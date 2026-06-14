const express = require('express');
const cors = require('cors');
const path = require('path');
const bodyParser = require('body-parser');
const db = require('./db');
const { sendDbError } = require('./dbError');
const menuRt = require('./routes/menuRoutes');
const analyticsRt = require('./routes/analyticsRoutes');

const app = express();

// Cấu hình CORS - cho phép tất cả origin (kể cả file://)
app.use(cors({
    origin: '*',
    methods: 'GET,POST,PUT,DELETE',
    allowedHeaders: 'Content-Type',
}));

// Phục vụ file tĩnh (ảnh upload + web admin)
app.use(express.static(path.join(__dirname, 'public')));
app.use('/admin', express.static(path.join(__dirname, '..', 'Project_Food_Admin')));

// Middleware parse JSON body
app.use(bodyParser.json());
app.use(express.json());

// ==========================================
// API Routes
// ==========================================

// Health check - kiểm tra kết nối SQL Server
app.get('/api/health', async (req, res) => {
    try {
        await db.executeQuery('SELECT 1 AS ok');
        res.json({ status: 'ok', database: 'connected' });
    } catch (err) {
        res.status(503).json({
            status: 'error',
            database: 'disconnected',
            message: err.isConnectionError
                ? 'Không thể kết nối đến SQL Server. Vui lòng kiểm tra: (1) SQL Server đang chạy, (2) Server name/port đúng, (3) Tường lửa không chặn.'
                : err.message
        });
    }
});

// Routes cho quản lý thực đơn (CRUD)
app.use('/api/menu', menuRt);

// Routes cho thống kê doanh thu
app.use('/api', analyticsRt);

// ==========================================
// API: Xác thực người dùng
// ==========================================

// Đăng nhập - gọi stored procedure sp_DangNhap
app.post('/api/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            return res.status(400).json({ message: 'Vui lòng nhập tài khoản và mật khẩu' });
        }
        const result = await db.executeProcedure('sp_DangNhap', {
            TenDangNhap: username,
            MatKhau: password
        });
        if (result.recordset.length > 0) {
            res.json({ success: true, user: result.recordset[0] });
        } else {
            res.status(401).json({ success: false, message: 'Sai thông tin đăng nhập' });
        }
    } catch (err) {
        sendDbError(res, err, 'Lỗi đăng nhập:');
    }
});

// Đăng ký - gọi stored procedure sp_DangKy
app.post('/api/register', async (req, res) => {
    try {
        const { username, password, fullName, role } = req.body;
        if (!username || !password || !fullName) {
            return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin' });
        }
        const result = await db.executeProcedure('sp_DangKy', {
            TenDangNhap: username,
            MatKhau: password,
            HoTen: fullName,
            VaiTro: role || 'Nhân viên'
        });
        res.json({ success: true, userId: result.recordset[0]?.Id });
    } catch (err) {
        sendDbError(res, err, 'Lỗi đăng ký:');
    }
});

// ==========================================
// API: Quản lý bàn ăn
// ==========================================

// Lấy danh sách bàn (kèm HoaDonId nếu có hóa đơn chưa thanh toán)
app.get('/api/tables', async (req, res) => {
    try {
        const result = await db.executeQuery(`
            SELECT b.Id, b.TenBan, b.TrangThai,
                (SELECT TOP 1 Id FROM HoaDon WHERE BanId = b.Id AND TrangThai = N'Chưa thanh toán') AS HoaDonId
            FROM Ban b ORDER BY b.Id
        `);
        res.json(result.recordset);
    } catch (err) {
        sendDbError(res, err, 'Không thể lấy danh sách bàn');
    }
});

// Cập nhật trạng thái bàn
app.put('/api/tables/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { trangThai } = req.body;
        await db.executeParameterizedQuery('UPDATE Ban SET TrangThai = @trangThai WHERE Id = @id', { trangThai, id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Không thể cập nhật bàn');
    }
});

// Thêm bàn mới
app.post('/api/tables', async (req, res) => {
    try {
        const { tenBan } = req.body;
        if (!tenBan) return res.status(400).json({ message: 'Thiếu tên bàn' });
        const result = await db.executeParameterizedQuery('INSERT INTO Ban (TenBan) VALUES (@tenBan); SELECT SCOPE_IDENTITY() AS Id', { tenBan });
        res.status(201).json({ success: true, id: result.recordset[0]?.Id });
    } catch (err) {
        sendDbError(res, err, 'Không thể thêm bàn');
    }
});

// Dồn bàn: chuyển hóa đơn từ bàn hiện tại sang bàn khác, xong xóa bàn hiện tại
// Gửi tenBan là tên bàn muốn dồn sang
app.put('/api/tables/:id/rename', async (req, res) => {
    try {
        const { id } = req.params;
        const { tenBan } = req.body;
        if (!tenBan) return res.status(400).json({ message: 'Thiếu tên bàn' });

        const targetResult = await db.executeParameterizedQuery(
            'SELECT Id, TrangThai FROM Ban WHERE TenBan = @tenBan',
            { tenBan }
        );
        if (targetResult.recordset.length === 0) {
            return res.status(404).json({ message: 'Chưa có bàn ' + tenBan });
        }
        const targetId = targetResult.recordset[0].Id;
        const targetStatus = targetResult.recordset[0].TrangThai;

        if (parseInt(id) === targetId) {
            return res.status(400).json({ message: 'Không thể dồn vào chính nó' });
        }

        // Cập nhật BanId của các hóa đơn chưa thanh toán từ bàn hiện tại sang bàn đích
        await db.executeParameterizedQuery(
            "UPDATE HoaDon SET BanId = @targetId WHERE BanId = @id AND TrangThai = N'Chưa thanh toán'",
            { id: parseInt(id), targetId }
        );

        // Cập nhật trạng thái
        if (targetStatus === 'Còn trống') {
            await db.executeParameterizedQuery(
                "UPDATE Ban SET TrangThai = N'Đang sử dụng' WHERE Id = @targetId",
                { targetId }
            );
        }
        await db.executeParameterizedQuery(
            "UPDATE Ban SET TrangThai = N'Còn trống' WHERE Id = @id",
            { id: parseInt(id) }
        );

        res.json({ success: true, message: 'Đã dồn bàn thành công' });
    } catch (err) {
        sendDbError(res, err, 'Không thể dồn bàn');
    }
});

// Xóa bàn (dùng stored procedure để tránh permission issue)
app.delete('/api/tables/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.executeProcedure('sp_XoaBan', { Id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Không thể xóa bàn');
    }
});

// ==========================================
// API: Đặt hàng & Thanh toán
// ==========================================

// Đặt hàng mới (sử dụng Transaction qua stored procedure sp_DatHang)
app.post('/api/orders', async (req, res) => {
    try {
        const { banId, nhanVienId, items } = req.body;
        if (!banId || !nhanVienId || !items || items.length === 0) {
            return res.status(400).json({ message: 'Thiếu thông tin đặt hàng' });
        }
        const itemsJson = JSON.stringify(items.map(item => ({
            monAnId: item.monAnId || item.productId,
            soLuong: item.quantity,
            donGia: item.price,
            ghiChu: item.ghiChu || ''
        })));
        const result = await db.executeProcedure('sp_DatHang', {
            BanId: banId,
            NhanVienId: nhanVienId,
            Items: itemsJson
        });
        if (result.recordset && result.recordset.length > 0) {
            res.json({ success: true, ...result.recordset[0] });
        } else {
            res.json({ success: true });
        }
    } catch (err) {
        sendDbError(res, err, 'Lỗi đặt hàng:');
    }
});

// Thanh toán hóa đơn - gọi stored procedure sp_ThanhToan (có hỗ trợ voucher)
app.post('/api/payment', async (req, res) => {
    try {
        const { hoaDonId, maGiamGia } = req.body;
        if (!hoaDonId) {
            return res.status(400).json({ message: 'Thiếu mã hóa đơn' });
        }
        const result = await db.executeProcedure('sp_ThanhToan', {
            HoaDonId: hoaDonId,
            MaGiamGia: maGiamGia || null
        });
        const msg = result.recordset && result.recordset[0] ? result.recordset[0] : {};
        res.json({ success: true, ...msg });
    } catch (err) {
        sendDbError(res, err, 'Lỗi thanh toán:');
    }
});

// Kiểm tra mã giảm giá
app.post('/api/vouchers/check', async (req, res) => {
    try {
        const { ma, tongTien } = req.body;
        if (!ma) return res.status(400).json({ message: 'Thiếu mã giảm giá' });
        const result = await db.executeProcedure('sp_KiemTraVoucher', {
            Ma: ma,
            TongTien: tongTien || 0
        });
        res.json(result.recordset[0] || { TrangThai: 'Không hợp lệ' });
    } catch (err) {
        sendDbError(res, err, 'Lỗi kiểm tra voucher:');
    }
});

// Lấy danh sách voucher
app.get('/api/vouchers', async (req, res) => {
    try {
        const result = await db.executeProcedure('sp_VoucherList');
        res.json(result.recordset || []);
    } catch (err) {
        sendDbError(res, err, 'Lỗi lấy voucher:');
    }
});

// Thêm voucher
app.post('/api/vouchers', async (req, res) => {
    try {
        const { ma, phanTramGiam } = req.body;
        if (!ma || !phanTramGiam) {
            return res.status(400).json({ message: 'Thiếu thông tin voucher' });
        }
        const result = await db.executeProcedure('sp_VoucherAdd', {
            Ma: ma,
            PhanTramGiam: phanTramGiam
        });
        res.status(201).json({ success: true, id: result.recordset[0]?.Id });
    } catch (err) {
        sendDbError(res, err, 'Lỗi thêm voucher:');
    }
});

// Sửa voucher
app.put('/api/vouchers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { ma, phanTramGiam } = req.body;
        if (!ma || !phanTramGiam) {
            return res.status(400).json({ message: 'Thiếu thông tin voucher' });
        }
        await db.executeProcedure('sp_VoucherUpdate', {
            Id: parseInt(id),
            Ma: ma,
            PhanTramGiam: phanTramGiam
        });
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Lỗi sửa voucher:');
    }
});

// Bật/tắt voucher
app.put('/api/vouchers/:id/toggle', async (req, res) => {
    try {
        const { id } = req.params;
        await db.executeProcedure('sp_VoucherToggle', { Id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Lỗi đổi trạng thái voucher:');
    }
});

// Xóa voucher
app.delete('/api/vouchers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.executeProcedure('sp_VoucherDelete', { Id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Lỗi xóa voucher:');
    }
});

// ============================================================
// Employee (Nhân viên)
// ============================================================

// Danh sách nhân viên
app.get('/api/employees', async (req, res) => {
    try {
        const result = await db.executeProcedure('sp_NhanVienList');
        res.json(result.recordset || []);
    } catch (err) {
        sendDbError(res, err, 'Lỗi lấy nhân viên:');
    }
});

// Thêm nhân viên
app.post('/api/employees', async (req, res) => {
    try {
        const { tenDangNhap, matKhau, hoTen, vaiTro } = req.body;
        if (!tenDangNhap || !matKhau || !hoTen) {
            return res.status(400).json({ message: 'Thiếu thông tin nhân viên' });
        }
        const result = await db.executeProcedure('sp_NhanVienAdd', {
            TenDangNhap: tenDangNhap,
            MatKhau: matKhau,
            HoTen: hoTen,
            VaiTro: vaiTro || 'Nhân viên'
        });
        res.status(201).json({ success: true, id: result.recordset[0]?.Id });
    } catch (err) {
        sendDbError(res, err, 'Lỗi thêm nhân viên:');
    }
});

// Sửa nhân viên
app.put('/api/employees/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { tenDangNhap, matKhau, hoTen, vaiTro } = req.body;
        if (!tenDangNhap || !hoTen) {
            return res.status(400).json({ message: 'Thiếu thông tin nhân viên' });
        }
        await db.executeProcedure('sp_NhanVienUpdate', {
            Id: parseInt(id),
            TenDangNhap: tenDangNhap,
            MatKhau: matKhau || null,
            HoTen: hoTen,
            VaiTro: vaiTro || 'Nhân viên'
        });
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Lỗi sửa nhân viên:');
    }
});

// Xóa nhân viên
app.delete('/api/employees/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.executeProcedure('sp_NhanVienDelete', { Id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Lỗi xóa nhân viên:');
    }
});

// Lấy danh sách hóa đơn
app.get('/api/invoices', async (req, res) => {
    try {
        const { status } = req.query;
        let query = `
            SELECT hd.Id, hd.NgayTao, b.TenBan, nv.HoTen AS TenNhanVien,
                   hd.BanId, hd.NhanVienId, hd.TongTien, hd.MaGiamGia, hd.TienGiam, hd.TrangThai
            FROM HoaDon hd
            JOIN Ban b ON hd.BanId = b.Id
            JOIN NhanVien nv ON hd.NhanVienId = nv.Id
        `;
        const params = {};
        if (status) {
            query += ' WHERE hd.TrangThai = @status';
            params.status = status;
        }
        query += ' ORDER BY hd.NgayTao DESC';
        const result = await db.executeParameterizedQuery(query, params);
        res.json(result.recordset);
    } catch (err) {
        sendDbError(res, err, 'Không thể lấy danh sách hóa đơn');
    }
});

// Lấy chi tiết hóa đơn
app.get('/api/invoices/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.executeProcedure('sp_ChiTietHoaDon', { HoaDonId: parseInt(id) });
        res.json(result.recordset);
    } catch (err) {
        sendDbError(res, err, 'Không thể lấy chi tiết hóa đơn');
    }
});

// Xóa một món khỏi hóa đơn chưa thanh toán
app.delete('/api/orders/:hoaDonId/items/:chiTietId', async (req, res) => {
    try {
        const { hoaDonId, chiTietId } = req.params;
        const checkResult = await db.executeParameterizedQuery(
            "SELECT 1 FROM HoaDon WHERE Id = @hoaDonId AND TrangThai = N'Chưa thanh toán'",
            { hoaDonId: parseInt(hoaDonId) }
        );
        if (checkResult.recordset.length === 0) {
            return res.status(400).json({ message: 'Không thể sửa hóa đơn đã thanh toán' });
        }
        await db.executeParameterizedQuery(
            'DELETE FROM ChiTietHoaDon WHERE Id = @chiTietId AND HoaDonId = @hoaDonId',
            { chiTietId: parseInt(chiTietId), hoaDonId: parseInt(hoaDonId) }
        );
        res.json({ success: true });
    } catch (err) {
        sendDbError(res, err, 'Không thể xóa món');
    }
});

// ==========================================
// API: Danh mục
// ==========================================

app.get('/api/categories', async (req, res) => {
    try {
        const result = await db.executeQuery('SELECT Id, Ten, MoTa FROM DanhMuc ORDER BY Id');
        res.json(result.recordset);
    } catch (err) {
        sendDbError(res, err, 'Không thể lấy danh mục');
    }
});

// ==========================================
// Global error handling middleware
// ==========================================
app.use((err, req, res, next) => {
    console.error('Lỗi không xử lý được:', err);
    const statusCode = err.statusCode || 500;
    const message = err.isConnectionError
        ? 'Mất kết nối đến SQL Server. Vui lòng kiểm tra server và kết nối mạng.'
        : (err.message || 'Lỗi server nội bộ');
    res.status(statusCode).json({ message, isConnectionError: !!err.isConnectionError });
});

// Khởi động server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server đang chạy trên cổng ${PORT}`);
    console.log(`API: http://localhost:${PORT}/api`);
});

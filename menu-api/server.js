const express = require('express');
const cors = require('cors');
const path = require('path');
const bodyParser = require('body-parser');
const db = require('./db');
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
        console.error('Lỗi đăng nhập:', err);
        res.status(500).json({ success: false, message: 'Lỗi server: ' + err.message });
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
        console.error('Lỗi đăng ký:', err);
        res.status(500).json({ success: false, message: 'Lỗi server: ' + err.message });
    }
});

// ==========================================
// API: Quản lý bàn ăn
// ==========================================

// Lấy danh sách bàn
app.get('/api/tables', async (req, res) => {
    try {
        const result = await db.executeQuery('SELECT Id, TenBan, TrangThai FROM Ban ORDER BY Id');
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi lấy danh sách bàn:', err);
        res.status(500).json({ message: 'Không thể lấy danh sách bàn' });
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
        console.error('Lỗi cập nhật bàn:', err);
        res.status(500).json({ message: 'Không thể cập nhật bàn' });
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
        console.error('Lỗi thêm bàn:', err);
        res.status(500).json({ message: 'Không thể thêm bàn' });
    }
});

// Đổi chỗ 2 bàn cho nhau
// Gửi tenBan là tên bàn muốn đổi chỗ với bàn hiện tại
app.put('/api/tables/:id/rename', async (req, res) => {
    try {
        const { id } = req.params;
        const { tenBan } = req.body;
        if (!tenBan) return res.status(400).json({ message: 'Thiếu tên bàn' });

        const targetResult = await db.executeParameterizedQuery(
            'SELECT Id, TrangThai, TenBan FROM Ban WHERE TenBan = @tenBan',
            { tenBan }
        );
        if (targetResult.recordset.length === 0) {
            return res.status(404).json({ message: 'Chưa có bàn ' + tenBan });
        }
        const targetId = targetResult.recordset[0].Id;
        const targetStatus = targetResult.recordset[0].TrangThai;
        const targetName = targetResult.recordset[0].TenBan;

        if (parseInt(id) === targetId) {
            return res.status(400).json({ message: 'Không thể đổi chỗ với chính nó' });
        }

        const currentResult = await db.executeParameterizedQuery(
            'SELECT TrangThai, TenBan FROM Ban WHERE Id = @id',
            { id: parseInt(id) }
        );
        const currentStatus = currentResult.recordset[0].TrangThai;
        const currentName = currentResult.recordset[0].TenBan;

        await db.executeParameterizedQuery(
            "UPDATE HoaDon SET BanId = @targetId WHERE BanId = @id AND TrangThai = N'Chưa thanh toán'",
            { targetId, id: parseInt(id) }
        );
        await db.executeParameterizedQuery(
            "UPDATE HoaDon SET BanId = @id WHERE BanId = @targetId AND TrangThai = N'Chưa thanh toán'",
            { targetId, id: parseInt(id) }
        );

        await db.executeParameterizedQuery(
            'UPDATE Ban SET TrangThai = @targetStatus WHERE Id = @id',
            { targetStatus, id: parseInt(id) }
        );
        await db.executeParameterizedQuery(
            'UPDATE Ban SET TrangThai = @currentStatus WHERE Id = @targetId',
            { currentStatus, targetId }
        );

        await db.executeParameterizedQuery(
            'UPDATE Ban SET TenBan = @targetName WHERE Id = @id',
            { targetName, id: parseInt(id) }
        );
        await db.executeParameterizedQuery(
            'UPDATE Ban SET TenBan = @currentName WHERE Id = @targetId',
            { currentName, targetId }
        );

        res.json({ success: true, message: 'Đã đổi chỗ bàn thành công' });
    } catch (err) {
        console.error('Lỗi đổi bàn:', err);
        res.status(500).json({ message: 'Không thể đổi bàn' });
    }
});

// Xóa bàn
app.delete('/api/tables/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const checkResult = await db.executeParameterizedQuery(
            "SELECT COUNT(*) AS cnt FROM HoaDon WHERE BanId = @id AND TrangThai = N'Chưa thanh toán'",
            { id: parseInt(id) }
        );
        if (checkResult.recordset[0].cnt > 0) {
            return res.status(400).json({ message: 'Không thể xóa bàn đang có hóa đơn chưa thanh toán' });
        }
        await db.executeParameterizedQuery('DELETE FROM Ban WHERE Id = @id', { id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        console.error('Lỗi xóa bàn:', err);
        res.status(500).json({ message: 'Không thể xóa bàn' });
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
        console.error('Lỗi đặt hàng:', err);
        res.status(500).json({ success: false, message: err.message });
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
        console.error('Lỗi thanh toán:', err);
        res.status(500).json({ success: false, message: err.message });
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
        console.error('Lỗi kiểm tra voucher:', err);
        res.status(500).json({ message: err.message });
    }
});

// Lấy danh sách voucher
app.get('/api/vouchers', async (req, res) => {
    try {
        const result = await db.executeProcedure('sp_VoucherList');
        res.json(result.recordset || []);
    } catch (err) {
        console.error('Lỗi lấy voucher:', err);
        res.status(500).json({ message: err.message });
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
        console.error('Lỗi thêm voucher:', err);
        res.status(500).json({ message: err.message });
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
        console.error('Lỗi sửa voucher:', err);
        res.status(500).json({ message: err.message });
    }
});

// Bật/tắt voucher
app.put('/api/vouchers/:id/toggle', async (req, res) => {
    try {
        const { id } = req.params;
        await db.executeProcedure('sp_VoucherToggle', { Id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        console.error('Lỗi đổi trạng thái voucher:', err);
        res.status(500).json({ message: err.message });
    }
});

// Xóa voucher
app.delete('/api/vouchers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.executeParameterizedQuery('DELETE FROM Voucher WHERE Id = @id', { id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        console.error('Lỗi xóa voucher:', err);
        res.status(500).json({ message: err.message });
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
        console.error('Lỗi lấy nhân viên:', err);
        res.status(500).json({ message: err.message });
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
        console.error('Lỗi thêm nhân viên:', err);
        res.status(500).json({ message: err.message });
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
        console.error('Lỗi sửa nhân viên:', err);
        res.status(500).json({ message: err.message });
    }
});

// Xóa nhân viên
app.delete('/api/employees/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.executeProcedure('sp_NhanVienDelete', { Id: parseInt(id) });
        res.json({ success: true });
    } catch (err) {
        console.error('Lỗi xóa nhân viên:', err);
        res.status(500).json({ message: err.message });
    }
});

// Lấy danh sách hóa đơn
app.get('/api/invoices', async (req, res) => {
    try {
        const { status } = req.query;
        let query = `
            SELECT hd.Id, hd.NgayTao, b.TenBan, nv.HoTen AS TenNhanVien,
                   hd.TongTien, hd.MaGiamGia, hd.TienGiam, hd.TrangThai
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
        console.error('Lỗi lấy hóa đơn:', err);
        res.status(500).json({ message: 'Không thể lấy danh sách hóa đơn' });
    }
});

// Lấy chi tiết hóa đơn
app.get('/api/invoices/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.executeProcedure('sp_ChiTietHoaDon', { HoaDonId: parseInt(id) });
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi lấy chi tiết hóa đơn:', err);
        res.status(500).json({ message: 'Không thể lấy chi tiết hóa đơn' });
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
        console.error('Lỗi lấy danh mục:', err);
        res.status(500).json({ message: 'Không thể lấy danh mục' });
    }
});

// ==========================================
// Error handling middleware
// ==========================================
app.use((err, req, res, next) => {
    console.error('Lỗi không xử lý được:', err);
    res.status(500).json({ message: 'Lỗi server nội bộ' });
});

// Khởi động server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server đang chạy trên cổng ${PORT}`);
    console.log(`API: http://localhost:${PORT}/api`);
});

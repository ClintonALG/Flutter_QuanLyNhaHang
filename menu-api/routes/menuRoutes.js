const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../db');
const router = express.Router();

const uploadDir = path.join(__dirname, '../public/imgs/products');

// Tạo thư mục upload nếu chưa tồn tại
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Cấu hình multer để upload file ảnh
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        const timestamp = Date.now();
        const ext = path.extname(file.originalname);
        const name = path.basename(file.originalname, ext);
        cb(null, `${name}_${timestamp}${ext}`);
    }
});

const upload = multer({ storage: storage }).single('image');

// ==========================================
// API: Upload ảnh món ăn
// ==========================================
router.post('/upload', (req, res) => {
    upload(req, res, function (err) {
        if (err) {
            return res.status(500).json({ message: 'Lỗi upload: ' + err.message });
        }
        if (!req.file) {
            return res.status(400).json({ message: 'Không có file nào được upload' });
        }
        const imagePath = `/imgs/products/${req.file.filename}`;
        res.json({ imagePath });
    });
});

// ==========================================
// API: Lấy danh sách món ăn (có filter)
// ==========================================
router.get('/', async (req, res) => {
    try {
        const { category, search, all } = req.query;
        let query = `
            SELECT ma.Id, ma.Ten, ma.Gia, ma.MoTa, ma.HinhAnh,
                   ma.DanhMucId, dm.Ten AS DanhMuc, ma.TrangThai, ma.NgayTao
            FROM MonAn ma
            JOIN DanhMuc dm ON ma.DanhMucId = dm.Id
        `;
        const conditions = [];
        const params = {};
        if (all !== 'true') {
            conditions.push('ma.TrangThai = 1');
        }
        if (category && category !== 'All') {
            conditions.push('dm.Ten = @category');
            params.category = category;
        }
        if (search) {
            conditions.push('ma.Ten LIKE @search');
            params.search = '%' + search + '%';
        }
        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }
        query += ' ORDER BY ma.Id';
        const result = await db.executeParameterizedQuery(query, params);
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi lấy menu:', err);
        res.status(500).json({ message: 'Không thể lấy dữ liệu menu' });
    }
});

// ==========================================
// API: Thêm món ăn mới (dùng stored procedure)
// ==========================================
router.post('/', async (req, res) => {
    try {
        const { name, description, price, image, categoryId } = req.body;
        if (!name || !price || !categoryId) {
            return res.status(400).json({ message: 'Thiếu thông tin bắt buộc (tên, giá, danh mục)' });
        }
        const result = await db.executeProcedure('sp_ThemMonAn', {
            Ten: name,
            Gia: parseFloat(price),
            MoTa: description || null,
            HinhAnh: image || null,
            DanhMucId: parseInt(categoryId)
        });
        res.status(201).json({ success: true, id: result.recordset[0]?.Id });
    } catch (err) {
        console.error('Lỗi thêm món:', err);
        res.status(500).json({ message: err.message });
    }
});

// ==========================================
// API: Cập nhật món ăn (dùng stored procedure)
// ==========================================
router.put('/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const { name, description, price, image, categoryId, trangThai } = req.body;
        await db.executeProcedure('sp_CapNhatMonAn', {
            Id: id,
            Ten: name || null,
            Gia: price ? parseFloat(price) : null,
            MoTa: description || null,
            HinhAnh: image || null,
            DanhMucId: categoryId ? parseInt(categoryId) : null,
            TrangThai: trangThai !== undefined ? (trangThai ? 1 : 0) : null
        });
        res.json({ success: true, message: 'Cập nhật thành công' });
    } catch (err) {
        console.error('Lỗi cập nhật món:', err);
        res.status(500).json({ message: err.message });
    }
});

// ==========================================
// API: Bật/tắt trạng thái món ăn
// ==========================================
router.put('/:id/toggle', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const result = await db.executeParameterizedQuery(
            'UPDATE MonAn SET TrangThai = CASE WHEN TrangThai = 1 THEN 0 ELSE 1 END WHERE Id = @id',
            { id }
        );
        res.json({ success: true });
    } catch (err) {
        console.error('Lỗi đổi trạng thái món:', err);
        res.status(500).json({ message: err.message });
    }
});

// ==========================================
// API: Xóa món ăn (xóa thật - xóa ChiTietHoaDon trước)
// ==========================================
router.delete('/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const check = await db.executeParameterizedQuery(`
            SELECT 1 FROM ChiTietHoaDon cthd, HoaDon hd
            WHERE cthd.MonAnId = @id
            AND cthd.HoaDonId = hd.Id
            AND hd.TrangThai = N'Chưa thanh toán'
        `, { id });
        if (check.recordset.length > 0) {
            return res.status(400).json({ message: 'Không thể xóa món đang có trong hóa đơn chưa thanh toán' });
        }
        await db.executeParameterizedQuery('DELETE FROM ChiTietHoaDon WHERE MonAnId = @id', { id });
        await db.executeParameterizedQuery('DELETE FROM MonAn WHERE Id = @id', { id });
        res.json({ success: true, message: 'Đã xóa thành công' });
    } catch (err) {
        console.error('Lỗi xóa món:', err);
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;

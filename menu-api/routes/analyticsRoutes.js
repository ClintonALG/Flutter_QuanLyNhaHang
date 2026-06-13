const express = require('express');
const db = require('../db');
const router = express.Router();

// ==========================================
// API: Doanh thu theo khoảng thời gian
// Sử dụng stored procedure sp_ThongKeDoanhThu
// ==========================================
router.get('/revenue', async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        if (!startDate || !endDate) {
            return res.status(400).json({ message: 'Thiếu tham số ngày (startDate, endDate)' });
        }
        const result = await db.executeProcedure('sp_ThongKeDoanhThu', {
            TuNgay: startDate,
            DenNgay: endDate
        });
        const orders = result.recordset;
        const totalRevenue = orders.reduce((sum, o) => sum + (o.DoanhThu || 0), 0);
        res.json({ totalRevenue, orders: result.recordset });
    } catch (err) {
        console.error('Lỗi thống kê doanh thu:', err);
        res.status(500).json({ message: 'Không thể lấy dữ liệu doanh thu' });
    }
});

// ==========================================
// API: Tất cả doanh thu theo ngày (không filter)
// Dùng cho biểu đồ tổng quan
// ==========================================
router.get('/revenue-all', async (req, res) => {
    try {
        const result = await db.executeQuery(`
            SELECT
                CAST(NgayTao AS DATE) AS Ngay,
                COUNT(*) AS SoHoaDon,
                SUM(TongTien) AS TongTien,
                SUM(TongTien - TienGiam) AS DoanhThu
            FROM HoaDon
            WHERE TrangThai = N'Đã thanh toán'
            GROUP BY CAST(NgayTao AS DATE)
            ORDER BY Ngay
        `);
        const orders = result.recordset;
        for (let order of orders) {
            const detail = await db.executeParameterizedQuery(`
                SELECT SUM(SoLuong) AS SoMonDaBan
                FROM ChiTietHoaDon cthd, HoaDon hd
                WHERE cthd.HoaDonId = hd.Id
                  AND CAST(hd.NgayTao AS DATE) = @ngay
                  AND hd.TrangThai = N'Đã thanh toán'
            `, { ngay: order.Ngay.toISOString().split('T')[0] });
            order.SoMonDaBan = detail.recordset[0]?.SoMonDaBan || 0;
        }
        res.json({ orders });
    } catch (err) {
        console.error('Lỗi lấy tất cả doanh thu:', err);
        res.status(500).json({ message: 'Không thể lấy dữ liệu doanh thu' });
    }
});

// ==========================================
// API: Tổng số sản phẩm đã bán
// ==========================================
router.get('/products-sold', async (req, res) => {
    try {
        const result = await db.executeQuery(`
            SELECT ISNULL(SUM(SoLuong), 0) AS TotalSold
            FROM ChiTietHoaDon cthd
            JOIN HoaDon hd ON cthd.HoaDonId = hd.Id
            WHERE hd.TrangThai = N'Đã thanh toán'
        `);
        res.json({ totalSold: result.recordset[0].TotalSold });
    } catch (err) {
        console.error('Lỗi đếm sản phẩm:', err);
        res.status(500).json({ message: 'Không thể đếm sản phẩm đã bán' });
    }
});

// ==========================================
// API: Chi tiết doanh thu theo ngày
// ==========================================
router.get('/detail-revenue', async (req, res) => {
    try {
        const { date, startDate, endDate } = req.query;
        if (!date && (!startDate || !endDate)) {
            return res.status(400).json({ message: 'Thiếu tham số: date hoặc startDate + endDate' });
        }
        let query;
        const params = {};
        if (date) {
            query = `
                SELECT cthd.SoLuong, cthd.DonGia, cthd.ThanhTien, ma.Ten AS TenMonAn
                FROM ChiTietHoaDon cthd, HoaDon hd, MonAn ma
                WHERE cthd.HoaDonId = hd.Id
                  AND cthd.MonAnId = ma.Id
                  AND CAST(hd.NgayTao AS DATE) = @date
                  AND hd.TrangThai = N'Đã thanh toán'
            `;
            params.date = date;
        } else {
            query = `
                SELECT cthd.SoLuong, cthd.DonGia, cthd.ThanhTien, ma.Ten AS TenMonAn
                FROM ChiTietHoaDon cthd, HoaDon hd, MonAn ma
                WHERE cthd.HoaDonId = hd.Id
                  AND cthd.MonAnId = ma.Id
                  AND CAST(hd.NgayTao AS DATE) BETWEEN @startDate AND @endDate
                  AND hd.TrangThai = N'Đã thanh toán'
            `;
            params.startDate = startDate;
            params.endDate = endDate;
        }
        const result = await db.executeParameterizedQuery(query, params);
        res.json({ items: result.recordset });
    } catch (err) {
        console.error('Lỗi chi tiết doanh thu:', err);
        res.status(500).json({ message: 'Không thể lấy chi tiết doanh thu' });
    }
});

// ==========================================
// API: Món bán chạy
// ==========================================
router.get('/best-selling', async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        let result;
        if (startDate && endDate) {
            result = await db.executeProcedure('sp_MonBanChay', {
                TuNgay: startDate,
                DenNgay: endDate
            });
        } else {
            result = await db.executeProcedure('sp_MonBanChay');
        }
        res.json(result.recordset);
    } catch (err) {
        console.error('Lỗi lấy món bán chạy:', err);
        res.status(500).json({ message: 'Không thể lấy dữ liệu món bán chạy' });
    }
});

module.exports = router;

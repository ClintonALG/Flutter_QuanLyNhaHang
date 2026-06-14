let revenueChart = null;
let allOrders = [];
let currentView = 'month'; // 'month' or 'day'

// Khởi tạo khi trang load
document.addEventListener('DOMContentLoaded', function () {
    fetchAllRevenue();
});

async function fetchAllRevenue() {
    try {
        const response = await apiFetch(API_BASE + '/revenue-all');
        if (!response.ok) throw new Error('HTTP ' + response.status);
        const data = await response.json();
        allOrders = data.orders || [];
        renderView();
    } catch (error) {
        console.error('Lỗi:', error);
        document.getElementById('total-gross').textContent = 'Lỗi';
        document.getElementById('total-revenue').textContent = 'Lỗi: ' + error.message;
    }
}

function switchView(view) {
    currentView = view;
    document.querySelectorAll('.toggle-group .btn').forEach(b => b.classList.remove('active'));
    if (view === 'month') {
        document.getElementById('btn-month').classList.add('active');
    } else {
        document.getElementById('btn-day').classList.add('active');
    }
    renderView();
}

function renderView() {
    if (allOrders.length === 0) {
        document.getElementById('total-gross').textContent = '0 ₫';
        document.getElementById('total-revenue').textContent = '0 ₫';
        showNoDataMessage('Chưa có dữ liệu');
        if (revenueChart) revenueChart.destroy();
        return;
    }

    if (currentView === 'month') {
        renderByMonth();
    } else {
        renderByDay();
    }
}

function renderByMonth() {
    const monthly = {};
    allOrders.forEach(item => {
        const monthKey = moment(item.Ngay).format('YYYY-MM');
        if (!monthly[monthKey]) {
            monthly[monthKey] = { TongTien: 0, DoanhThu: 0, Ngay: item.Ngay };
        }
        monthly[monthKey].TongTien += item.TongTien || 0;
        monthly[monthKey].DoanhThu += item.DoanhThu || 0;
    });

    const months = Object.keys(monthly).sort();
    const labels = months.map(m => {
        const d = moment(m, 'YYYY-MM');
        return 'Tháng ' + d.format('M/YYYY');
    });
    const revenues = months.map(m => monthly[m].DoanhThu);
    const totalGross = months.reduce((a, m) => a + monthly[m].TongTien, 0);
    const totalNet = revenues.reduce((a, b) => a + b, 0);

    document.getElementById('total-gross').textContent = totalGross.toLocaleString('vi-VN') + ' ₫';
    document.getElementById('total-revenue').textContent = totalNet.toLocaleString('vi-VN') + ' ₫';
    drawChart(labels, revenues, months, 'month');
}

function renderByDay() {
    const labels = allOrders.map(item => moment(item.Ngay).format('DD/MM'));
    const revenues = allOrders.map(item => item.DoanhThu || 0);
    const totalGross = allOrders.reduce((a, item) => a + (item.TongTien || 0), 0);
    const totalNet = revenues.reduce((a, b) => a + b, 0);

    document.getElementById('total-gross').textContent = totalGross.toLocaleString('vi-VN') + ' ₫';
    document.getElementById('total-revenue').textContent = totalNet.toLocaleString('vi-VN') + ' ₫';
    drawChart(labels, revenues, allOrders.map(item => item.Ngay), 'day');
}

function drawChart(labels, revenues, keys, viewType) {
    const canvas = document.getElementById('revenueChart');
    if (!canvas) return;
    if (revenueChart) revenueChart.destroy();

    revenueChart = new Chart(canvas.getContext('2d'), {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Doanh thu (₫)',
                data: revenues,
                backgroundColor: '#1976d2',
                borderRadius: 4
            }]
        },
        options: {
            responsive: true,
            onClick: function (e, elements) {
                if (elements.length > 0) {
                    const idx = elements[0].index;
                    const key = keys[idx];
                    if (viewType === 'month') {
                        processMonthDetail(key);
                    } else {
                        processDayDetail(key);
                    }
                }
            },
            scales: {
                y: {
                    ticks: {
                        callback: function (value) {
                            return value.toLocaleString('vi-VN') + '₫';
                        }
                    }
                }
            }
        }
    });
}

async function processMonthDetail(monthKey) {
    const header = document.querySelector('.detail-analytics h4');
    if (header) {
        const d = moment(monthKey, 'YYYY-MM');
        header.textContent = 'Chi tiết tháng ' + d.format('M/YYYY') + ':';
    }

    const tbody = document.querySelector('#detail-revenue tbody');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="4" class="text-center"><div class="spinner-border text-primary" role="status"><span class="sr-only">Đang tải...</span></div></td></tr>';

    try {
        const start = moment(monthKey, 'YYYY-MM').startOf('month').format('YYYY-MM-DD');
        const end = moment(monthKey, 'YYYY-MM').endOf('month').format('YYYY-MM-DD');
        const response = await apiFetch(`${API_BASE}/detail-revenue?startDate=${start}&endDate=${end}`);
        const data = await response.json();
        const items = (data.items || []).map(item => ({
            name: item.TenMonAn || 'Không xác định',
            price: item.DonGia || 0,
            quantity: item.SoLuong || 1
        }));
        renderOrderDetails(items, data.tongCong || 0, data.tienGiam || 0);
    } catch (error) {
        console.error('Lỗi chi tiết:', error);
        showNoDataMessage('Lỗi tải dữ liệu');
    }
}

async function processDayDetail(ngay) {
    const header = document.querySelector('.detail-analytics h4');
    if (header) header.textContent = 'Chi tiết ngày ' + moment(ngay).format('DD/MM/YYYY') + ':';

    const tbody = document.querySelector('#detail-revenue tbody');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="4" class="text-center"><div class="spinner-border text-primary" role="status"><span class="sr-only">Đang tải...</span></div></td></tr>';

    try {
        const formattedDate = moment(ngay).format('YYYY-MM-DD');
        const response = await apiFetch(`${API_BASE}/detail-revenue?date=${formattedDate}`);
        if (!response.ok) throw new Error('HTTP ' + response.status);
        const data = await response.json();
        const items = (data.items || []).map(item => ({
            name: item.TenMonAn || 'Không xác định',
            price: item.DonGia || 0,
            quantity: item.SoLuong || 1
        }));
        renderOrderDetails(items, data.tongCong || 0, data.tienGiam || 0);
    } catch (error) {
        console.error('Lỗi chi tiết:', error);
        showNoDataMessage('Lỗi tải dữ liệu');
    }
}

function renderOrderDetails(items, tongCong, tienGiam) {
    const tbody = document.querySelector('#detail-revenue tbody');
    if (!tbody) return;
    tbody.innerHTML = '';

    if (!items || items.length === 0) {
        showNoDataMessage();
        return;
    }

    let totalAmount = 0;
    items.forEach(item => {
        const price = parseFloat(item.price) || 0;
        const quantity = parseInt(item.quantity) || 0;
        const itemTotal = quantity * price;
        totalAmount += itemTotal;

        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.name}</td>
            <td>${quantity}</td>
            <td>${price.toLocaleString('vi-VN')} ₫</td>
            <td>${itemTotal.toLocaleString('vi-VN')} ₫</td>
        `;
        tbody.appendChild(row);
    });

    const tienGiamNum = parseFloat(tienGiam) || 0;
    const thanhTien = totalAmount - tienGiamNum;

    const totalRow = document.createElement('tr');
    totalRow.innerHTML = `
        <td colspan="3"><strong>Tổng tiền hàng</strong></td>
        <td><strong>${totalAmount.toLocaleString('vi-VN')} ₫</strong></td>
    `;
    tbody.appendChild(totalRow);

    if (tienGiamNum > 0) {
        const discountRow = document.createElement('tr');
        discountRow.style.color = '#2e7d32';
        discountRow.innerHTML = `
            <td colspan="3"><strong>Giảm giá (Voucher)</strong></td>
            <td><strong>-${tienGiamNum.toLocaleString('vi-VN')} ₫</strong></td>
        `;
        tbody.appendChild(discountRow);

        const finalRow = document.createElement('tr');
        finalRow.style.color = '#c62828';
        finalRow.innerHTML = `
            <td colspan="3"><strong>Thành tiền</strong></td>
            <td><strong>${thanhTien.toLocaleString('vi-VN')} ₫</strong></td>
        `;
        tbody.appendChild(finalRow);
    }
}

function showNoDataMessage(message) {
    if (!message) message = 'Chưa có dữ liệu';
    const tbody = document.querySelector('#detail-revenue tbody');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="4" class="text-center" style="padding:24px;color:#999;"><i class="fa-solid fa-circle-info"></i> ' + message + '</td></tr>';
}
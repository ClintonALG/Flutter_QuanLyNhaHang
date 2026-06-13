/**
 * Tải danh sách món ăn từ SQL Server qua API backend
 * 
 * Gọi API /api/menu -> truy vấn SQL Server -> hiển thị lên bảng
 * Dữ liệu trả về gồm: Id, Ten, Gia, MoTa, HinhAnh, DanhMucId, DanhMuc, TrangThai
 */
async function loadMenu() {
    try {
        const response = await fetch(API_BASE + "/menu?all=true");
        if (!response.ok) {
            document.querySelector(".product-table tbody").innerHTML = '<tr><td colspan="7" style="text-align:center;color:red;">Lỗi kết nối API (mã: ' + response.status + ')</td></tr>';
            return;
        }
        const data = await response.json();
        if (!Array.isArray(data)) {
            document.querySelector(".product-table tbody").innerHTML = '<tr><td colspan="7" style="text-align:center;color:red;">Dữ liệu không hợp lệ</td></tr>';
            return;
        }

        const tbody = document.querySelector(".product-table tbody");
        tbody.innerHTML = "";

        data.forEach(function (item, index) {
        const newRow = document.createElement("tr");
        newRow.setAttribute("data-category", item.DanhMuc || item.danhMuc || "");
        newRow.setAttribute('data-id', item.Id || item.id);

        const imgSrc = item.HinhAnh || item.image || "../imgs/products/foodDefault.png";
        const fullImgSrc = imgSrc.startsWith('http') ? imgSrc : `${API_BASE.replace('/api', '')}${imgSrc.startsWith('/') ? '' : '/'}${imgSrc}`;

        const isActive = item.TrangThai === true || item.TrangThai === 1;
        const statusBadge = isActive
            ? '<span class="badge badge-ok" style="background:#e8f5e9;color:#2e7d32;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:600;">Active</span>'
            : '<span class="badge badge-thieu" style="background:#ffebee;color:#c62828;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:600;">Disable</span>';

        newRow.innerHTML = `
          <td><input type="checkbox" class="row-checkbox"></td>
          <td>${index + 1}</td>
          <td><img src="${fullImgSrc}" alt="Ảnh" class="product-img" onerror="this.src='../imgs/products/foodDefault.png'"></td>
          <td>${item.Ten || item.name || ''}</td>
          <td>${item.MoTa || item.description || ''}</td>
          <td>${(item.Gia || item.price || 0).toLocaleString('vi-VN')}₫</td>
          <td>${statusBadge}</td>
          <td>
              <button class="status-btn" onclick="toggleStatus(${item.Id || item.id})" style="background:${isActive ? '#ff9800' : '#4caf50'};color:white;border:none;padding:5px 10px;border-radius:6px;cursor:pointer;font-size:12px;margin-right:4px;">
                  ${isActive ? 'Disable' : 'Active'}
              </button>
              <button class="edit-btn" style="background:#1976d2;color:white;border:none;padding:5px 10px;border-radius:6px;cursor:pointer;font-size:12px;" onclick="editProduct(${item.Id || item.id})">Sửa</button>
          </td>          
        `;
        tbody.appendChild(newRow);
        });
    } catch (err) {
        console.error("Lỗi tải menu:", err);
    }
}

async function toggleStatus(id) {
    try {
        const res = await fetch(`${API_BASE}/menu/${id}/toggle`, { method: 'PUT' });
        if (res.ok) {
            await loadMenu();
        } else {
            alert('Lỗi đổi trạng thái');
        }
    } catch (e) {
        alert('Lỗi kết nối');
    }
}

window.addEventListener("DOMContentLoaded", loadMenu);

// ============================================================
// Hàm sửa sản phẩm (gọi từ onclick của nút Sửa)
// ============================================================
function editProduct(id) {
    const row = document.querySelector(`tr[data-id="${id}"]`);
    if (!row) return;
    const cells = row.querySelectorAll('td');
    const form = document.getElementById('product-form');

    form.style.display = 'block';
    form.scrollIntoView({ behavior: 'smooth' });

    window.editProductId = id;
    window.currentEditingImage = cells[2].querySelector('img')?.src || '';

    const imagePreview = document.getElementById('image-preview');
    if (imagePreview) {
        imagePreview.src = window.currentEditingImage;
        imagePreview.style.display = 'block';
    }

    document.getElementById('product-name').value = cells[3]?.textContent || '';
    document.getElementById('product-des').value = cells[4]?.textContent || '';
    document.getElementById('product-price').value = parseInt((cells[5]?.textContent || '0').replace(/[^0-9]/g, '')) || 0;
    document.getElementById('product-category').value = row.dataset.category || 'Đồ ăn';

    const addBtn = document.querySelector('.btn-add-product, .add-btn');
    if (addBtn) addBtn.style.display = 'none';
}

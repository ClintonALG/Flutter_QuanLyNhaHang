/**
 * Thêm / Sửa sản phẩm - gọi POST hoặc PUT /api/menu/:id
 * Thêm: sp_ThemMonAn, Sửa: sp_CapNhatMonAn
 */

const addBtn = document.querySelector('.add-btn');
const formAddProduct = document.getElementById('product-form');
const cancelBtn = document.getElementById('cancel-btn');

// Map tên danh mục sang ID
const categoryMap = {
    'food': 1, 'drink': 2, 'combo': 3,
    'Đồ ăn': 1, 'Đồ uống': 2, 'Tráng miệng': 3
};

// Hiện form thêm sản phẩm
addBtn.addEventListener('click', function () {
    window.editProductId = null;
    window.currentEditingImage = '';
    formAddProduct.reset();
    formAddProduct.style.display = 'block';
    addBtn.style.display = 'none';
});

// Hủy bỏ
cancelBtn.addEventListener('click', function () {
    formAddProduct.reset();
    formAddProduct.style.display = 'none';
    addBtn.style.display = 'block';
    window.editProductId = null;
    window.currentEditingImage = '';
});

// Xử lý submit - vừa thêm vừa sửa
formAddProduct.addEventListener('submit', async function (event) {
    event.preventDefault();

    const name = document.getElementById('product-name').value.trim();
    const category = document.getElementById('product-category').value;
    const description = document.getElementById('product-des').value.trim();
    const price = document.getElementById('product-price').value;
    const imgInput = document.getElementById('product-img');

    if (!name) { alert('Vui lòng nhập tên món ăn'); return; }
    if (!price || parseInt(price) <= 0) { alert('Vui lòng nhập giá hợp lệ'); return; }

    // Upload ảnh nếu có
    let imgURL = window.currentEditingImage || '';
    if (imgInput.files && imgInput.files[0]) {
        const formData = new FormData();
        formData.append('image', imgInput.files[0]);
        try {
            const uploadRes = await fetch(API_BASE + '/menu/upload', {
                method: 'POST', body: formData
            });
            if (uploadRes.ok) {
                const uploadResult = await uploadRes.json();
                imgURL = uploadResult.imagePath;
            }
        } catch (e) {
            console.error('Lỗi upload ảnh:', e);
        }
    }

    const categoryId = categoryMap[category] || 1;

    try {
        const isEdit = window.editProductId;
        let response;

        if (isEdit) {
            // Sửa
            response = await fetch(`${API_BASE}/menu/${window.editProductId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: name, description: description,
                    price: parseInt(price), categoryId: categoryId,
                    image: imgURL
                })
            });
        } else {
            // Thêm
            response = await fetch(API_BASE + "/menu", {
                method: "POST",
                headers: { "content-type": "application/json" },
                body: JSON.stringify({
                    name: name, description: description,
                    price: parseInt(price), categoryId: categoryId,
                    image: imgURL
                })
            });
        }

        if (response.ok) {
            alert(isEdit ? "Sửa sản phẩm thành công!" : "Thêm sản phẩm thành công");
            formAddProduct.reset();
            formAddProduct.style.display = 'none';
            addBtn.style.display = 'block';
            window.editProductId = null;
            await loadMenu();
        } else {
            const err = await response.json();
            alert("Lỗi: " + (err.message || ''));
        }
    } catch (error) {
        console.error("Lỗi:", error);
        alert("Lỗi kết nối đến server");
    }
});

function scrollToProduct(productId) {
    const row = document.querySelector(`tr[data-id="${productId}"]`);
    if (row) {
        row.scrollIntoView({ behavior: 'smooth', block: 'center' });
        row.style.backgroundColor = '#e0f7fa';
        setTimeout(() => { row.style.backgroundColor = ''; }, 2000);
    }
}
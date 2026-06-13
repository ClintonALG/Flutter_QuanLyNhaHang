/**
 * Xóa sản phẩm - gọi DELETE /api/menu/:id -> stored procedure sp_XoaMonAn
 */

const deleBtn = document.querySelector('.delete-btn');

deleBtn.addEventListener('click', async function (event) {
    event.preventDefault();

    const selectedCb = document.querySelectorAll('.row-checkbox:checked');
    const idDelete = Array.from(selectedCb).map(function (cb) {
        return cb.closest('tr').dataset.id;
    });

    if (idDelete.length === 0) {
        alert('Bạn phải chọn ít nhất một sản phẩm');
        return;
    }
    if (!confirm('Bạn có chắc chắn xóa ' + idDelete.length + ' sản phẩm đã chọn?')) return;

    let successCount = 0;
    for (const id of idDelete) {
        try {
            const response = await fetch(`${API_BASE}/menu/${id}`, {
                method: 'DELETE'
            });
            if (response.ok) successCount++;
        } catch (error) {
            console.error("Lỗi mạng khi xóa sản phẩm:", error);
        }
    }

    if (successCount > 0) {
        alert(`Đã xóa ${successCount} sản phẩm thành công`);
        location.reload();
    } else {
        alert('Không thể xóa sản phẩm. Vui lòng thử lại.');
    }
});

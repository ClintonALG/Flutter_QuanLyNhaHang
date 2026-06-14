
const getTotalSold = document.getElementById('total-products-sold');

async function fetchTotalSold() {
    try {
        const res = await apiFetch(API_BASE + '/products-sold');

        const data = await res.json();

        getTotalSold.textContent = data.totalSold + " món";
    }
    catch (error) {
        console.error("Lỗi khi lấy tổng món đã bán ", error);
        getTotalSold.textContent = "Lỗi";
    }
}

//load
window.addEventListener("DOMContentLoaded", fetchTotalSold);
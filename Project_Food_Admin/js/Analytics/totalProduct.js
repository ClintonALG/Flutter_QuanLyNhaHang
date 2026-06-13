const totalProduct = document.getElementById('total-products');

// console.log(totalProduct);

async function getTotalProduct() {

    try {
        const response = await fetch(API_BASE + "/menu");// gọi API

        const products = await response.json();// lấy dữ liệu JSON

        const total = products.length;// đếm tổng số món ăn

        // console.log(total);

        totalProduct.textContent = total;

    }
    catch (error) {
        console.error("Lỗi khi lấy thông tin món ăn: ", error);
        totalProduct.textContent = "Lỗi";
    }
}

//gọi hàm khi trang vừa load
window.addEventListener("DOMContentLoaded", getTotalProduct);
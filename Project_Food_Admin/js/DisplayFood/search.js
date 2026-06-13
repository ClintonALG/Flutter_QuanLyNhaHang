const searchInput = document.getElementById('search-input');
const getSearchBtn = document.querySelector('.search-btn');


// console.log(getSearchBtn);

getSearchBtn.addEventListener('click', function () {
    const keyword = searchInput.value.toLowerCase().trim();
    // console.log(keyword);

    const rows = document.querySelectorAll('.product-table tbody tr');
    // console.log(rows);

    rows.forEach((row) => {

        const nameProduct = row.querySelector('td:nth-child(4)').textContent.toLowerCase();
        // console.log(nameProduct);

        const descriptionProduct = row.querySelector('td:nth-child(5)').textContent.toLowerCase();
        // console.log(descriptionProduct);

        if (nameProduct.includes(keyword) || descriptionProduct.includes(keyword)) {
            row.style.display = "";
            // console.log(123);
        }
        else {
            row.style.display = "none";
            // alert("Không tìm thấy sản phẩm nào phù hợp với từ khóa của bạn!");
        }
    });
});

//cho phép sử dụng enter để tìm kiếm
searchInput.addEventListener('keypress', function (event) {
    if (event.key === 'Enter') {
        getSearchBtn.click();
    }
});



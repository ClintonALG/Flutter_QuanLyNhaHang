
function addCategoryListener() {
    const filterBtns = document.querySelectorAll('.category-filter button');

    // console.log(filterBtns);

    // console.log(productRow);
    filterBtns.forEach(button => {
        button.addEventListener('click', function () {

            //category btn
            const categoryBtn = button.getAttribute('data-category');
            // console.log(categoryBtn);

            //để productRow ở đây. Vì phải load lại mỗi dòng sau khi click
            //productRow là lấy all dòng sp đang có
            const productRow = document.querySelectorAll('.product-table tbody tr');

            //category sp
            productRow.forEach(row => {
                const categoryProduct = row.getAttribute('data-category');
                //console.log(categoryProduct);


                if (categoryBtn === 'all' || categoryBtn === categoryProduct) {
                    row.style.display = '';
                }
                else {
                    row.style.display = 'none';
                }
            });
        });
    });
}

//lắng nghe sự kiện load ở window
window.addEventListener('DOMContentLoaded', async function () {

    await loadMenu();
    addCategoryListener(); //gọi lại hàm sao khi load lại menu

});

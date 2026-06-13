
function addCheckboxListeners() {
    const getSelectedAll = document.getElementById('selected-all');
    const rowCheckBox = document.querySelectorAll('.row-checkbox');
    // console.log(getSelected);

    //tick chỌn tất cả checkbox
    getSelectedAll.addEventListener('change', function () {

        const isChecked = getSelectedAll.checked;
        // if (getSelectedAll.checked) {
        rowCheckBox.forEach(function (checkbox) {
            checkbox.checked = isChecked;
        })
        // }
    });

    //nếu chọn all checkbox con thì checkboxAll sẽ auto tick
    rowCheckBox.forEach(function (checkbox) {

        checkbox.addEventListener('change', function () {

            const allChecked = Array.from(rowCheckBox).every(function (cb) {
                return cb.checked;
            });

            getSelectedAll.checked = allChecked;

        });

    });
}


//lắng nghe sự kiện load ở window
window.addEventListener('DOMContentLoaded', async function () {
    await loadMenu();
    addCheckboxListeners(); //gọi lại hàm sao khi load lại menu

});
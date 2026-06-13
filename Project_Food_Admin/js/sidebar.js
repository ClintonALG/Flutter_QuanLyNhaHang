/**
 * Cập nhật active menu và hiển thị thông tin người dùng
 */
document.addEventListener("DOMContentLoaded", function () {
    // Hiển thị tên người dùng
    const userJson = localStorage.getItem('admin_user');
    if (userJson) {
        try {
            const user = JSON.parse(userJson);
            const navHeader = document.querySelector('.nav-header');
            if (navHeader) {
                const userInfo = document.createElement('div');
                userInfo.style.cssText =
                    'text-align:center;padding:8px 12px 16px;border-bottom:1px solid rgba(0,0,0,0.08);margin-bottom:8px;';
                userInfo.innerHTML =
                    '<div style="font-weight:700;font-size:14px;color:#333;">' +
                    (user.HoTen || user.TenDangNhap || 'Admin') +
                    '</div>' +
                    '<div style="font-size:11px;color:#888;margin-top:2px;">' +
                    (user.VaiTro || '') +
                    '</div>';
                navHeader.after(userInfo);
            }
        } catch (e) { /* ignore */ }
    }

    const menuItem = document.querySelectorAll(".side-menu li");

    function removeActiveClass() {
        menuItem.forEach((item) => {
            item.classList.remove("active");
        }
        );
    }

    function setActiveClass() {
        removeActiveClass();

        const currentPath = window.location.pathname.split("/").pop() || 'index.html';

        console.log("currentPath: ", currentPath);

        menuItem.forEach((item) => {
            const link = item.querySelector("a").getAttribute("href");
            if (link === currentPath) {
                item.classList.add("active");
            }
        });

    }
    menuItem.forEach((item) => {
        item.addEventListener("click", function () {
            removeActiveClass();

            this.classList.add("active");
            const link = this.querySelector("a").getAttribute("href");
            localStorage.setItem("activeMenu", link);
        });
    });

    //đặt item active khi load trang
    setActiveClass();

    //kt localStorage để khôi phục trạng thái tùy chọn
    const activeMenu = localStorage.getItem("activeMenu");
    if (activeMenu) {
        menuItem.forEach((item) => {
            const link = item.querySelector("a").getAttribute("href");
            if (link === activeMenu) {
                removeActiveClass();
                item.classList.add("active");

                localStorage.setItem("activeMenu", link);
            }
        });
    }
});
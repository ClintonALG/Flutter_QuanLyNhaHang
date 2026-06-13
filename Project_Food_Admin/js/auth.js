/**
 * Kiểm tra đăng nhập - chuyển hướng về login.html nếu chưa đăng nhập
 */
function checkAuth() {
    const user = localStorage.getItem('admin_user');
    if (!user) {
        const loginUrl = window.location.pathname.includes('/functions/')
            ? '../login.html'
            : 'login.html';
        window.location.replace(loginUrl);
        return null;
    }
    try {
        return JSON.parse(user);
    } catch {
        localStorage.removeItem('admin_user');
        window.location.replace('login.html');
        return null;
    }
}

/**
 * Đăng xuất - xóa thông tin và chuyển về trang đăng nhập
 */
function logout() {
    localStorage.removeItem('admin_user');
    const loginUrl = window.location.pathname.includes('/functions/')
        ? '../login.html'
        : 'login.html';
    window.location.href = loginUrl;
}

document.addEventListener('DOMContentLoaded', checkAuth);

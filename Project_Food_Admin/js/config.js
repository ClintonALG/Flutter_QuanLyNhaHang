// Đổi true/false để chuyển giữa local và LAN
const USE_LAN = false;
const LAN_IP = '192.168.1.10';
const API_TIMEOUT_MS = 10000;
const API_BASE = USE_LAN ? `http://${LAN_IP}:3000/api` : 'http://localhost:3000/api';

const CONNECTION_HELP =
    'Vui lòng kiểm tra:\n' +
    '(1) Chạy API backend: npm run dev trong thư mục menu-api\n' +
    '(2) SQL Server đang hoạt động\n' +
    '(3) Địa chỉ IP/port đúng trong config.js\n' +
    '(4) Thiết bị và server cùng mạng (nếu dùng LAN)';

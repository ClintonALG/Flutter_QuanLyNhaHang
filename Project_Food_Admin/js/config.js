// Đổi true/false để chuyển giữa local và LAN
const USE_LAN = true;
const LAN_IP = '192.168.1.10';
const API_BASE = USE_LAN ? `http://${LAN_IP}:3000/api` : 'http://localhost:3000/api';

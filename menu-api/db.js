const sql = require('mssql');
const fs = require('fs');
const path = require('path');

// Đọc cấu hình kết nối từ file appsettings.json
// Mục đích: Tránh hardcode chuỗi kết nối trong code Dart/JS, dễ dàng thay đổi cấu hình
const configPath = path.join(__dirname, 'appsettings.json');
let config = {};

try {
  const raw = fs.readFileSync(configPath, 'utf8');
  const settings = JSON.parse(raw);
  const connStr = settings.ConnectionStrings.QuanLyNhaHang;

  // Parse chuỗi kết nối thành object config cho mssql
  const parts = connStr.split(';');
  parts.forEach(part => {
    const [key, ...vals] = part.split('=');
    const val = vals.join('=').trim();
    switch (key.trim()) {
      case 'Server': config.server = val; break;
      case 'Database': config.database = val; break;
      case 'User ID': config.user = val; break;
      case 'Password': config.password = val; break;
      case 'Encrypt': config.options = { ...config.options, encrypt: val === 'True' }; break;
      case 'TrustServerCertificate': config.options = { ...config.options, trustServerCertificate: val === 'True' }; break;
    }
  });
  config.options = { ...config.options, connectTimeout: 30000, requestTimeout: 30000 };
  console.log('Đã đọc cấu hình kết nối SQL Server từ appsettings.json');
} catch (err) {
  console.error('Không thể đọc appsettings.json, sử dụng cấu hình mặc định:', err.message);
  // Fallback: cấu hình mặc định cho phát triển
  config = {
    server: 'localhost',
    database: 'QuanLyNhaHang',
    user: 'sa',
    password: '123456',
    options: {
      encrypt: false,
      trustServerCertificate: true,
      connectTimeout: 30000,
      requestTimeout: 30000
    }
  };
}

// Tạo connection pool duy nhất cho toàn bộ ứng dụng
// Mục đích: Connection pooling giúp tái sử dụng kết nối, tránh tạo mới mỗi request
const pool = new sql.ConnectionPool(config);

// Kết nối pool khi khởi động
pool.connect()
  .then(() => console.log('Đã kết nối SQL Server thành công!'))
  .catch(err => console.error('Lỗi kết nối SQL Server:', err.message));

// Hàm helper thực thi stored procedure
// @param procedureName: Tên stored procedure
// @param params: Object chứa các tham số { key: value }
// @returns: Kết quả trả về từ SP
async function executeProcedure(procedureName, params = {}) {
  try {
    const request = pool.request();
    Object.entries(params).forEach(([key, value]) => {
      request.input(key, value);
    });
    const result = await request.execute(procedureName);
    return result;
  } catch (err) {
    throw err;
  }
}

// Hàm helper thực thi câu lệnh SQL
// @param query: Câu lệnh SQL
// @returns: Kết quả trả về
async function executeQuery(query) {
  try {
    const result = await pool.request().query(query);
    return result;
  } catch (err) {
    throw err;
  }
}

async function executeParameterizedQuery(query, params = {}) {
  try {
    const request = pool.request();
    Object.entries(params).forEach(([key, value]) => {
      request.input(key, value);
    });
    const result = await request.query(query);
    return result;
  } catch (err) {
    throw err;
  }
}

module.exports = {
  pool,
  executeProcedure,
  executeQuery,
  executeParameterizedQuery,
  sql
};

const sql = require('mssql');
const fs = require('fs');
const path = require('path');

// Đọc cấu hình kết nối từ file appsettings.json
const configPath = path.join(__dirname, 'appsettings.json');
let config = {};

try {
  const raw = fs.readFileSync(configPath, 'utf8');
  const settings = JSON.parse(raw);
  const connStr = settings.ConnectionStrings.QuanLyNhaHang;

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
  const timeout = settings.SqlTimeout || {};
  config.options = {
    ...config.options,
    encrypt: false,
    trustServerCertificate: true,
    connectTimeout: timeout.ConnectMs ?? 30000,
    requestTimeout: timeout.RequestMs ?? 30000,
    cancelTimeout: timeout.CancelMs ?? 5000
  };
} catch (err) {
  config = {
    server: 'localhost',
    database: 'QuanLyNhaHang',
    user: 'sa',
    password: '123456',
    options: {
      encrypt: false,
      trustServerCertificate: true,
      connectTimeout: 30000,
      requestTimeout: 30000,
      cancelTimeout: 5000
    }
  };
}

const pool = new sql.ConnectionPool(config);
let poolConnected = false;

pool.on('error', err => {
  console.error('Connection pool lỗi:', err.message);
  poolConnected = false;
});

async function ensureConnected() {
  if (!poolConnected) {
    try {
      await pool.connect();
      poolConnected = true;
      console.log('Đã kết nối SQL Server thành công!');
    } catch (err) {
      poolConnected = false;
      const dbErr = new Error('Không thể kết nối đến SQL Server. Vui lòng kiểm tra: (1) SQL Server đang chạy, (2) Server name/port đúng, (3) Tường lửa không chặn.');
      dbErr.code = 'ECONNREFUSED';
      throw dbErr;
    }
  }
}

pool.connect()
  .then(() => {
    poolConnected = true;
    console.log('Đã kết nối SQL Server thành công!');
  })
  .catch(err => {
    poolConnected = false;
    console.error('Lỗi kết nối SQL Server:', err.message);
  });

function classifyError(err) {
  if (!err) return err;
  if (err.code === 'ECONNREFUSED' || err.code === 'ENOTFOUND' || err.code === 'ETIMEDOUT' || err.code === 'ESOCKET') {
    const dbErr = new Error('Không thể kết nối đến SQL Server. Vui lòng kiểm tra: (1) SQL Server đang chạy, (2) Server name/port đúng, (3) Tường lửa không chặn.');
    dbErr.statusCode = 503;
    dbErr.isConnectionError = true;
    return dbErr;
  }
  if (err.code === 'EREQUEST' && err.number === -2) {
    const timeoutErr = new Error('SQL Server không phản hồi (timeout). Vui lòng kiểm tra kết nối mạng.');
    timeoutErr.statusCode = 503;
    timeoutErr.isConnectionError = true;
    return timeoutErr;
  }
  if (err.message && (err.message.includes('timeout') || err.message.includes('timed out'))) {
    const timeoutErr = new Error('SQL Server không phản hồi (timeout). Vui lòng kiểm tra kết nối mạng.');
    timeoutErr.statusCode = 503;
    timeoutErr.isConnectionError = true;
    return timeoutErr;
  }
  if (err.message && (err.message.includes('login') || err.message.includes('login failed'))) {
    const authErr = new Error('Đăng nhập SQL Server thất bại. Vui lòng kiểm tra User ID và Password.');
    authErr.statusCode = 500;
    authErr.isConnectionError = true;
    return authErr;
  }
  return err;
}

async function executeProcedure(procedureName, params = {}) {
  try {
    await ensureConnected();
    const request = pool.request();
    Object.entries(params).forEach(([key, value]) => {
      request.input(key, value);
    });
    const result = await request.execute(procedureName);
    return result;
  } catch (err) {
    throw classifyError(err);
  }
}

async function executeQuery(query) {
  try {
    await ensureConnected();
    const result = await pool.request().query(query);
    return result;
  } catch (err) {
    throw classifyError(err);
  }
}

async function executeParameterizedQuery(query, params = {}) {
  try {
    await ensureConnected();
    const request = pool.request();
    Object.entries(params).forEach(([key, value]) => {
      request.input(key, value);
    });
    const result = await request.query(query);
    return result;
  } catch (err) {
    throw classifyError(err);
  }
}

module.exports = {
  pool,
  executeProcedure,
  executeQuery,
  executeParameterizedQuery,
  sql
};

/**
 * Gọi API có timeout và hiển thị dialog khi mất kết nối (API tắt / SQL lỗi).
 */
async function apiFetch(url, options = {}) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), API_TIMEOUT_MS);
    try {
        const res = await fetch(url, { ...options, signal: controller.signal });
        clearTimeout(timer);
        if (res.status === 503) {
            const data = await res.clone().json().catch(() => ({}));
            if (data.isConnectionError) {
                showConnectionError(data.message || 'Mất kết nối đến SQL Server.');
            }
        }
        return res;
    } catch (err) {
        clearTimeout(timer);
        const message = err.name === 'AbortError'
            ? 'Quá thời gian chờ kết nối API.\n' + CONNECTION_HELP
            : 'Mất kết nối đến API backend.\n' + CONNECTION_HELP;
        showConnectionError(message);
        const connErr = new Error(message);
        connErr.isConnectionError = true;
        throw connErr;
    }
}

function showConnectionError(message) {
    if (document.getElementById('conn-error-overlay')) return;

    const overlay = document.createElement('div');
    overlay.id = 'conn-error-overlay';
    overlay.style.cssText =
        'position:fixed;inset:0;background:rgba(0,0,0,0.55);z-index:99999;' +
        'display:flex;align-items:center;justify-content:center;padding:16px;';

    const box = document.createElement('div');
    box.style.cssText =
        'background:#fff;padding:28px;border-radius:14px;max-width:440px;width:100%;' +
        'box-shadow:0 12px 40px rgba(0,0,0,0.25);';

    const title = document.createElement('h3');
    title.style.cssText = 'margin:0 0 12px;color:#c62828;font-size:18px;';
    title.textContent = 'Mất kết nối';

    const body = document.createElement('p');
    body.style.cssText = 'margin:0 0 20px;white-space:pre-line;line-height:1.55;color:#333;font-size:14px;';
    body.textContent = message;

    const btn = document.createElement('button');
    btn.textContent = 'Đã hiểu';
    btn.style.cssText =
        'padding:10px 22px;background:#1976d2;color:#fff;border:none;' +
        'border-radius:8px;cursor:pointer;font-size:14px;font-weight:500;';
    btn.onclick = () => overlay.remove();

    box.appendChild(title);
    box.appendChild(body);
    box.appendChild(btn);
    overlay.appendChild(box);
    document.body.appendChild(overlay);
}

function sendDbError(res, err, fallbackMessage = 'Lỗi server') {
    console.error(fallbackMessage, err);
    const status = err.isConnectionError ? 503 : (err.statusCode || 500);
    const message = err.message || fallbackMessage;
    res.status(status).json({
        success: false,
        message,
        isConnectionError: !!err.isConnectionError,
    });
}

module.exports = { sendDbError };

using fruit_api.Models;

namespace fruit_api.Services;

public class VietQRService
{
    private readonly IConfiguration _config;

    public VietQRService(IConfiguration config)
    {
        _config = config;
    }

    public VietQRResponse GenerateQR(string orderId, decimal amount)
    {
        // Lấy thông tin tài khoản từ appsettings.json
        var bankCode = _config["VietQR:BankCode"];
        var accountNo = _config["VietQR:AccountNo"];
        var accountName = _config["VietQR:AccountName"];
        var template = _config["VietQR:Template"] ?? "compact2";

        // Nội dung chuyển tiền là mã đơn hàng
        var orderInfo = $"DH{orderId}";

        // Tạo URL QR code từ vietqr.io
        var qrUrl = $"https://img.vietqr.io/image/{bankCode}-{accountNo}-{template}.png?" +
                    $"amount={amount}&" +
                    $"addInfo={Uri.EscapeDataString(orderInfo)}&" +
                    $"accountName={Uri.EscapeDataString(accountName)}";

        return new VietQRResponse
        {
            Success = true,
            QrCodeUrl = qrUrl,
            Message = "Tạo mã QR thành công"
        };
    }
}
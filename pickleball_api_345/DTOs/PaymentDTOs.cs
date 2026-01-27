using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

public class VnPayPaymentRequestDto
{
    [Required(ErrorMessage = "ID thành viên là bắt buộc")]
    public int MemberId { get; set; }

    [Required(ErrorMessage = "Số tiền là bắt buộc")]
    [Range(10000, 50000000, ErrorMessage = "Số tiền phải từ 10,000 đến 50,000,000 VND")]
    public decimal Amount { get; set; }

    [MaxLength(200, ErrorMessage = "Mô tả không được vượt quá 200 ký tự")]
    public string Description { get; set; } = "Nạp tiền vào ví PCM345";
}

public class VnPayPaymentResponseDto
{
    public string PaymentUrl { get; set; } = string.Empty;
    public string TransactionId { get; set; } = string.Empty;
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}

public class VnPayCallbackDto
{
    public string vnp_Amount { get; set; } = string.Empty;
    public string vnp_BankCode { get; set; } = string.Empty;
    public string vnp_BankTranNo { get; set; } = string.Empty;
    public string vnp_CardType { get; set; } = string.Empty;
    public string vnp_OrderInfo { get; set; } = string.Empty;
    public string vnp_PayDate { get; set; } = string.Empty;
    public string vnp_ResponseCode { get; set; } = string.Empty;
    public string vnp_TmnCode { get; set; } = string.Empty;
    public string vnp_TransactionNo { get; set; } = string.Empty;
    public string vnp_TransactionStatus { get; set; } = string.Empty;
    public string vnp_TxnRef { get; set; } = string.Empty;
    public string vnp_SecureHash { get; set; } = string.Empty;
}

public class QrCodeRequestDto
{
    [Required(ErrorMessage = "ID thành viên là bắt buộc")]
    public int MemberId { get; set; }

    [Required(ErrorMessage = "Số tiền là bắt buộc")]
    [Range(10000, 50000000, ErrorMessage = "Số tiền phải từ 10,000 đến 50,000,000 VND")]
    public decimal Amount { get; set; }

    [MaxLength(200, ErrorMessage = "Mô tả không được vượt quá 200 ký tự")]
    public string Description { get; set; } = "Nạp tiền vào ví PCM345";
}

public class QrCodeResponseDto
{
    public string QrCode { get; set; } = string.Empty;
    public string TransactionId { get; set; } = string.Empty;
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}
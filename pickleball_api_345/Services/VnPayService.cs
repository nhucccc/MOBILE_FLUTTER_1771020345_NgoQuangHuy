using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Web;

namespace pickleball_api_345.Services;

public class VnPayService : IPaymentService
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly IWalletService _walletService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<VnPayService> _logger;

    // VNPay Sandbox Configuration
    private readonly string _vnpUrl;
    private readonly string _vnpTmnCode;
    private readonly string _vnpHashSecret;
    private readonly string _vnpReturnUrl;

    public VnPayService(
        IConfiguration configuration,
        ApplicationDbContext context,
        IWalletService walletService,
        INotificationService notificationService,
        ILogger<VnPayService> logger)
    {
        _configuration = configuration;
        _context = context;
        _walletService = walletService;
        _notificationService = notificationService;
        _logger = logger;

        // VNPay Sandbox URLs and credentials
        _vnpUrl = _configuration["VnPay:Url"] ?? "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
        _vnpTmnCode = _configuration["VnPay:TmnCode"] ?? "DEMO123";
        _vnpHashSecret = _configuration["VnPay:HashSecret"] ?? "DEMOHASHSECRET";
        _vnpReturnUrl = _configuration["VnPay:ReturnUrl"] ?? "http://localhost:58377/api/payment/vnpay-callback";
    }

    public async Task<VnPayPaymentResponseDto> CreatePaymentUrlAsync(VnPayPaymentRequestDto request)
    {
        try
        {
            var member = await _context.Members_345.FindAsync(request.MemberId);
            if (member == null)
            {
                return new VnPayPaymentResponseDto
                {
                    Success = false,
                    Message = "Không tìm thấy thành viên"
                };
            }

            // Create transaction record
            var transaction = new WalletTransaction_345
            {
                MemberId = request.MemberId,
                Amount = request.Amount,
                Type = TransactionType.Deposit,
                Status = TransactionStatus.Pending,
                Description = request.Description,
                CreatedDate = DateTime.UtcNow
            };

            _context.WalletTransactions_345.Add(transaction);
            await _context.SaveChangesAsync();

            // Build VNPay parameters
            var vnpParams = new SortedDictionary<string, string>
            {
                {"vnp_Version", "2.1.0"},
                {"vnp_Command", "pay"},
                {"vnp_TmnCode", _vnpTmnCode},
                {"vnp_Amount", ((long)(request.Amount * 100)).ToString()}, // VNPay uses VND * 100
                {"vnp_CreateDate", DateTime.Now.ToString("yyyyMMddHHmmss")},
                {"vnp_CurrCode", "VND"},
                {"vnp_IpAddr", "127.0.0.1"},
                {"vnp_Locale", "vn"},
                {"vnp_OrderInfo", $"Nap tien vi PCM345 - {request.Description}"},
                {"vnp_OrderType", "other"},
                {"vnp_ReturnUrl", _vnpReturnUrl},
                {"vnp_TxnRef", transaction.Id.ToString()}
            };

            // Create secure hash
            var hashData = string.Join("&", vnpParams.Select(kv => $"{kv.Key}={kv.Value}"));
            var secureHash = CreateSecureHash(hashData, _vnpHashSecret);
            vnpParams.Add("vnp_SecureHash", secureHash);

            // Build payment URL
            var paymentUrl = _vnpUrl + "?" + string.Join("&", vnpParams.Select(kv => $"{kv.Key}={HttpUtility.UrlEncode(kv.Value)}"));

            _logger.LogInformation($"Created VNPay payment URL for transaction {transaction.Id}");

            return new VnPayPaymentResponseDto
            {
                PaymentUrl = paymentUrl,
                TransactionId = transaction.Id.ToString(),
                Success = true,
                Message = "Tạo link thanh toán thành công"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating VNPay payment URL");
            return new VnPayPaymentResponseDto
            {
                Success = false,
                Message = "Có lỗi xảy ra khi tạo link thanh toán"
            };
        }
    }

    public async Task<VnPayCallbackDto> ProcessCallbackAsync(IQueryCollection queryParams)
    {
        var callback = new VnPayCallbackDto();
        
        foreach (var param in queryParams)
        {
            var property = typeof(VnPayCallbackDto).GetProperty(param.Key);
            if (property != null)
            {
                property.SetValue(callback, param.Value.ToString());
            }
        }

        return callback;
    }

    public async Task<bool> ValidateCallbackAsync(VnPayCallbackDto callback)
    {
        try
        {
            // Validate secure hash
            var vnpParams = new SortedDictionary<string, string>();
            var properties = typeof(VnPayCallbackDto).GetProperties();
            
            foreach (var prop in properties)
            {
                if (prop.Name != "vnp_SecureHash")
                {
                    var value = prop.GetValue(callback)?.ToString();
                    if (!string.IsNullOrEmpty(value))
                    {
                        vnpParams.Add(prop.Name, value);
                    }
                }
            }

            var hashData = string.Join("&", vnpParams.Select(kv => $"{kv.Key}={kv.Value}"));
            var expectedHash = CreateSecureHash(hashData, _vnpHashSecret);

            if (expectedHash != callback.vnp_SecureHash)
            {
                _logger.LogWarning("VNPay callback hash validation failed");
                return false;
            }

            // Process successful payment
            if (callback.vnp_ResponseCode == "00" && callback.vnp_TransactionStatus == "00")
            {
                var transactionId = int.Parse(callback.vnp_TxnRef);
                var transaction = await _context.WalletTransactions_345
                    .Include(t => t.Member)
                    .FirstOrDefaultAsync(t => t.Id == transactionId);

                if (transaction != null && transaction.Status == TransactionStatus.Pending)
                {
                    // Update transaction status
                    transaction.Status = TransactionStatus.Completed;
                    transaction.ProcessedDate = DateTime.UtcNow;
                    transaction.ProcessedBy = "VNPay_System";

                    // Update wallet balance
                    transaction.Member.WalletBalance += transaction.Amount;
                    transaction.Member.TotalSpent += transaction.Amount;

                    await _context.SaveChangesAsync();

                    // Send notification
                    await _notificationService.NotifyWalletDepositAsync(
                        transaction.Member.UserId,
                        transaction.Amount
                    );

                    _logger.LogInformation($"VNPay payment processed successfully for transaction {transactionId}");
                    return true;
                }
            }
            else
            {
                // Handle failed payment
                var transactionId = int.Parse(callback.vnp_TxnRef);
                var transaction = await _context.WalletTransactions_345.FindAsync(transactionId);
                
                if (transaction != null)
                {
                    transaction.Status = TransactionStatus.Failed;
                    transaction.ProcessedDate = DateTime.UtcNow;
                    transaction.ProcessedBy = "VNPay_System";
                    await _context.SaveChangesAsync();
                }

                _logger.LogWarning($"VNPay payment failed for transaction {transactionId}. Response: {callback.vnp_ResponseCode}");
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating VNPay callback");
            return false;
        }
    }

    public async Task<string> GenerateQrCodeAsync(decimal amount, string description, string memberId)
    {
        try
        {
            // For demo purposes, generate a simple QR code data
            // In production, you would integrate with VietQR API
            var qrData = $"PCM345|{memberId}|{amount}|{description}|{DateTime.UtcNow:yyyyMMddHHmmss}";
            var qrCodeBase64 = Convert.ToBase64String(Encoding.UTF8.GetBytes(qrData));
            
            _logger.LogInformation($"Generated QR code for member {memberId}, amount {amount}");
            return qrCodeBase64;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating QR code");
            return string.Empty;
        }
    }

    private string CreateSecureHash(string data, string secretKey)
    {
        using var hmac = new HMACSHA512(Encoding.UTF8.GetBytes(secretKey));
        var hashBytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
        return BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
    }
}
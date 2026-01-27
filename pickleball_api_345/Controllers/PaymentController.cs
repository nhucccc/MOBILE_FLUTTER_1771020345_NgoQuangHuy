using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using pickleball_api_345.DTOs;
using pickleball_api_345.Services;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(IPaymentService paymentService, ILogger<PaymentController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    [HttpPost("vnpay/create")]
    [Authorize]
    public async Task<ActionResult<VnPayPaymentResponseDto>> CreateVnPayPayment([FromBody] VnPayPaymentRequestDto request)
    {
        try
        {
            var result = await _paymentService.CreatePaymentUrlAsync(request);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating VNPay payment");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi tạo thanh toán" });
        }
    }

    [HttpGet("vnpay-callback")]
    public async Task<IActionResult> VnPayCallback()
    {
        try
        {
            var callback = await _paymentService.ProcessCallbackAsync(Request.Query);
            var isValid = await _paymentService.ValidateCallbackAsync(callback);

            if (isValid)
            {
                if (callback.vnp_ResponseCode == "00")
                {
                    // Redirect to success page
                    return Redirect($"/payment/success?txnRef={callback.vnp_TxnRef}&amount={callback.vnp_Amount}");
                }
                else
                {
                    // Redirect to failure page
                    return Redirect($"/payment/failure?txnRef={callback.vnp_TxnRef}&code={callback.vnp_ResponseCode}");
                }
            }

            return BadRequest("Invalid callback");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing VNPay callback");
            return StatusCode(500, "Internal server error");
        }
    }

    [HttpPost("qr-code/generate")]
    [Authorize]
    public async Task<ActionResult<QrCodeResponseDto>> GenerateQrCode([FromBody] QrCodeRequestDto request)
    {
        try
        {
            var qrCode = await _paymentService.GenerateQrCodeAsync(
                request.Amount, 
                request.Description, 
                request.MemberId.ToString()
            );

            return Ok(new QrCodeResponseDto
            {
                QrCode = qrCode,
                TransactionId = Guid.NewGuid().ToString(),
                Success = true,
                Message = "Tạo mã QR thành công"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating QR code");
            return StatusCode(500, new QrCodeResponseDto
            {
                Success = false,
                Message = "Có lỗi xảy ra khi tạo mã QR"
            });
        }
    }

    [HttpGet("test-success")]
    public IActionResult TestSuccess()
    {
        return Ok(new { message = "Payment successful!", timestamp = DateTime.UtcNow });
    }

    [HttpGet("test-failure")]
    public IActionResult TestFailure()
    {
        return Ok(new { message = "Payment failed!", timestamp = DateTime.UtcNow });
    }
}
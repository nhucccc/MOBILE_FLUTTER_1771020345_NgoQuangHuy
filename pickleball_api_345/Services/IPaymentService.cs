using pickleball_api_345.DTOs;

namespace pickleball_api_345.Services;

public interface IPaymentService
{
    Task<VnPayPaymentResponseDto> CreatePaymentUrlAsync(VnPayPaymentRequestDto request);
    Task<VnPayCallbackDto> ProcessCallbackAsync(IQueryCollection queryParams);
    Task<bool> ValidateCallbackAsync(VnPayCallbackDto callback);
    Task<string> GenerateQrCodeAsync(decimal amount, string description, string memberId);
}
using pickleball_api_345.DTOs;

namespace pickleball_api_345.Services;

public interface IConcurrencyService
{
    Task<ConcurrentBookingResultDto> CreateBookingWithConcurrencyCheckAsync(CreateBookingDto request, int memberId);
    Task<bool> HandleConcurrencyConflictAsync(int bookingId, byte[] originalRowVersion);
}
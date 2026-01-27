using pickleball_api_345.DTOs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public interface IBookingService
{
    Task<List<CourtDto>> GetCourtsAsync();
    Task<List<CalendarBookingDto>> GetCalendarBookingsAsync(DateTime from, DateTime to, int? currentUserId = null);
    Task<BookingDto?> CreateBookingAsync(int memberId, CreateBookingDto request);
    Task<List<BookingDto>> CreateRecurringBookingAsync(int memberId, CreateRecurringBookingDto request);
    Task<bool> CancelBookingAsync(int bookingId, int memberId);
    Task<List<BookingDto>> GetMyBookingsAsync(int memberId, int page = 1, int pageSize = 20);
    Task<bool> IsCourtAvailableAsync(int courtId, DateTime startTime, DateTime endTime, int? excludeBookingId = null);
}
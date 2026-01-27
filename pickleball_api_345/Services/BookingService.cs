using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public class BookingService : IBookingService
{
    private readonly ApplicationDbContext _context;
    private readonly IWalletService _walletService;

    public BookingService(ApplicationDbContext context, IWalletService walletService)
    {
        _context = context;
        _walletService = walletService;
    }

    public async Task<List<CourtDto>> GetCourtsAsync()
    {
        return await _context.Courts_345
            .Where(c => c.IsActive)
            .Select(c => new CourtDto
            {
                Id = c.Id,
                Name = c.Name,
                IsActive = c.IsActive,
                Description = c.Description,
                PricePerHour = c.PricePerHour
            })
            .ToListAsync();
    }

    public async Task<List<CalendarBookingDto>> GetCalendarBookingsAsync(DateTime from, DateTime to, int? currentUserId = null)
    {
        return await _context.Bookings_345
            .Include(b => b.Court)
            .Include(b => b.Member)
            .Where(b => b.StartTime >= from && b.StartTime <= to)
            .Select(b => new CalendarBookingDto
            {
                Id = b.Id,
                CourtId = b.CourtId,
                CourtName = b.Court.Name,
                StartTime = b.StartTime,
                EndTime = b.EndTime,
                Status = b.Status.ToString(),
                MemberName = b.Member.FullName,
                IsMyBooking = currentUserId.HasValue && b.MemberId == currentUserId.Value
            })
            .ToListAsync();
    }

    public async Task<BookingDto?> CreateBookingAsync(int memberId, CreateBookingDto request)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            // Optimistic concurrency control - check availability with retry logic
            var retryCount = 0;
            const int maxRetries = 3;
            
            while (retryCount < maxRetries)
            {
                try
                {
                    // Check court availability
                    var isAvailable = await IsCourtAvailableAsync(request.CourtId, request.StartTime, request.EndTime);
                    if (!isAvailable)
                        return null;

                    // Double-check availability right before creating booking
                    var conflictingBookings = await _context.Bookings_345
                        .Where(b => b.CourtId == request.CourtId && 
                                   b.Status == BookingStatus.Confirmed &&
                                   b.StartTime < request.EndTime && 
                                   b.EndTime > request.StartTime)
                        .ToListAsync();

                    if (conflictingBookings.Any())
                        return null; // Conflict detected

                    break; // No conflict, proceed
                }
                catch (DbUpdateConcurrencyException)
                {
                    retryCount++;
                    if (retryCount >= maxRetries)
                        throw;
                    
                    // Wait before retry
                    await Task.Delay(100 * retryCount);
                }
            }

            // Get court and calculate price
            var court = await _context.Courts_345.FindAsync(request.CourtId);
            if (court == null || !court.IsActive)
                return null;

            var duration = (request.EndTime - request.StartTime).TotalHours;
            var totalPrice = (decimal)(duration * (double)court.PricePerHour);

            // Process payment
            var paymentSuccess = await _walletService.ProcessPaymentAsync(
                memberId, 
                totalPrice, 
                TransactionType.Payment, 
                $"Đặt sân {court.Name} - {request.StartTime:dd/MM/yyyy HH:mm}"
            );

            if (!paymentSuccess)
                return null;

            // Create booking
            var booking = new Booking_345
            {
                CourtId = request.CourtId,
                MemberId = memberId,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                TotalPrice = totalPrice,
                Status = BookingStatus.Confirmed,
                IsRecurring = false
            };

            _context.Bookings_345.Add(booking);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return new BookingDto
            {
                Id = booking.Id,
                CourtId = booking.CourtId,
                MemberId = booking.MemberId,
                StartTime = booking.StartTime,
                EndTime = booking.EndTime,
                TotalPrice = booking.TotalPrice,
                Status = booking.Status.ToString(),
                IsRecurring = booking.IsRecurring,
                Court = new CourtDto
                {
                    Id = court.Id,
                    Name = court.Name,
                    IsActive = court.IsActive,
                    Description = court.Description,
                    PricePerHour = court.PricePerHour
                }
            };
        }
        catch
        {
            await transaction.RollbackAsync();
            return null;
        }
    }

    public async Task<List<BookingDto>> CreateRecurringBookingAsync(int memberId, CreateRecurringBookingDto request)
    {
        var bookings = new List<BookingDto>();
        var currentDate = request.StartTime.Date;
        
        while (currentDate <= request.EndDate.Date)
        {
            var bookingRequest = new CreateBookingDto
            {
                CourtId = request.CourtId,
                StartTime = currentDate.Add(request.StartTime.TimeOfDay),
                EndTime = currentDate.Add(request.EndTime.TimeOfDay)
            };

            var booking = await CreateBookingAsync(memberId, bookingRequest);
            if (booking != null)
            {
                bookings.Add(booking);
            }

            // Add 7 days for weekly recurrence
            currentDate = currentDate.AddDays(7);
        }

        return bookings;
    }

    public async Task<bool> CancelBookingAsync(int bookingId, int memberId)
    {
        var booking = await _context.Bookings_345
            .Include(b => b.Court)
            .FirstOrDefaultAsync(b => b.Id == bookingId && b.MemberId == memberId);

        if (booking == null || booking.Status != BookingStatus.Confirmed)
            return false;

        // Check if cancellation is allowed (24 hours before)
        var hoursUntilStart = (booking.StartTime - DateTime.UtcNow).TotalHours;
        if (hoursUntilStart < 24)
            return false; // Cannot cancel within 24 hours

        // Process refund
        await _walletService.RefundAsync(
            memberId, 
            booking.TotalPrice, 
            $"Hoàn tiền hủy sân {booking.Court.Name} - {booking.StartTime:dd/MM/yyyy HH:mm}",
            booking.Id.ToString()
        );

        // Update booking status
        booking.Status = BookingStatus.Cancelled;
        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<List<BookingDto>> GetMyBookingsAsync(int memberId, int page = 1, int pageSize = 20)
    {
        return await _context.Bookings_345
            .Include(b => b.Court)
            .Where(b => b.MemberId == memberId)
            .OrderByDescending(b => b.StartTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(b => new BookingDto
            {
                Id = b.Id,
                CourtId = b.CourtId,
                MemberId = b.MemberId,
                StartTime = b.StartTime,
                EndTime = b.EndTime,
                TotalPrice = b.TotalPrice,
                Status = b.Status.ToString(),
                IsRecurring = b.IsRecurring,
                Court = new CourtDto
                {
                    Id = b.Court.Id,
                    Name = b.Court.Name,
                    IsActive = b.Court.IsActive,
                    Description = b.Court.Description,
                    PricePerHour = b.Court.PricePerHour
                }
            })
            .ToListAsync();
    }

    public async Task<bool> IsCourtAvailableAsync(int courtId, DateTime startTime, DateTime endTime, int? excludeBookingId = null)
    {
        var query = _context.Bookings_345
            .Where(b => b.CourtId == courtId && 
                       b.Status == BookingStatus.Confirmed &&
                       ((b.StartTime < endTime && b.EndTime > startTime)));

        if (excludeBookingId.HasValue)
        {
            query = query.Where(b => b.Id != excludeBookingId.Value);
        }

        return !await query.AnyAsync();
    }
}
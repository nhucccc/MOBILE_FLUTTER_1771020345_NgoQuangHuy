using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;
using pickleball_api_345.Hubs;

namespace pickleball_api_345.Services;

public class BookingService : IBookingService
{
    private readonly ApplicationDbContext _context;
    private readonly IWalletService _walletService;
    private readonly IWalletSyncService _walletSyncService;
    private readonly IHubContext<PcmHub> _hubContext;

    public BookingService(
        ApplicationDbContext context, 
        IWalletService walletService,
        IWalletSyncService walletSyncService,
        IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _walletService = walletService;
        _walletSyncService = walletSyncService;
        _hubContext = hubContext;
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
        using var transaction = await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
        try
        {
            // 1. Lock court to prevent concurrent bookings
            var court = await _context.Courts_345
                .FromSqlRaw("SELECT * FROM Courts_345 WITH (UPDLOCK) WHERE Id = {0}", request.CourtId)
                .FirstOrDefaultAsync();
                
            if (court == null || !court.IsActive)
                return null;

            // 2. Check for conflicts with pessimistic locking
            var hasConflict = await _context.Bookings_345
                .AnyAsync(b => b.CourtId == request.CourtId && 
                              b.Status == BookingStatus.Confirmed &&
                              b.StartTime < request.EndTime && 
                              b.EndTime > request.StartTime);
                              
            if (hasConflict)
                return null;

            // 3. Lock member wallet
            var member = await _context.Members_345
                .FromSqlRaw("SELECT * FROM Members_345 WITH (UPDLOCK) WHERE Id = {0}", memberId)
                .FirstOrDefaultAsync();
                
            if (member == null)
                return null;

            // 4. Calculate price and check balance
            var duration = (request.EndTime - request.StartTime).TotalHours;
            var totalPrice = (decimal)(duration * (double)court.PricePerHour);
            
            if (member.WalletBalance < totalPrice)
                return null;

            // 5. Deduct money atomically
            member.WalletBalance -= totalPrice;
            member.TotalSpent += totalPrice;

            // 6. Create booking
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

            // 7. Create wallet transaction record
            var walletTransaction = new WalletTransaction_345
            {
                MemberId = memberId,
                Amount = -totalPrice,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Đặt sân {court.Name} - {request.StartTime:dd/MM/yyyy HH:mm}",
                RelatedId = null, // Will be updated after booking is saved
                CreatedDate = DateTime.UtcNow
            };
            _context.WalletTransactions_345.Add(walletTransaction);

            // 8. Save all changes atomically
            await _context.SaveChangesAsync();
            
            // Update transaction with booking ID
            walletTransaction.RelatedId = booking.Id.ToString();
            await _context.SaveChangesAsync();
            
            await transaction.CommitAsync();

            // 9. Sync wallet balance in real-time
            await _walletSyncService.NotifyWalletUpdateAsync(
                memberId,
                -totalPrice,
                "Booking",
                $"Đặt sân {court.Name} - {request.StartTime:dd/MM/yyyy HH:mm}",
                walletTransaction.Id.ToString()
            );

            // 10. Broadcast realtime update
            await BroadcastBookingCreated(booking, court);

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
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            Console.WriteLine($"CreateBooking failed: {ex.Message}");
            return null;
        }
    }

    private async Task BroadcastBookingCreated(Booking_345 booking, Court_345 court)
    {
        try
        {
            // ✅ FIXED: Use standardized event payload
            var bookingPayload = new EventPayloads.BookingPayload
            {
                BookingId = booking.Id,
                CourtId = booking.CourtId,
                CourtName = court.Name,
                StartTime = booking.StartTime,
                EndTime = booking.EndTime,
                Status = booking.Status.ToString(),
                MemberId = booking.MemberId,
                MemberName = "", // Would need to include Member in query
                Timestamp = DateTime.UtcNow
            };

            // Broadcast to all users for calendar updates
            await _hubContext.Clients.All.SendAsync(SignalREvents.BookingCreated, bookingPayload);
            
            // Broadcast calendar refresh with standardized payload
            var calendarRefresh = new
            {
                Date = booking.StartTime.Date,
                CourtId = booking.CourtId,
                Action = "BookingCreated",
                Timestamp = DateTime.UtcNow
            };
            await _hubContext.Clients.All.SendAsync(SignalREvents.RefreshCalendar, calendarRefresh);

            Console.WriteLine($"✅ Broadcasted booking created: Court {court.Name}, Time {booking.StartTime}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Failed to broadcast booking: {ex.Message}");
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
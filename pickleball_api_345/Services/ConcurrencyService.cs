using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public class ConcurrencyService : IConcurrencyService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ConcurrencyService> _logger;
    private readonly INotificationService _notificationService;

    public ConcurrencyService(
        ApplicationDbContext context,
        ILogger<ConcurrencyService> logger,
        INotificationService notificationService)
    {
        _context = context;
        _logger = logger;
        _notificationService = notificationService;
    }

    public async Task<ConcurrentBookingResultDto> CreateBookingWithConcurrencyCheckAsync(CreateBookingDto request, int memberId)
    {
        const int maxRetries = 3;
        var retryCount = 0;

        while (retryCount < maxRetries)
        {
            try
            {
                using var transaction = await _context.Database.BeginTransactionAsync();

                // Check if slot is still available
                var conflictingBookings = await GetConflictingBookingsAsync(
                    request.CourtId, request.StartTime, request.EndTime);

                if (conflictingBookings.Any())
                {
                    return new ConcurrentBookingResultDto
                    {
                        Success = false,
                        Message = "Slot đã được đặt bởi người khác",
                        ConflictingBookings = conflictingBookings,
                        ConflictType = "TimeConflict"
                    };
                }

                // Get member and court info
                var member = await _context.Members_345.FindAsync(memberId);
                var court = await _context.Courts_345.FindAsync(request.CourtId);

                if (member == null || court == null)
                {
                    return new ConcurrentBookingResultDto
                    {
                        Success = false,
                        Message = "Không tìm thấy thông tin thành viên hoặc sân",
                        ConflictType = "None"
                    };
                }

                // Calculate total price
                var duration = request.EndTime - request.StartTime;
                var totalPrice = (decimal)duration.TotalHours * court.PricePerHour;

                // Check wallet balance
                if (member.WalletBalance < totalPrice)
                {
                    return new ConcurrentBookingResultDto
                    {
                        Success = false,
                        Message = "Số dư ví không đủ để thanh toán",
                        ConflictType = "None"
                    };
                }

                // Create booking with optimistic concurrency
                var booking = new Booking_345
                {
                    CourtId = request.CourtId,
                    MemberId = memberId,
                    StartTime = request.StartTime,
                    EndTime = request.EndTime,
                    TotalPrice = totalPrice,
                    Status = BookingStatus.PendingPayment,
                    CreatedDate = DateTime.UtcNow,
                    Notes = request.Notes
                };

                _context.Bookings_345.Add(booking);

                // Save changes with concurrency check
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                _logger.LogInformation($"Successfully created booking {booking.Id} for member {memberId}");

                // Send notification
                await _notificationService.SendNotificationAsync(
                    memberId,
                    "Đặt sân thành công",
                    $"Bạn đã đặt thành công {court.Name} từ {request.StartTime:HH:mm} đến {request.EndTime:HH:mm}",
                    NotificationType.Success
                );

                return new ConcurrentBookingResultDto
                {
                    Success = true,
                    Message = "Đặt sân thành công",
                    Booking = new BookingDto
                    {
                        Id = booking.Id,
                        CourtId = booking.CourtId,
                        CourtName = court.Name,
                        MemberId = booking.MemberId,
                        MemberName = member.FullName,
                        StartTime = booking.StartTime,
                        EndTime = booking.EndTime,
                        TotalPrice = booking.TotalPrice,
                        Status = booking.Status.ToString(),
                        CreatedDate = booking.CreatedDate,
                        Notes = booking.Notes
                    },
                    ConflictType = "None"
                };
            }
            catch (DbUpdateConcurrencyException ex)
            {
                retryCount++;
                _logger.LogWarning($"Concurrency conflict detected, retry {retryCount}/{maxRetries}. Error: {ex.Message}");

                if (retryCount >= maxRetries)
                {
                    return new ConcurrentBookingResultDto
                    {
                        Success = false,
                        Message = "Có nhiều người cùng đặt slot này. Vui lòng thử lại.",
                        ConflictType = "ConcurrencyConflict"
                    };
                }

                // Wait a bit before retrying
                await Task.Delay(100 * retryCount);
                
                // Refresh context
                foreach (var entry in _context.ChangeTracker.Entries())
                {
                    await entry.ReloadAsync();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating booking");
                return new ConcurrentBookingResultDto
                {
                    Success = false,
                    Message = "Có lỗi xảy ra khi đặt sân",
                    ConflictType = "None"
                };
            }
        }

        return new ConcurrentBookingResultDto
        {
            Success = false,
            Message = "Không thể đặt sân sau nhiều lần thử",
            ConflictType = "ConcurrencyConflict"
        };
    }

    public async Task<bool> HandleConcurrencyConflictAsync(int bookingId, byte[] originalRowVersion)
    {
        try
        {
            var booking = await _context.Bookings_345.FindAsync(bookingId);
            if (booking == null)
                return false;

            // Check if the row version matches
            if (!booking.RowVersion.SequenceEqual(originalRowVersion))
            {
                _logger.LogWarning($"Concurrency conflict detected for booking {bookingId}");
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error handling concurrency conflict");
            return false;
        }
    }

    private async Task<List<ConflictingBookingDto>> GetConflictingBookingsAsync(int courtId, DateTime startTime, DateTime endTime)
    {
        try
        {
            var conflictingBookings = await _context.Bookings_345
                .Include(b => b.Member)
                .Where(b => b.CourtId == courtId &&
                           (b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.PendingPayment) &&
                           ((b.StartTime < endTime && b.EndTime > startTime)))
                .Select(b => new ConflictingBookingDto
                {
                    BookingId = b.Id,
                    MemberName = b.Member.FullName,
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    Status = b.Status.ToString()
                })
                .ToListAsync();

            return conflictingBookings;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting conflicting bookings");
            return new List<ConflictingBookingDto>();
        }
    }
}
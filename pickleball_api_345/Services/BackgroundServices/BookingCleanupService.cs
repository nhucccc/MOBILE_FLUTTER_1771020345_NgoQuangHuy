using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services.BackgroundServices;

public class BookingCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BookingCleanupService> _logger;

    public BookingCleanupService(IServiceProvider serviceProvider, ILogger<BookingCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessUnpaidBookings();
                await SendReminders();
                
                // Chạy mỗi phút
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in BookingCleanupService");
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }

    private async Task ProcessUnpaidBookings()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var walletService = scope.ServiceProvider.GetRequiredService<IWalletService>();

        // Tìm booking "Hold" quá 5 phút chưa thanh toán
        var cutoffTime = DateTime.UtcNow.AddMinutes(-5);
        var unpaidBookings = await context.Bookings_345
            .Include(b => b.Court)
            .Include(b => b.Member)
            .Where(b => b.Status == BookingStatus.PendingPayment && 
                       b.CreatedDate < cutoffTime)
            .ToListAsync();

        foreach (var booking in unpaidBookings)
        {
            try
            {
                // Hủy booking
                booking.Status = BookingStatus.Cancelled;
                booking.CancelledDate = DateTime.UtcNow;
                booking.CancelReason = "Tự động hủy do không thanh toán trong 5 phút";

                _logger.LogInformation($"Auto-cancelled booking {booking.Id} for member {booking.Member.FullName}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error cancelling booking {booking.Id}");
            }
        }

        if (unpaidBookings.Any())
        {
            await context.SaveChangesAsync();
            _logger.LogInformation($"Auto-cancelled {unpaidBookings.Count} unpaid bookings");
        }
    }

    private async Task SendReminders()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

        // Tìm booking sắp diễn ra trong 24 giờ tới
        var tomorrow = DateTime.UtcNow.AddDays(1);
        var reminderTime = DateTime.UtcNow.AddHours(23); // 23-25 giờ tới

        var upcomingBookings = await context.Bookings_345
            .Include(b => b.Court)
            .Include(b => b.Member)
            .Where(b => b.Status == BookingStatus.Confirmed &&
                       b.StartTime >= reminderTime &&
                       b.StartTime <= tomorrow &&
                       !b.ReminderSent)
            .ToListAsync();

        foreach (var booking in upcomingBookings)
        {
            try
            {
                var message = $"Nhắc nhở: Bạn có lịch đặt {booking.Court.Name} vào {booking.StartTime:dd/MM/yyyy HH:mm}";
                
                await notificationService.SendNotificationAsync(
                    booking.MemberId,
                    "Nhắc nhở lịch đặt sân",
                    message,
                    NotificationType.Info
                );

                booking.ReminderSent = true;
                _logger.LogInformation($"Sent reminder for booking {booking.Id} to member {booking.Member.FullName}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending reminder for booking {booking.Id}");
            }
        }

        if (upcomingBookings.Any())
        {
            await context.SaveChangesAsync();
            _logger.LogInformation($"Sent {upcomingBookings.Count} booking reminders");
        }
    }
}
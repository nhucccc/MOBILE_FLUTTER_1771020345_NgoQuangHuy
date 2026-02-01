using Microsoft.Extensions.Caching.Memory;

namespace pickleball_api_345.Services.BackgroundServices;

public class SlotCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<SlotCleanupService> _logger;
    private readonly TimeSpan _cleanupInterval = TimeSpan.FromMinutes(1); // Run every minute

    public SlotCleanupService(
        IServiceProvider serviceProvider,
        ILogger<SlotCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("✅ Slot Cleanup Service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var slotReservationService = scope.ServiceProvider.GetRequiredService<ISlotReservationService>();
                
                await slotReservationService.CleanupExpiredReservationsAsync();
                
                await Task.Delay(_cleanupInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Expected when cancellation is requested
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Error in Slot Cleanup Service");
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken); // Wait 5 minutes before retry
            }
        }

        _logger.LogInformation("🛑 Slot Cleanup Service stopped");
    }
}
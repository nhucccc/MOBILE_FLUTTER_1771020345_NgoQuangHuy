using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services.BackgroundServices;

public class TierUpdateService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<TierUpdateService> _logger;
    private readonly TimeSpan _period = TimeSpan.FromHours(6); // Run every 6 hours

    public TierUpdateService(
        IServiceProvider serviceProvider,
        ILogger<TierUpdateService> logger)
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
                await UpdateMemberTiers();
                await Task.Delay(_period, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Expected when cancellation is requested
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred while updating member tiers");
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken); // Wait 5 minutes before retry
            }
        }
    }

    private async Task UpdateMemberTiers()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

        _logger.LogInformation("Starting member tier update process");

        var members = await context.Members_345
            .Where(m => m.IsActive)
            .ToListAsync();

        var updatedCount = 0;

        foreach (var member in members)
        {
            var oldTier = member.Tier;
            var newTier = CalculateTier(member.TotalSpent);

            if (oldTier != newTier)
            {
                member.Tier = newTier;
                updatedCount++;

                _logger.LogInformation(
                    "Updated member {MemberId} tier from {OldTier} to {NewTier} (Total spent: {TotalSpent})",
                    member.Id, oldTier, newTier, member.TotalSpent);

                // Send tier upgrade notification
                try
                {
                    await notificationService.SendNotificationAsync(
                        member.Id, // Use member ID instead of UserId
                        "🎉 Chúc mừng! Bạn đã được nâng hạng",
                        $"Bạn đã được nâng lên hạng {GetTierDisplayName(newTier)}! " +
                        $"Hãy tận hưởng các quyền lợi đặc biệt dành cho thành viên {GetTierDisplayName(newTier)}.",
                        NotificationType.Success
                    );
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send tier upgrade notification to member {MemberId}", member.Id);
                }
            }
        }

        if (updatedCount > 0)
        {
            await context.SaveChangesAsync();
            _logger.LogInformation("Updated {UpdatedCount} member tiers", updatedCount);
        }
        else
        {
            _logger.LogInformation("No tier updates needed");
        }
    }

    private static MemberTier CalculateTier(decimal totalSpent)
    {
        return totalSpent switch
        {
            >= 10000000 => MemberTier.Diamond,  // 10M VND
            >= 5000000 => MemberTier.Gold,      // 5M VND
            >= 2000000 => MemberTier.Silver,    // 2M VND
            _ => MemberTier.Standard
        };
    }

    private static string GetTierDisplayName(MemberTier tier)
    {
        return tier switch
        {
            MemberTier.Standard => "Tiêu chuẩn",
            MemberTier.Silver => "Bạc",
            MemberTier.Gold => "Vàng",
            MemberTier.Diamond => "Kim cương",
            _ => "Không xác định"
        };
    }
}

// Extension method to register the service
public static class TierUpdateServiceExtensions
{
    public static IServiceCollection AddTierUpdateService(this IServiceCollection services)
    {
        services.AddHostedService<TierUpdateService>();
        return services;
    }
}
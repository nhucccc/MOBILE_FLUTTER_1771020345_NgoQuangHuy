using Microsoft.Extensions.Caching.Memory;
using Microsoft.AspNetCore.SignalR;
using pickleball_api_345.Hubs;

namespace pickleball_api_345.Services;

public interface ISlotReservationService
{
    Task<bool> ReserveSlotAsync(int courtId, DateTime startTime, DateTime endTime, int memberId);
    Task<bool> ReleaseSlotAsync(int courtId, DateTime startTime, DateTime endTime, int memberId);
    Task<bool> IsSlotReservedAsync(int courtId, DateTime startTime, DateTime endTime);
    Task<SlotReservation?> GetSlotReservationAsync(int courtId, DateTime startTime, DateTime endTime);
    Task CleanupExpiredReservationsAsync();
}

public class SlotReservation
{
    public int CourtId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int MemberId { get; set; }
    public DateTime ReservedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
}

public class SlotReservationService : ISlotReservationService
{
    private readonly IMemoryCache _cache;
    private readonly IHubContext<PcmHub> _hubContext;
    private readonly ILogger<SlotReservationService> _logger;
    private const int RESERVATION_MINUTES = 5;

    public SlotReservationService(
        IMemoryCache cache, 
        IHubContext<PcmHub> hubContext,
        ILogger<SlotReservationService> logger)
    {
        _cache = cache;
        _hubContext = hubContext;
        _logger = logger;
    }

    public async Task<bool> ReserveSlotAsync(int courtId, DateTime startTime, DateTime endTime, int memberId)
    {
        var key = GetSlotKey(courtId, startTime, endTime);
        
        // Check if already reserved
        if (_cache.TryGetValue(key, out SlotReservation? existingReservation))
        {
            // If reserved by same user, extend the reservation
            if (existingReservation?.MemberId == memberId)
            {
                existingReservation.ExpiresAt = DateTime.UtcNow.AddMinutes(RESERVATION_MINUTES);
                _cache.Set(key, existingReservation, existingReservation.ExpiresAt);
                return true;
            }
            
            // If reserved by different user and not expired, reject
            if (existingReservation?.ExpiresAt > DateTime.UtcNow)
            {
                return false;
            }
        }

        // Create new reservation
        var reservation = new SlotReservation
        {
            CourtId = courtId,
            StartTime = startTime,
            EndTime = endTime,
            MemberId = memberId,
            ReservedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddMinutes(RESERVATION_MINUTES)
        };

        _cache.Set(key, reservation, reservation.ExpiresAt);

        // Broadcast slot status change
        await BroadcastSlotStatusChange(courtId, startTime, endTime, "Reserved", memberId);

        _logger.LogInformation($"Slot reserved: Court {courtId}, {startTime:HH:mm}-{endTime:HH:mm} by Member {memberId}");
        return true;
    }

    public async Task<bool> ReleaseSlotAsync(int courtId, DateTime startTime, DateTime endTime, int memberId)
    {
        var key = GetSlotKey(courtId, startTime, endTime);
        
        if (_cache.TryGetValue(key, out SlotReservation? reservation))
        {
            // Only allow the same user to release their reservation
            if (reservation?.MemberId == memberId)
            {
                _cache.Remove(key);
                
                // Broadcast slot status change
                await BroadcastSlotStatusChange(courtId, startTime, endTime, "Available", null);
                
                _logger.LogInformation($"Slot released: Court {courtId}, {startTime:HH:mm}-{endTime:HH:mm} by Member {memberId}");
                return true;
            }
        }

        return false;
    }

    public async Task<bool> IsSlotReservedAsync(int courtId, DateTime startTime, DateTime endTime)
    {
        var key = GetSlotKey(courtId, startTime, endTime);
        
        if (_cache.TryGetValue(key, out SlotReservation? reservation))
        {
            if (reservation?.ExpiresAt > DateTime.UtcNow)
            {
                return true;
            }
            else
            {
                // Clean up expired reservation
                _cache.Remove(key);
                await BroadcastSlotStatusChange(courtId, startTime, endTime, "Available", null);
            }
        }

        return false;
    }

    public async Task<SlotReservation?> GetSlotReservationAsync(int courtId, DateTime startTime, DateTime endTime)
    {
        var key = GetSlotKey(courtId, startTime, endTime);
        
        if (_cache.TryGetValue(key, out SlotReservation? reservation))
        {
            if (reservation?.ExpiresAt > DateTime.UtcNow)
            {
                return reservation;
            }
            else
            {
                // Clean up expired reservation
                _cache.Remove(key);
                await BroadcastSlotStatusChange(courtId, startTime, endTime, "Available", null);
            }
        }

        return null;
    }

    public async Task CleanupExpiredReservationsAsync()
    {
        // This would be called by a background service
        // For now, cleanup happens on-demand in other methods
        await Task.CompletedTask;
    }

    private string GetSlotKey(int courtId, DateTime startTime, DateTime endTime)
    {
        return $"slot_{courtId}_{startTime:yyyyMMddHHmm}_{endTime:yyyyMMddHHmm}";
    }

    private async Task BroadcastSlotStatusChange(int courtId, DateTime startTime, DateTime endTime, string status, int? memberId)
    {
        try
        {
            var slotPayload = new EventPayloads.SlotStatusPayload
            {
                CourtId = courtId,
                StartTime = startTime,
                EndTime = endTime,
                Status = status,
                MemberId = memberId,
                ExpiresAt = status == "Reserved" ? DateTime.UtcNow.AddMinutes(RESERVATION_MINUTES) : null,
                Timestamp = DateTime.UtcNow
            };

            await _hubContext.Clients.All.SendAsync(SignalREvents.SlotStatusChanged, slotPayload);
            
            _logger.LogInformation($"✅ Broadcasted slot status change: Court {courtId}, Status {status}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Failed to broadcast slot status change for Court {courtId}");
        }
    }
}
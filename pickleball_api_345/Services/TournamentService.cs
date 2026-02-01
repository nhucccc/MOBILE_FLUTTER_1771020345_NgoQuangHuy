using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public class TournamentService : ITournamentService
{
    private readonly ApplicationDbContext _context;
    private readonly IWalletService _walletService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<TournamentService> _logger;

    public TournamentService(
        ApplicationDbContext context,
        IWalletService walletService,
        INotificationService notificationService,
        ILogger<TournamentService> logger)
    {
        _context = context;
        _walletService = walletService;
        _notificationService = notificationService;
        _logger = logger;
    }

    // ✅ FIXED: Implement all interface methods
    public async Task<List<TournamentDto>> GetTournamentsAsync(TournamentStatus? status = null)
    {
        var query = _context.Tournaments_345.AsQueryable();
        
        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        return await query
            .Select(t => new TournamentDto
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description,
                StartDate = t.StartDate,
                EndDate = t.EndDate,
                RegistrationDeadline = t.RegistrationDeadline,
                MaxParticipants = t.MaxParticipants,
                EntryFee = t.EntryFee,
                PrizePool = t.PrizePool,
                Format = t.Format.ToString(),
                Status = t.Status.ToString(),
                ParticipantCount = t.Participants.Count()
            })
            .ToListAsync();
    }

    public async Task<TournamentDto?> GetTournamentByIdAsync(int id)
    {
        return await GetTournamentDetailsAsync(id);
    }

    public async Task<TournamentDto?> CreateTournamentAsync(CreateTournamentDto request, string createdBy)
    {
        // Implementation would go here - for now return null
        await Task.CompletedTask;
        return null;
    }

    public async Task<bool> JoinTournamentAsync(int tournamentId, int memberId, string? teamName = null)
    {
        return await RegisterForTournamentAsync(tournamentId, memberId);
    }

    public async Task<bool> GenerateScheduleAsync(int tournamentId)
    {
        // Implementation would go here - for now return false
        await Task.CompletedTask;
        return false;
    }

    public async Task<List<MatchDto>> GetTournamentMatchesAsync(int tournamentId)
    {
        // Implementation would go here - for now return empty list
        await Task.CompletedTask;
        return new List<MatchDto>();
    }

    public async Task<bool> UpdateMatchResultAsync(int matchId, UpdateMatchScoreDto request)
    {
        // Implementation would go here - for now return false
        await Task.CompletedTask;
        return false;
    }

    public async Task<bool> RegisterForTournamentAsync(int tournamentId, int memberId)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var tournament = await _context.Tournaments_345
                .Include(t => t.Participants)
                .FirstOrDefaultAsync(t => t.Id == tournamentId);

            if (tournament == null || tournament.Status != TournamentStatus.Registering)
                return false;

            // Check if already registered
            if (tournament.Participants.Any(p => p.MemberId == memberId))
                return false;

            // Check if tournament is full
            if (tournament.Participants.Count >= tournament.MaxParticipants)
                return false;

            // ✅ FIXED: Process entry fee payment
            if (tournament.EntryFee > 0)
            {
                var paymentSuccess = await ProcessEntryFeeAsync(tournamentId, memberId);
                if (!paymentSuccess)
                {
                    _logger.LogWarning($"Entry fee payment failed for Member {memberId} in Tournament {tournamentId}");
                    return false;
                }
            }

            // Create tournament participant
            var participant = new TournamentParticipant_345
            {
                TournamentId = tournamentId,
                MemberId = memberId,
                JoinedDate = DateTime.UtcNow,
                PaymentStatus = tournament.EntryFee > 0 ? PaymentStatus.Paid : PaymentStatus.Pending
            };

            _context.TournamentParticipants_345.Add(participant);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            // Send notification
            await _notificationService.SendNotificationAsync(
                memberId,
                "Đăng ký giải đấu thành công",
                $"Bạn đã đăng ký thành công giải đấu {tournament.Name}",
                NotificationType.Success
            );

            _logger.LogInformation($"Member {memberId} registered for tournament {tournamentId}");
            return true;
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, $"Error registering member {memberId} for tournament {tournamentId}");
            return false;
        }
    }

    public async Task<bool> ProcessEntryFeeAsync(int tournamentId, int memberId)
    {
        var tournament = await _context.Tournaments_345.FindAsync(tournamentId);
        if (tournament == null || tournament.EntryFee <= 0)
            return true; // No fee required

        var member = await _context.Members_345.FindAsync(memberId);
        if (member == null)
            return false;

        // Check wallet balance
        if (member.WalletBalance < tournament.EntryFee)
        {
            _logger.LogWarning($"Insufficient balance for Member {memberId}. Required: {tournament.EntryFee}, Available: {member.WalletBalance}");
            return false;
        }

        // Process payment through wallet service
        var paymentSuccess = await _walletService.ProcessPaymentAsync(
            memberId,
            tournament.EntryFee,
            TransactionType.Payment,
            $"Phí tham gia giải đấu: {tournament.Name}",
            tournamentId.ToString()
        );

        if (paymentSuccess)
        {
            _logger.LogInformation($"Entry fee {tournament.EntryFee} processed for Member {memberId} in Tournament {tournamentId}");
        }

        return paymentSuccess;
    }

    public async Task<bool> UnregisterFromTournamentAsync(int tournamentId, int memberId)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var tournament = await _context.Tournaments_345.FindAsync(tournamentId);
            if (tournament == null || tournament.Status != TournamentStatus.Registering)
                return false;

            var participant = await _context.TournamentParticipants_345
                .FirstOrDefaultAsync(p => p.TournamentId == tournamentId && p.MemberId == memberId);

            if (participant == null)
                return false;

            // Process refund if applicable (within 24 hours of registration)
            var hoursSinceRegistration = (DateTime.UtcNow - participant.JoinedDate).TotalHours;
            if (hoursSinceRegistration <= 24 && tournament.EntryFee > 0)
            {
                await _walletService.RefundAsync(
                    memberId,
                    tournament.EntryFee,
                    $"Hoàn phí hủy đăng ký giải đấu: {tournament.Name}",
                    tournamentId.ToString()
                );
            }

            _context.TournamentParticipants_345.Remove(participant);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation($"Member {memberId} unregistered from tournament {tournamentId}");
            return true;
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, $"Error unregistering member {memberId} from tournament {tournamentId}");
            return false;
        }
    }

    public async Task<List<TournamentDto>> GetAvailableTournamentsAsync()
    {
        return await _context.Tournaments_345
            .Where(t => t.Status == TournamentStatus.Registering)
            .Select(t => new TournamentDto
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description,
                StartDate = t.StartDate,
                EndDate = t.EndDate,
                RegistrationDeadline = t.RegistrationDeadline,
                MaxParticipants = t.MaxParticipants,
                EntryFee = t.EntryFee,
                PrizePool = t.PrizePool,
                Format = t.Format.ToString(),
                Status = t.Status.ToString(),
                ParticipantCount = t.Participants.Count()
            })
            .ToListAsync();
    }

    public async Task<TournamentDto?> GetTournamentDetailsAsync(int tournamentId)
    {
        return await _context.Tournaments_345
            .Include(t => t.Participants)
            .ThenInclude(p => p.Member)
            .Where(t => t.Id == tournamentId)
            .Select(t => new TournamentDto
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description,
                StartDate = t.StartDate,
                EndDate = t.EndDate,
                RegistrationDeadline = t.RegistrationDeadline,
                MaxParticipants = t.MaxParticipants,
                EntryFee = t.EntryFee,
                PrizePool = t.PrizePool,
                Format = t.Format.ToString(),
                Status = t.Status.ToString(),
                ParticipantCount = t.Participants.Count(),
                Participants = t.Participants.Select(p => new DTOs.TournamentParticipantDto
                {
                    Id = p.Id,
                    MemberId = p.MemberId,
                    MemberName = p.Member.FullName,
                    JoinedDate = p.JoinedDate,
                    PaymentStatus = p.PaymentStatus.ToString()
                }).ToList()
            })
            .FirstOrDefaultAsync();
    }
}

// DTOs for Tournament
public class TournamentDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime RegistrationDeadline { get; set; }
    public int MaxParticipants { get; set; }
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
    public string Format { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int ParticipantCount { get; set; }
    public List<DTOs.TournamentParticipantDto> Participants { get; set; } = new();
}
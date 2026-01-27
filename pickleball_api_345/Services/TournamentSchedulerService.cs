using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public interface ITournamentSchedulerService
{
    Task<bool> GenerateScheduleAsync(int tournamentId);
    Task<bool> GenerateKnockoutBracketAsync(int tournamentId);
    Task<bool> GenerateRoundRobinScheduleAsync(int tournamentId);
}

public class TournamentSchedulerService : ITournamentSchedulerService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<TournamentSchedulerService> _logger;

    public TournamentSchedulerService(
        ApplicationDbContext context,
        ILogger<TournamentSchedulerService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<bool> GenerateScheduleAsync(int tournamentId)
    {
        var tournament = await _context.Tournaments_345
            .Include(t => t.Participants)
            .FirstOrDefaultAsync(t => t.Id == tournamentId);

        if (tournament == null || tournament.Status != TournamentStatus.Registering)
        {
            return false;
        }

        try
        {
            bool success = tournament.Format switch
            {
                TournamentFormat.RoundRobin => await GenerateRoundRobinScheduleAsync(tournamentId),
                TournamentFormat.Knockout => await GenerateKnockoutBracketAsync(tournamentId),
                TournamentFormat.Hybrid => await GenerateHybridScheduleAsync(tournamentId),
                _ => false
            };

            if (success)
            {
                tournament.Status = TournamentStatus.DrawCompleted;
                await _context.SaveChangesAsync();
            }

            return success;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating schedule for tournament {TournamentId}", tournamentId);
            return false;
        }
    }

    public async Task<bool> GenerateKnockoutBracketAsync(int tournamentId)
    {
        var tournament = await _context.Tournaments_345
            .Include(t => t.Participants)
            .ThenInclude(p => p.Member)
            .FirstOrDefaultAsync(t => t.Id == tournamentId);

        if (tournament == null) return false;

        var participants = tournament.Participants.ToList();
        if (participants.Count < 2) return false;

        // Shuffle participants for random seeding
        var random = new Random();
        participants = participants.OrderBy(x => random.Next()).ToList();

        // Ensure power of 2 participants (add byes if needed)
        var roundSize = GetNextPowerOfTwo(participants.Count);
        var rounds = new List<string>();

        // Determine round names based on bracket size
        if (roundSize >= 32) rounds.Add("Round of 32");
        if (roundSize >= 16) rounds.Add("Round of 16");
        if (roundSize >= 8) rounds.Add("Quarter Final");
        if (roundSize >= 4) rounds.Add("Semi Final");
        rounds.Add("Final");

        var currentRound = rounds[0];
        var matchNumber = 1;
        var startDate = tournament.StartDate;

        // Create first round matches
        for (int i = 0; i < participants.Count; i += 2)
        {
            var team1 = participants[i];
            var team2 = i + 1 < participants.Count ? participants[i + 1] : null;

            var match = new Match_345
            {
                TournamentId = tournamentId,
                RoundName = currentRound,
                Date = startDate.AddDays(GetRoundDay(currentRound)),
                StartTime = TimeSpan.FromHours(9 + (matchNumber % 8)), // Spread matches throughout the day
                Team1_Player1Id = team1.MemberId,
                Team1_Player2Id = null, // Single player for now
                Team2_Player1Id = team2?.MemberId ?? 0,
                Team2_Player2Id = null,
                Status = MatchStatus.Scheduled,
                IsRanked = true
            };

            _context.Matches_345.Add(match);
            matchNumber++;
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> GenerateRoundRobinScheduleAsync(int tournamentId)
    {
        var tournament = await _context.Tournaments_345
            .Include(t => t.Participants)
            .ThenInclude(p => p.Member)
            .FirstOrDefaultAsync(t => t.Id == tournamentId);

        if (tournament == null) return false;

        var participants = tournament.Participants.ToList();
        if (participants.Count < 3) return false;

        // Divide participants into groups (max 6 per group)
        var groups = DivideIntoGroups(participants, 6);
        var matchNumber = 1;
        var startDate = tournament.StartDate;

        foreach (var group in groups.Select((g, index) => new { Group = g, Index = index }))
        {
            var groupName = $"Group {(char)('A' + group.Index)}";
            var groupParticipants = group.Group;

            // Generate round-robin matches for this group
            for (int i = 0; i < groupParticipants.Count; i++)
            {
                for (int j = i + 1; j < groupParticipants.Count; j++)
                {
                    var team1 = groupParticipants[i];
                    var team2 = groupParticipants[j];

                    var match = new Match_345
                    {
                        TournamentId = tournamentId,
                        RoundName = groupName,
                        Date = startDate.AddDays((matchNumber - 1) / 8), // 8 matches per day
                        StartTime = TimeSpan.FromHours(9 + ((matchNumber - 1) % 8)),
                        Team1_Player1Id = team1.MemberId,
                        Team1_Player2Id = null,
                        Team2_Player1Id = team2.MemberId,
                        Team2_Player2Id = null,
                        Status = MatchStatus.Scheduled,
                        IsRanked = true
                    };

                    _context.Matches_345.Add(match);
                    matchNumber++;
                }
            }
        }

        await _context.SaveChangesAsync();
        return true;
    }

    private async Task<bool> GenerateHybridScheduleAsync(int tournamentId)
    {
        // First generate round-robin groups
        var roundRobinSuccess = await GenerateRoundRobinScheduleAsync(tournamentId);
        if (!roundRobinSuccess) return false;

        // Then create knockout bracket for group winners
        // This would be implemented based on specific tournament rules
        // For now, we'll just return success after round-robin
        return true;
    }

    private static int GetNextPowerOfTwo(int number)
    {
        int power = 1;
        while (power < number)
        {
            power *= 2;
        }
        return power;
    }

    private static int GetRoundDay(string roundName)
    {
        return roundName switch
        {
            "Round of 32" => 0,
            "Round of 16" => 1,
            "Quarter Final" => 2,
            "Semi Final" => 3,
            "Final" => 4,
            "Third Place" => 4,
            _ => 0
        };
    }

    private static List<List<T>> DivideIntoGroups<T>(List<T> items, int maxGroupSize)
    {
        var groups = new List<List<T>>();
        var totalGroups = (int)Math.Ceiling((double)items.Count / maxGroupSize);

        for (int i = 0; i < totalGroups; i++)
        {
            var group = items.Skip(i * maxGroupSize).Take(maxGroupSize).ToList();
            groups.Add(group);
        }

        return groups;
    }
}

// Extension method to register the service
public static class TournamentSchedulerServiceExtensions
{
    public static IServiceCollection AddTournamentSchedulerService(this IServiceCollection services)
    {
        services.AddScoped<ITournamentSchedulerService, TournamentSchedulerService>();
        return services;
    }
}
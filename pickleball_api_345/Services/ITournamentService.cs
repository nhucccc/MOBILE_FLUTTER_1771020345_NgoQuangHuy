using pickleball_api_345.DTOs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public interface ITournamentService
{
    Task<List<TournamentDto>> GetTournamentsAsync(TournamentStatus? status = null);
    Task<TournamentDto?> GetTournamentByIdAsync(int id);
    Task<TournamentDto?> CreateTournamentAsync(CreateTournamentDto request, string createdBy);
    Task<bool> JoinTournamentAsync(int tournamentId, int memberId, string? teamName = null);
    Task<bool> GenerateScheduleAsync(int tournamentId);
    Task<List<MatchDto>> GetTournamentMatchesAsync(int tournamentId);
    Task<bool> UpdateMatchResultAsync(int matchId, UpdateMatchResultDto request);
}
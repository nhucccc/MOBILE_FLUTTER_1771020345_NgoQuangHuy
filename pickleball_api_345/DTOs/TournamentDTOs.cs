using System.ComponentModel.DataAnnotations;
using pickleball_api_345.Models;

namespace pickleball_api_345.DTOs;

public class TournamentDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Format { get; set; } = string.Empty;
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int MaxParticipants { get; set; }
    public int CurrentParticipants { get; set; }
    public DateTime CreatedDate { get; set; }
    public string? CreatedBy { get; set; }
    public bool CanJoin { get; set; }
    public bool HasJoined { get; set; }
}

public class CreateTournamentDto
{
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    public TournamentFormat Format { get; set; } = TournamentFormat.RoundRobin;
    
    [Range(0, 10000000)]
    public decimal EntryFee { get; set; } = 0;
    
    [Range(0, 100000000)]
    public decimal PrizePool { get; set; } = 0;
    
    [MaxLength(1000)]
    public string? Description { get; set; }
    
    [Range(4, 128)]
    public int MaxParticipants { get; set; } = 32;
    
    public string? Settings { get; set; } // JSON configuration
}

public class JoinTournamentDto
{
    [Required]
    public int TournamentId { get; set; }
    
    [MaxLength(100)]
    public string? TeamName { get; set; }
    
    [MaxLength(500)]
    public string? Notes { get; set; }
}

public class MatchDto
{
    public int Id { get; set; }
    public int? TournamentId { get; set; }
    public string? TournamentName { get; set; }
    public string? RoundName { get; set; }
    public DateTime Date { get; set; }
    public TimeSpan StartTime { get; set; }
    public string Team1_Player1Name { get; set; } = string.Empty;
    public string? Team1_Player2Name { get; set; }
    public string Team2_Player1Name { get; set; } = string.Empty;
    public string? Team2_Player2Name { get; set; }
    public int? Score1 { get; set; }
    public int? Score2 { get; set; }
    public string? Details { get; set; }
    public string? WinningSide { get; set; }
    public bool IsRanked { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? CourtName { get; set; }
}

public class UpdateMatchResultDto
{
    [Required]
    public int Score1 { get; set; }
    
    [Required]
    public int Score2 { get; set; }
    
    [Required]
    public WinningSide WinningSide { get; set; }
    
    [MaxLength(1000)]
    public string? Details { get; set; } // JSON string for set details
    
    public bool IsRanked { get; set; } = true;
}
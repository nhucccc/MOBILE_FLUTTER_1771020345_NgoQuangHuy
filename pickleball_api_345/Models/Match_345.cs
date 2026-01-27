using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace pickleball_api_345.Models;

[Table("345_Matches")]
public class Match_345
{
    [Key]
    public int Id { get; set; }
    
    public int? TournamentId { get; set; }
    
    [MaxLength(100)]
    public string? RoundName { get; set; }
    
    public DateTime Date { get; set; }
    
    public TimeSpan StartTime { get; set; }
    
    // Team 1 participants
    public int Team1_Player1Id { get; set; }
    public int? Team1_Player2Id { get; set; }
    
    // Team 2 participants
    public int Team2_Player1Id { get; set; }
    public int? Team2_Player2Id { get; set; }
    
    // Results
    public int? Score1 { get; set; }
    public int? Score2 { get; set; }
    
    public string? Details { get; set; } // JSON string for set details
    
    public WinningSide? WinningSide { get; set; }
    
    public bool IsRanked { get; set; } = true;
    
    public MatchStatus Status { get; set; } = MatchStatus.Scheduled;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    public int? CourtId { get; set; }
    
    // Navigation properties
    [ForeignKey("TournamentId")]
    public virtual Tournament_345? Tournament { get; set; }
    
    [ForeignKey("Team1_Player1Id")]
    public virtual Member_345 Team1_Player1 { get; set; } = null!;
    
    [ForeignKey("Team1_Player2Id")]
    public virtual Member_345? Team1_Player2 { get; set; }
    
    [ForeignKey("Team2_Player1Id")]
    public virtual Member_345 Team2_Player1 { get; set; } = null!;
    
    [ForeignKey("Team2_Player2Id")]
    public virtual Member_345? Team2_Player2 { get; set; }
    
    [ForeignKey("CourtId")]
    public virtual Court_345? Court { get; set; }
}
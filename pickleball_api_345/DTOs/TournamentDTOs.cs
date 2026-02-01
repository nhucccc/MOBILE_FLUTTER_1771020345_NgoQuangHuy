using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

public class CreateTournamentDto
{
    [Required(ErrorMessage = "Tên giải đấu là bắt buộc")]
    [StringLength(200, ErrorMessage = "Tên giải đấu không được vượt quá 200 ký tự")]
    public string Name { get; set; } = string.Empty;

    [StringLength(1000, ErrorMessage = "Mô tả không được vượt quá 1000 ký tự")]
    public string? Description { get; set; }

    [Required(ErrorMessage = "Ngày bắt đầu là bắt buộc")]
    public DateTime StartDate { get; set; }

    [Required(ErrorMessage = "Ngày kết thúc là bắt buộc")]
    public DateTime EndDate { get; set; }

    [Required(ErrorMessage = "Định dạng giải đấu là bắt buộc")]
    public string Format { get; set; } = string.Empty; // Knockout, RoundRobin, Hybrid

    [Range(0, double.MaxValue, ErrorMessage = "Phí tham gia phải >= 0")]
    public decimal EntryFee { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "Giải thưởng phải >= 0")]
    public decimal PrizePool { get; set; }

    [Range(2, 128, ErrorMessage = "Số lượng tham gia phải từ 2 đến 128")]
    public int MaxParticipants { get; set; }

    public DateTime? RegistrationDeadline { get; set; }
}

public class UpdateTournamentDto
{
    [StringLength(200, ErrorMessage = "Tên giải đấu không được vượt quá 200 ký tự")]
    public string? Name { get; set; }

    [StringLength(1000, ErrorMessage = "Mô tả không được vượt quá 1000 ký tự")]
    public string? Description { get; set; }

    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? Format { get; set; }
    
    [Range(0, double.MaxValue, ErrorMessage = "Phí tham gia phải >= 0")]
    public decimal? EntryFee { get; set; }

    [Range(0, double.MaxValue, ErrorMessage = "Giải thưởng phải >= 0")]
    public decimal? PrizePool { get; set; }

    [Range(2, 128, ErrorMessage = "Số lượng tham gia phải từ 2 đến 128")]
    public int? MaxParticipants { get; set; }

    public DateTime? RegistrationDeadline { get; set; }
    public string? Status { get; set; } // Open, Registering, InProgress, Completed, Cancelled
}

public class TournamentDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Format { get; set; } = string.Empty;
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
    public int MaxParticipants { get; set; }
    public int ParticipantCount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? RegistrationDeadline { get; set; }
    public DateTime CreatedDate { get; set; }
    public bool IsActive { get; set; }
}

public class TournamentDetailDto : TournamentDto
{
    public List<TournamentParticipantDto> Participants { get; set; } = new();
    public List<MatchDto> Matches { get; set; } = new();
    public List<TournamentRoundDto> Rounds { get; set; } = new();
}

public class TournamentParticipantDto
{
    public int Id { get; set; }
    public int TournamentId { get; set; }
    public int MemberId { get; set; }
    public string MemberName { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty; // Pending, Paid, Refunded
    public DateTime JoinedDate { get; set; }
    public double? DuprRating { get; set; }
    public int? SeedNumber { get; set; }
}

public class MatchDto
{
    public int Id { get; set; }
    public int TournamentId { get; set; }
    public string RoundName { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public DateTime StartTime { get; set; }
    public int? CourtId { get; set; }
    public string? CourtName { get; set; }
    
    // Team 1
    public string Team1Player1Name { get; set; } = string.Empty;
    public string? Team1Player2Name { get; set; }
    public int Team1Score { get; set; }
    
    // Team 2
    public string Team2Player1Name { get; set; } = string.Empty;
    public string? Team2Player2Name { get; set; }
    public int Team2Score { get; set; }
    
    public string Status { get; set; } = string.Empty; // Scheduled, InProgress, Completed, Cancelled
    public string? Notes { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class TournamentRoundDto
{
    public int Id { get; set; }
    public int TournamentId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int RoundNumber { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public List<MatchDto> Matches { get; set; } = new();
}

public class JoinTournamentDto
{
    public int TournamentId { get; set; }
    public double? DuprRating { get; set; }
    public string? Notes { get; set; }
}

public class UpdateMatchScoreDto
{
    [Range(0, int.MaxValue, ErrorMessage = "Điểm số phải >= 0")]
    public int Team1Score { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "Điểm số phải >= 0")]
    public int Team2Score { get; set; }

    public string? Notes { get; set; }
    public bool IsCompleted { get; set; } = false;
}

public class TournamentStatsDto
{
    public int TotalTournaments { get; set; }
    public int ActiveTournaments { get; set; }
    public int CompletedTournaments { get; set; }
    public int TotalParticipants { get; set; }
    public decimal TotalPrizePool { get; set; }
    public decimal TotalEntryFees { get; set; }
}

public class TournamentBracketDto
{
    public int TournamentId { get; set; }
    public string TournamentName { get; set; } = string.Empty;
    public string Format { get; set; } = string.Empty;
    public List<TournamentRoundDto> Rounds { get; set; } = new();
    public List<TournamentParticipantDto> Participants { get; set; } = new();
}

public class CancelTournamentDto
{
    [Required(ErrorMessage = "Lý do hủy là bắt buộc")]
    [StringLength(500, ErrorMessage = "Lý do hủy không được vượt quá 500 ký tự")]
    public string Reason { get; set; } = string.Empty;
}

public class UpdateMatchResultDto
{
    [Required(ErrorMessage = "Trạng thái trận đấu là bắt buộc")]
    public string Status { get; set; } = string.Empty; // Scheduled, InProgress, Finished

    [Range(0, int.MaxValue, ErrorMessage = "Điểm số đội 1 phải >= 0")]
    public int? Score1 { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "Điểm số đội 2 phải >= 0")]
    public int? Score2 { get; set; }

    public string? WinningSide { get; set; } // Team1, Team2, Draw

    [StringLength(1000, ErrorMessage = "Ghi chú không được vượt quá 1000 ký tự")]
    public string? Details { get; set; }

    public DateTime? Date { get; set; }
    public DateTime? StartTime { get; set; }
    public int? CourtId { get; set; }
}
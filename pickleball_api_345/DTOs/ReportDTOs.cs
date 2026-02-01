namespace pickleball_api_345.DTOs;

public class RevenueReportDto
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal BookingRevenue { get; set; }
    public decimal TournamentRevenue { get; set; }
    public int TotalBookings { get; set; }
    public int TotalTournamentRegistrations { get; set; }
    public List<DailyRevenueDto> DailyRevenues { get; set; } = new();
    public List<CourtRevenueDto> CourtRevenues { get; set; } = new();
}

public class DailyRevenueDto
{
    public DateTime Date { get; set; }
    public decimal Revenue { get; set; }
    public int BookingCount { get; set; }
}

public class CourtRevenueDto
{
    public string CourtName { get; set; } = string.Empty;
    public decimal Revenue { get; set; }
    public int BookingCount { get; set; }
    public decimal UtilizationRate { get; set; }
}

public class MemberReportDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime JoinDate { get; set; }
    public string Tier { get; set; } = string.Empty;
    public decimal DuprRating { get; set; }
    public decimal WalletBalance { get; set; }
    public decimal TotalSpent { get; set; }
    public int TotalBookings { get; set; }
    public int TotalTournaments { get; set; }
    public DateTime LastActivity { get; set; }
    public bool IsActive { get; set; }
}

public class TournamentReportDto
{
    public int TournamentId { get; set; }
    public string TournamentName { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int TotalParticipants { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal PrizePool { get; set; }
    public List<TournamentReportParticipantDto> Participants { get; set; } = new();
}

public class TournamentReportParticipantDto
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public decimal DuprRating { get; set; }
    public DateTime RegistrationDate { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
}

public class ExportRequestDto
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string Format { get; set; } = "excel"; // excel, pdf
    public string ReportType { get; set; } = "revenue"; // revenue, members, tournament
    public int? TournamentId { get; set; }
}
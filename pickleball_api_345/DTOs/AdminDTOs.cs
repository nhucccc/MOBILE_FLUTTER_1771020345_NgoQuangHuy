using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

public class UpdateMemberStatusDto
{
    public bool IsActive { get; set; }
}

public class UpdateMemberTierDto
{
    [Required]
    public string Tier { get; set; } = string.Empty;
}

public class ApproveDepositDto
{
    public string? AdminNotes { get; set; }
}

public class RejectDepositDto
{
    [Required]
    public string Reason { get; set; } = string.Empty;
}

public class CreateCourtDto
{
    [Required]
    public string Name { get; set; } = string.Empty;
    
    public string? Description { get; set; }
    
    [Required]
    [Range(0.01, double.MaxValue, ErrorMessage = "Giá phải lớn hơn 0")]
    public decimal PricePerHour { get; set; }
}

public class UpdateCourtDto
{
    [Required]
    public string Name { get; set; } = string.Empty;
    
    public string? Description { get; set; }
    
    [Required]
    [Range(0.01, double.MaxValue, ErrorMessage = "Giá phải lớn hơn 0")]
    public decimal PricePerHour { get; set; }
    
    public bool IsActive { get; set; }
}

public class SystemSettingsDto
{
    public int BookingAdvanceDays { get; set; }
    public int CancellationHours { get; set; }
    public bool AutoCleanupEnabled { get; set; }
    public int ReminderHours { get; set; }
    public int MaxRecurringBookings { get; set; }
}

public class AdminDashboardStatsDto
{
    public int TotalMembers { get; set; }
    public int TotalCourts { get; set; }
    public int PendingDeposits { get; set; }
    public int TodayBookings { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class MemberManagementDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime JoinDate { get; set; }
    public bool IsActive { get; set; }
    public decimal WalletBalance { get; set; }
    public string Tier { get; set; } = string.Empty;
    public decimal TotalSpent { get; set; }
    public double RankLevel { get; set; }
    public string Role { get; set; } = string.Empty;
}

public class PendingDepositDto
{
    public int Id { get; set; }
    public string MemberName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public string? ProofImageUrl { get; set; }
    public int MemberId { get; set; }
}

public class CourtManagementDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public string? Description { get; set; }
    public decimal PricePerHour { get; set; }
    public int BookingCount { get; set; }
}
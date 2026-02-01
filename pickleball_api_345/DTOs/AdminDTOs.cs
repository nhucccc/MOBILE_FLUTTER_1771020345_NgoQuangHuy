using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

// Member Management DTOs
public class CreateMemberDto
{
    [Required(ErrorMessage = "Họ tên là bắt buộc")]
    [StringLength(100, ErrorMessage = "Họ tên không được vượt quá 100 ký tự")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
    public string? PhoneNumber { get; set; }

    [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    public string Password { get; set; } = string.Empty;

    public string? Role { get; set; } = "Member";
}

public class UpdateMemberDto
{
    [Required(ErrorMessage = "Họ tên là bắt buộc")]
    [StringLength(100, ErrorMessage = "Họ tên không được vượt quá 100 ký tự")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
    public string? PhoneNumber { get; set; }

    public bool IsActive { get; set; } = true;

    public string Tier { get; set; } = "Standard";

    [Range(1.0, 5.0, ErrorMessage = "DUPR Rating phải từ 1.0 đến 5.0")]
    public double DuprRating { get; set; } = 2.0;

    public string? Role { get; set; }
}

public class UpdateMemberStatusDto
{
    public bool IsActive { get; set; }
}

public class UpdateMemberTierDto
{
    [Required(ErrorMessage = "Tier là bắt buộc")]
    public string Tier { get; set; } = string.Empty;
}

public class UpdateMemberWalletDto
{
    [Required(ErrorMessage = "Số tiền là bắt buộc")]
    [Range(0, double.MaxValue, ErrorMessage = "Số tiền phải lớn hơn 0")]
    public decimal Amount { get; set; }

    [Required(ErrorMessage = "Loại giao dịch là bắt buộc")]
    public string Type { get; set; } = string.Empty; // "Add" or "Subtract"

    [StringLength(500, ErrorMessage = "Ghi chú không được vượt quá 500 ký tự")]
    public string? Notes { get; set; }
}

// Court Management DTOs
public class CreateCourtDto
{
    [Required(ErrorMessage = "Tên sân là bắt buộc")]
    [StringLength(100, ErrorMessage = "Tên sân không được vượt quá 100 ký tự")]
    public string Name { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Mô tả không được vượt quá 500 ký tự")]
    public string? Description { get; set; }

    [Required(ErrorMessage = "Giá thuê sân là bắt buộc")]
    [Range(0, double.MaxValue, ErrorMessage = "Giá thuê sân phải lớn hơn 0")]
    public decimal PricePerHour { get; set; }
}

public class UpdateCourtDto
{
    [Required(ErrorMessage = "Tên sân là bắt buộc")]
    [StringLength(100, ErrorMessage = "Tên sân không được vượt quá 100 ký tự")]
    public string Name { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Mô tả không được vượt quá 500 ký tự")]
    public string? Description { get; set; }

    [Required(ErrorMessage = "Giá thuê sân là bắt buộc")]
    [Range(0, double.MaxValue, ErrorMessage = "Giá thuê sân phải lớn hơn 0")]
    public decimal PricePerHour { get; set; }

    public bool IsActive { get; set; } = true;
}

// Deposit Management DTOs
public class ApproveDepositDto
{
    [StringLength(500, ErrorMessage = "Ghi chú không được vượt quá 500 ký tự")]
    public string? AdminNotes { get; set; }
}

public class RejectDepositDto
{
    [Required(ErrorMessage = "Lý do từ chối là bắt buộc")]
    [StringLength(500, ErrorMessage = "Lý do từ chối không được vượt quá 500 ký tự")]
    public string Reason { get; set; } = string.Empty;
}

// System Settings DTOs
public class SystemSettingsDto
{
    [Range(1, 365, ErrorMessage = "Số ngày đặt trước phải từ 1 đến 365")]
    public int BookingAdvanceDays { get; set; } = 30;

    [Range(1, 72, ErrorMessage = "Số giờ hủy trước phải từ 1 đến 72")]
    public int CancellationHours { get; set; } = 24;

    public bool AutoCleanupEnabled { get; set; } = true;

    [Range(1, 24, ErrorMessage = "Số giờ nhắc nhở phải từ 1 đến 24")]
    public int ReminderHours { get; set; } = 2;

    [Range(1, 50, ErrorMessage = "Số lượng đặt sân định kỳ tối đa phải từ 1 đến 50")]
    public int MaxRecurringBookings { get; set; } = 10;
}
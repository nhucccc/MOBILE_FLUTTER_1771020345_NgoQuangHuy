using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

public class RegisterRequestDto
{
    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
    [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Họ và tên là bắt buộc")]
    public string FullName { get; set; } = string.Empty;

    [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
    public string? PhoneNumber { get; set; }
}

public class LoginRequestDto
{
    [Required(ErrorMessage = "Email là bắt buộc")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
    public string Password { get; set; } = string.Empty;
}

public class LoginResponseDto
{
    public string Token { get; set; } = string.Empty;
    public DateTime Expires { get; set; }
    public UserInfoDto User { get; set; } = new();
}

public class UserInfoDto
{
    public string Id { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string Role { get; set; } = "Member";
    public string? AvatarUrl { get; set; }
    public MemberInfoDto? Member { get; set; }
}

public class MemberInfoDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public DateTime JoinDate { get; set; }
    public double RankLevel { get; set; }
    public bool IsActive { get; set; }
    public decimal WalletBalance { get; set; }
    public string Tier { get; set; } = string.Empty;
    public decimal TotalSpent { get; set; }
    public string? AvatarUrl { get; set; }
}
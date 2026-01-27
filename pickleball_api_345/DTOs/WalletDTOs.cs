using System.ComponentModel.DataAnnotations;

namespace pickleball_api_345.DTOs;

public class DepositRequestDto
{
    [Required(ErrorMessage = "Số tiền là bắt buộc")]
    [Range(10000, 50000000, ErrorMessage = "Số tiền phải từ 10,000 đến 50,000,000 VNĐ")]
    public decimal Amount { get; set; }

    [Required(ErrorMessage = "Mô tả là bắt buộc")]
    [MinLength(5, ErrorMessage = "Mô tả phải có ít nhất 5 ký tự")]
    public string Description { get; set; } = string.Empty;

    public string? ProofImageUrl { get; set; }
}

public class ApproveTransactionDto
{
    [Required]
    public bool IsApproved { get; set; }

    public string? AdminNote { get; set; }
}

public class WalletBalanceDto
{
    public decimal Balance { get; set; }
    public string FormattedBalance { get; set; } = string.Empty;
}

public class WalletTransactionDto
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public decimal Amount { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? RelatedId { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public string? ProofImageUrl { get; set; }
    public string? AdminNote { get; set; }
    public string? MemberName { get; set; }
}
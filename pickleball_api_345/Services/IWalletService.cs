using pickleball_api_345.DTOs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public interface IWalletService
{
    Task<decimal> GetWalletBalanceAsync(int memberId);
    Task<List<WalletTransactionDto>> GetTransactionHistoryAsync(int memberId, int page = 1, int pageSize = 20);
    Task<WalletTransaction_345> CreateDepositRequestAsync(int memberId, DepositRequestDto request);
    Task<bool> ApproveTransactionAsync(int transactionId, string adminUserId, bool isApproved, string? adminNote = null);
    Task<bool> ProcessPaymentAsync(int memberId, decimal amount, TransactionType type, string? description = null, string? relatedId = null);
    Task<bool> RefundAsync(int memberId, decimal amount, string? description = null, string? relatedId = null);
    Task UpdateMemberTierAsync(int memberId);
}
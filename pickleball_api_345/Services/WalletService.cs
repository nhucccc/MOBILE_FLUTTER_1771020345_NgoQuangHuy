using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;

namespace pickleball_api_345.Services;

public class WalletService : IWalletService
{
    private readonly ApplicationDbContext _context;
    private readonly INotificationService _notificationService;

    public WalletService(ApplicationDbContext context, INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<decimal> GetWalletBalanceAsync(int memberId)
    {
        var member = await _context.Members_345.FindAsync(memberId);
        if (member == null) throw new ArgumentException("Member not found");

        return member.WalletBalance;
    }

    public async Task<List<WalletTransactionDto>> GetTransactionHistoryAsync(int memberId, int page = 1, int pageSize = 20)
    {
        return await _context.WalletTransactions_345
            .Where(wt => wt.MemberId == memberId)
            .OrderByDescending(wt => wt.CreatedDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(wt => new WalletTransactionDto
            {
                Id = wt.Id,
                MemberId = wt.MemberId,
                Amount = wt.Amount,
                Type = wt.Type.ToString(),
                Status = wt.Status.ToString(),
                RelatedId = wt.RelatedId,
                Description = wt.Description,
                CreatedDate = wt.CreatedDate,
                ProofImageUrl = wt.ProofImageUrl,
                AdminNote = wt.ProcessedBy ?? string.Empty // Use ProcessedBy as AdminNote for now
            })
            .ToListAsync();
    }

    public async Task<WalletTransaction_345> CreateDepositRequestAsync(int memberId, DepositRequestDto request)
    {
        var transaction = new WalletTransaction_345
        {
            MemberId = memberId,
            Amount = request.Amount,
            Type = TransactionType.Deposit,
            Status = TransactionStatus.Pending,
            Description = request.Description ?? $"Nạp tiền vào ví: {request.Amount:N0} VND",
            ProofImageUrl = request.ProofImageUrl,
            CreatedDate = DateTime.UtcNow
        };

        _context.WalletTransactions_345.Add(transaction);
        await _context.SaveChangesAsync();

        return transaction;
    }

    public async Task<bool> ApproveTransactionAsync(int transactionId, string adminUserId, bool isApproved, string? adminNote = null)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var walletTransaction = await _context.WalletTransactions_345
                .Include(wt => wt.Member)
                .FirstOrDefaultAsync(wt => wt.Id == transactionId);

            if (walletTransaction == null || walletTransaction.Status != TransactionStatus.Pending)
                return false;

            walletTransaction.ProcessedDate = DateTime.UtcNow;
            walletTransaction.ProcessedBy = adminUserId;
            walletTransaction.ProcessedBy = adminNote; // Store admin note in ProcessedBy field

            if (isApproved)
            {
                walletTransaction.Status = TransactionStatus.Completed;
                
                // Add money to wallet
                walletTransaction.Member.WalletBalance += walletTransaction.Amount;
                walletTransaction.Member.TotalSpent += walletTransaction.Amount;
                
                // Update member tier
                await UpdateMemberTierAsync(walletTransaction.MemberId);

                // Send notification via SignalR
                await _notificationService.NotifyWalletDepositAsync(
                    walletTransaction.Member.UserId, 
                    walletTransaction.Amount
                );
            }
            else
            {
                walletTransaction.Status = TransactionStatus.Rejected;
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            return true;
        }
        catch
        {
            await transaction.RollbackAsync();
            return false;
        }
    }

    public async Task<bool> ProcessPaymentAsync(int memberId, decimal amount, TransactionType type, string? description = null, string? relatedId = null)
    {
        // Remove nested transaction - use the existing transaction from BookingService
        try
        {
            var member = await _context.Members_345.FindAsync(memberId);
            Console.WriteLine($"ProcessPayment - Member ID: {memberId}");
            Console.WriteLine($"ProcessPayment - Member found: {member != null}");
            Console.WriteLine($"ProcessPayment - Current balance: {member?.WalletBalance}");
            Console.WriteLine($"ProcessPayment - Required amount: {amount}");
            Console.WriteLine($"ProcessPayment - Has enough balance: {member?.WalletBalance >= amount}");
            
            if (member == null || member.WalletBalance < amount)
            {
                Console.WriteLine($"ProcessPayment - FAILED: Member null or insufficient balance");
                return false;
            }

            // Deduct from wallet
            member.WalletBalance -= amount;
            member.TotalSpent += amount;

            Console.WriteLine($"ProcessPayment - New balance: {member.WalletBalance}");

            // Create transaction record
            var walletTransaction = new WalletTransaction_345
            {
                MemberId = memberId,
                Amount = -amount, // Negative for payment
                Type = type,
                Status = TransactionStatus.Completed,
                Description = description ?? $"Thanh toán: {amount:N0} VND",
                RelatedId = relatedId,
                CreatedDate = DateTime.UtcNow
            };

            _context.WalletTransactions_345.Add(walletTransaction);
            // Don't call SaveChanges here - let the parent transaction handle it
            
            Console.WriteLine($"ProcessPayment - SUCCESS");
            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ProcessPayment - EXCEPTION: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> RefundAsync(int memberId, decimal amount, string? description = null, string? relatedId = null)
    {
        var member = await _context.Members_345.FindAsync(memberId);
        if (member == null) return false;

        // Add to wallet
        member.WalletBalance += amount;

        // Create transaction record
        var walletTransaction = new WalletTransaction_345
        {
            MemberId = memberId,
            Amount = amount,
            Type = TransactionType.Refund,
            Status = TransactionStatus.Completed,
            Description = description ?? $"Hoàn tiền: {amount:N0} VND",
            RelatedId = relatedId,
            CreatedDate = DateTime.UtcNow
        };

        _context.WalletTransactions_345.Add(walletTransaction);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task UpdateMemberTierAsync(int memberId)
    {
        var member = await _context.Members_345.FindAsync(memberId);
        if (member == null) return;

        // Update tier based on total spent
        if (member.TotalSpent >= 10000000) // 10M VND
            member.Tier = MemberTier.Diamond;
        else if (member.TotalSpent >= 5000000) // 5M VND
            member.Tier = MemberTier.Gold;
        else if (member.TotalSpent >= 2000000) // 2M VND
            member.Tier = MemberTier.Silver;
        else
            member.Tier = MemberTier.Standard;

        await _context.SaveChangesAsync();
    }
}
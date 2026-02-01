using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Services;
using System.Security.Claims;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly IWalletService _walletService;
    private readonly ApplicationDbContext _context;

    public WalletController(IWalletService walletService, ApplicationDbContext context)
    {
        _walletService = walletService;
        _context = context;
    }

    [HttpGet("balance")]
    public async Task<IActionResult> GetWalletBalance()
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest(new { success = false, message = "Member not found" });

        var balance = await _walletService.GetWalletBalanceAsync(memberId.Value);
        return Ok(new { 
            success = true, 
            data = new { balance = balance }
        });
    }

    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactionHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        var transactions = await _walletService.GetTransactionHistoryAsync(memberId.Value, page, pageSize);
        return Ok(transactions);
    }

    [HttpPost("deposit")]
    public async Task<IActionResult> CreateDepositRequest([FromBody] DepositRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var memberId = await GetCurrentMemberIdAsync();
        if (memberId == null)
            return BadRequest("Member not found");

        try
        {
            var transaction = await _walletService.CreateDepositRequestAsync(memberId.Value, request);
            return Ok(new { 
                message = "Yêu cầu nạp tiền đã được tạo, vui lòng chờ admin duyệt",
                transactionId = transaction.Id 
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("admin/approve/{transactionId}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ApproveTransaction(int transactionId, [FromBody] ApproveTransactionDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminUserId))
            return Unauthorized();

        var success = await _walletService.ApproveTransactionAsync(
            transactionId, 
            adminUserId, 
            request.IsApproved, 
            request.AdminNote
        );

        if (!success)
            return BadRequest("Không thể xử lý giao dịch");

        var status = request.IsApproved ? "đã được duyệt" : "đã bị từ chối";
        return Ok(new { message = $"Giao dịch {status}" });
    }

    [HttpGet("admin/pending-transactions")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPendingTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var transactions = await _context.WalletTransactions_345
            .Include(wt => wt.Member)
            .Where(wt => wt.Status == Models.TransactionStatus.Pending)
            .OrderByDescending(wt => wt.CreatedDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(wt => new
            {
                wt.Id,
                wt.Amount,
                Type = wt.Type.ToString(),
                Status = wt.Status.ToString(),
                wt.Description,
                wt.CreatedDate,
                wt.ProofImageUrl,
                MemberName = wt.Member.FullName,
                MemberId = wt.MemberId
            })
            .ToListAsync();

        return Ok(transactions);
    }

    private async Task<int?> GetCurrentMemberIdAsync()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return null;

        var member = await _context.Members_345.FirstOrDefaultAsync(m => m.UserId == userId);
        return member?.Id;
    }
}
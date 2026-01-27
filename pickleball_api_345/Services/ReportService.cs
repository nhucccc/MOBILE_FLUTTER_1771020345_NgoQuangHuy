using Microsoft.EntityFrameworkCore;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using pickleball_api_345.Data;
using pickleball_api_345.DTOs;
using pickleball_api_345.Models;
using System.Drawing;

namespace pickleball_api_345.Services;

public class ReportService : IReportService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ReportService> _logger;

    public ReportService(ApplicationDbContext context, ILogger<ReportService> logger)
    {
        _context = context;
        _logger = logger;
        
        // Set EPPlus license context
        ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
    }

    public async Task<RevenueReportDto> GetRevenueReportDataAsync(DateTime fromDate, DateTime toDate)
    {
        try
        {
            var bookings = await _context.Bookings_345
                .Include(b => b.Court)
                .Include(b => b.Transaction)
                .Where(b => b.CreatedDate >= fromDate && 
                           b.CreatedDate <= toDate && 
                           b.Status == BookingStatus.Confirmed)
                .ToListAsync();

            var tournaments = await _context.TournamentParticipants_345
                .Include(tp => tp.Tournament)
                .Where(tp => tp.JoinedDate >= fromDate && 
                            tp.JoinedDate <= toDate &&
                            tp.PaymentStatus == PaymentStatus.Paid)
                .ToListAsync();

            var bookingRevenue = bookings.Sum(b => b.TotalPrice);
            var tournamentRevenue = tournaments.Sum(tp => tp.Tournament.EntryFee);

            var dailyRevenues = bookings
                .GroupBy(b => b.CreatedDate.Date)
                .Select(g => new DailyRevenueDto
                {
                    Date = g.Key,
                    Revenue = g.Sum(b => b.TotalPrice),
                    BookingCount = g.Count()
                })
                .OrderBy(d => d.Date)
                .ToList();

            var courtRevenues = bookings
                .GroupBy(b => b.Court)
                .Select(g => new CourtRevenueDto
                {
                    CourtName = g.Key.Name,
                    Revenue = g.Sum(b => b.TotalPrice),
                    BookingCount = g.Count(),
                    UtilizationRate = CalculateUtilizationRate(g.Key.Id, fromDate, toDate)
                })
                .ToList();

            return new RevenueReportDto
            {
                FromDate = fromDate,
                ToDate = toDate,
                TotalRevenue = bookingRevenue + tournamentRevenue,
                BookingRevenue = bookingRevenue,
                TournamentRevenue = tournamentRevenue,
                TotalBookings = bookings.Count,
                TotalTournamentRegistrations = tournaments.Count,
                DailyRevenues = dailyRevenues,
                CourtRevenues = courtRevenues
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating revenue report data");
            throw;
        }
    }

    public async Task<List<MemberReportDto>> GetMemberReportDataAsync()
    {
        try
        {
            var members = await _context.Members_345
                .Include(m => m.User)
                .Include(m => m.Bookings)
                .Include(m => m.TournamentParticipants)
                .Select(m => new MemberReportDto
                {
                    Id = m.Id,
                    FullName = m.FullName,
                    Email = m.User.Email ?? "",
                    JoinDate = m.JoinDate,
                    Tier = m.Tier.ToString(),
                    DuprRating = m.DuprRating,
                    WalletBalance = m.WalletBalance,
                    TotalSpent = m.TotalSpent,
                    TotalBookings = m.Bookings.Count(b => b.Status == BookingStatus.Confirmed),
                    TotalTournaments = m.TournamentParticipants.Count,
                    LastActivity = m.Bookings.Any() ? m.Bookings.Max(b => b.CreatedDate) : m.JoinDate,
                    IsActive = m.IsActive
                })
                .OrderBy(m => m.FullName)
                .ToListAsync();

            return members;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating member report data");
            throw;
        }
    }

    public async Task<byte[]> ExportRevenueReportAsync(DateTime fromDate, DateTime toDate, string format = "excel")
    {
        var reportData = await GetRevenueReportDataAsync(fromDate, toDate);

        if (format.ToLower() == "excel")
        {
            return await GenerateRevenueExcelAsync(reportData);
        }
        else if (format.ToLower() == "pdf")
        {
            return await GenerateRevenuePdfAsync(reportData);
        }

        throw new ArgumentException("Unsupported format");
    }

    public async Task<byte[]> ExportMemberListAsync(string format = "excel")
    {
        var memberData = await GetMemberReportDataAsync();

        if (format.ToLower() == "excel")
        {
            return await GenerateMemberExcelAsync(memberData);
        }
        else if (format.ToLower() == "pdf")
        {
            return await GenerateMemberPdfAsync(memberData);
        }

        throw new ArgumentException("Unsupported format");
    }

    public async Task<byte[]> ExportTournamentReportAsync(int tournamentId, string format = "excel")
    {
        var tournament = await _context.Tournaments_345
            .Include(t => t.Participants)
                .ThenInclude(p => p.Member)
                    .ThenInclude(m => m.User)
            .FirstOrDefaultAsync(t => t.Id == tournamentId);

        if (tournament == null)
            throw new ArgumentException("Tournament not found");

        var reportData = new TournamentReportDto
        {
            TournamentId = tournament.Id,
            TournamentName = tournament.Name,
            StartDate = tournament.StartDate,
            EndDate = tournament.EndDate,
            TotalParticipants = tournament.Participants.Count,
            TotalRevenue = tournament.Participants.Count(p => p.PaymentStatus == PaymentStatus.Paid) * tournament.EntryFee,
            PrizePool = tournament.PrizePool,
            Participants = tournament.Participants.Select(p => new TournamentParticipantDto
            {
                FullName = p.Member.FullName,
                Email = p.Member.User.Email ?? "",
                DuprRating = p.Member.DuprRating,
                RegistrationDate = p.JoinedDate,
                PaymentStatus = p.PaymentStatus.ToString()
            }).ToList()
        };

        if (format.ToLower() == "excel")
        {
            return await GenerateTournamentExcelAsync(reportData);
        }

        throw new ArgumentException("Unsupported format");
    }

    private async Task<byte[]> GenerateRevenueExcelAsync(RevenueReportDto data)
    {
        using var package = new ExcelPackage();
        
        // Summary sheet
        var summarySheet = package.Workbook.Worksheets.Add("Tổng quan");
        summarySheet.Cells["A1"].Value = "BÁO CÁO DOANH THU PICKLEBALL CLUB 345";
        summarySheet.Cells["A1:F1"].Merge = true;
        summarySheet.Cells["A1"].Style.Font.Size = 16;
        summarySheet.Cells["A1"].Style.Font.Bold = true;
        summarySheet.Cells["A1"].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;

        summarySheet.Cells["A3"].Value = "Từ ngày:";
        summarySheet.Cells["B3"].Value = data.FromDate.ToString("dd/MM/yyyy");
        summarySheet.Cells["A4"].Value = "Đến ngày:";
        summarySheet.Cells["B4"].Value = data.ToDate.ToString("dd/MM/yyyy");

        summarySheet.Cells["A6"].Value = "Tổng doanh thu:";
        summarySheet.Cells["B6"].Value = data.TotalRevenue;
        summarySheet.Cells["B6"].Style.Numberformat.Format = "#,##0 ₫";

        summarySheet.Cells["A7"].Value = "Doanh thu đặt sân:";
        summarySheet.Cells["B7"].Value = data.BookingRevenue;
        summarySheet.Cells["B7"].Style.Numberformat.Format = "#,##0 ₫";

        summarySheet.Cells["A8"].Value = "Doanh thu giải đấu:";
        summarySheet.Cells["B8"].Value = data.TournamentRevenue;
        summarySheet.Cells["B8"].Style.Numberformat.Format = "#,##0 ₫";

        // Daily revenue sheet
        var dailySheet = package.Workbook.Worksheets.Add("Doanh thu theo ngày");
        dailySheet.Cells["A1"].Value = "Ngày";
        dailySheet.Cells["B1"].Value = "Doanh thu";
        dailySheet.Cells["C1"].Value = "Số lượng booking";

        for (int i = 0; i < data.DailyRevenues.Count; i++)
        {
            var row = i + 2;
            dailySheet.Cells[row, 1].Value = data.DailyRevenues[i].Date.ToString("dd/MM/yyyy");
            dailySheet.Cells[row, 2].Value = data.DailyRevenues[i].Revenue;
            dailySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0 ₫";
            dailySheet.Cells[row, 3].Value = data.DailyRevenues[i].BookingCount;
        }

        // Court revenue sheet
        var courtSheet = package.Workbook.Worksheets.Add("Doanh thu theo sân");
        courtSheet.Cells["A1"].Value = "Tên sân";
        courtSheet.Cells["B1"].Value = "Doanh thu";
        courtSheet.Cells["C1"].Value = "Số booking";
        courtSheet.Cells["D1"].Value = "Tỷ lệ sử dụng (%)";

        for (int i = 0; i < data.CourtRevenues.Count; i++)
        {
            var row = i + 2;
            courtSheet.Cells[row, 1].Value = data.CourtRevenues[i].CourtName;
            courtSheet.Cells[row, 2].Value = data.CourtRevenues[i].Revenue;
            courtSheet.Cells[row, 2].Style.Numberformat.Format = "#,##0 ₫";
            courtSheet.Cells[row, 3].Value = data.CourtRevenues[i].BookingCount;
            courtSheet.Cells[row, 4].Value = data.CourtRevenues[i].UtilizationRate;
            courtSheet.Cells[row, 4].Style.Numberformat.Format = "0.00%";
        }

        // Auto-fit columns
        summarySheet.Cells.AutoFitColumns();
        dailySheet.Cells.AutoFitColumns();
        courtSheet.Cells.AutoFitColumns();

        return await Task.FromResult(package.GetAsByteArray());
    }

    private async Task<byte[]> GenerateMemberExcelAsync(List<MemberReportDto> members)
    {
        using var package = new ExcelPackage();
        var worksheet = package.Workbook.Worksheets.Add("Danh sách thành viên");

        // Headers
        var headers = new[]
        {
            "ID", "Họ tên", "Email", "Ngày tham gia", "Hạng", "DUPR Rating",
            "Số dư ví", "Tổng chi tiêu", "Số booking", "Số giải đấu", "Hoạt động cuối", "Trạng thái"
        };

        for (int i = 0; i < headers.Length; i++)
        {
            worksheet.Cells[1, i + 1].Value = headers[i];
            worksheet.Cells[1, i + 1].Style.Font.Bold = true;
            // worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillPatternType.Solid;
            worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(Color.LightGray);
        }

        // Data
        for (int i = 0; i < members.Count; i++)
        {
            var row = i + 2;
            var member = members[i];

            worksheet.Cells[row, 1].Value = member.Id;
            worksheet.Cells[row, 2].Value = member.FullName;
            worksheet.Cells[row, 3].Value = member.Email;
            worksheet.Cells[row, 4].Value = member.JoinDate.ToString("dd/MM/yyyy");
            worksheet.Cells[row, 5].Value = member.Tier;
            worksheet.Cells[row, 6].Value = member.DuprRating;
            worksheet.Cells[row, 7].Value = member.WalletBalance;
            worksheet.Cells[row, 7].Style.Numberformat.Format = "#,##0 ₫";
            worksheet.Cells[row, 8].Value = member.TotalSpent;
            worksheet.Cells[row, 8].Style.Numberformat.Format = "#,##0 ₫";
            worksheet.Cells[row, 9].Value = member.TotalBookings;
            worksheet.Cells[row, 10].Value = member.TotalTournaments;
            worksheet.Cells[row, 11].Value = member.LastActivity.ToString("dd/MM/yyyy");
            worksheet.Cells[row, 12].Value = member.IsActive ? "Hoạt động" : "Không hoạt động";
        }

        worksheet.Cells.AutoFitColumns();
        return await Task.FromResult(package.GetAsByteArray());
    }

    private async Task<byte[]> GenerateTournamentExcelAsync(TournamentReportDto tournament)
    {
        using var package = new ExcelPackage();
        var worksheet = package.Workbook.Worksheets.Add($"Giải {tournament.TournamentName}");

        // Tournament info
        worksheet.Cells["A1"].Value = $"BÁO CÁO GIẢI ĐẤU: {tournament.TournamentName}";
        worksheet.Cells["A1:F1"].Merge = true;
        worksheet.Cells["A1"].Style.Font.Size = 14;
        worksheet.Cells["A1"].Style.Font.Bold = true;

        worksheet.Cells["A3"].Value = "Ngày bắt đầu:";
        worksheet.Cells["B3"].Value = tournament.StartDate.ToString("dd/MM/yyyy");
        worksheet.Cells["A4"].Value = "Ngày kết thúc:";
        worksheet.Cells["B4"].Value = tournament.EndDate.ToString("dd/MM/yyyy");
        worksheet.Cells["A5"].Value = "Tổng số VĐV:";
        worksheet.Cells["B5"].Value = tournament.TotalParticipants;
        worksheet.Cells["A6"].Value = "Tổng doanh thu:";
        worksheet.Cells["B6"].Value = tournament.TotalRevenue;
        worksheet.Cells["B6"].Style.Numberformat.Format = "#,##0 ₫";

        // Participants
        worksheet.Cells["A8"].Value = "DANH SÁCH VẬN ĐỘNG VIÊN";
        worksheet.Cells["A8"].Style.Font.Bold = true;

        var headers = new[] { "Họ tên", "Email", "DUPR Rating", "Ngày đăng ký", "Trạng thái thanh toán" };
        for (int i = 0; i < headers.Length; i++)
        {
            worksheet.Cells[9, i + 1].Value = headers[i];
            worksheet.Cells[9, i + 1].Style.Font.Bold = true;
        }

        for (int i = 0; i < tournament.Participants.Count; i++)
        {
            var row = i + 10;
            var participant = tournament.Participants[i];

            worksheet.Cells[row, 1].Value = participant.FullName;
            worksheet.Cells[row, 2].Value = participant.Email;
            worksheet.Cells[row, 3].Value = participant.DuprRating;
            worksheet.Cells[row, 4].Value = participant.RegistrationDate.ToString("dd/MM/yyyy");
            worksheet.Cells[row, 5].Value = participant.PaymentStatus;
        }

        worksheet.Cells.AutoFitColumns();
        return await Task.FromResult(package.GetAsByteArray());
    }

    private async Task<byte[]> GenerateRevenuePdfAsync(RevenueReportDto data)
    {
        // For demo purposes, return empty byte array
        // In production, you would use a PDF library like iTextSharp
        return await Task.FromResult(new byte[0]);
    }

    private async Task<byte[]> GenerateMemberPdfAsync(List<MemberReportDto> members)
    {
        // For demo purposes, return empty byte array
        return await Task.FromResult(new byte[0]);
    }

    private decimal CalculateUtilizationRate(int courtId, DateTime fromDate, DateTime toDate)
    {
        var totalHours = (toDate - fromDate).TotalHours;
        var bookedHours = _context.Bookings_345
            .Where(b => b.CourtId == courtId && 
                       b.CreatedDate >= fromDate && 
                       b.CreatedDate <= toDate &&
                       b.Status == BookingStatus.Confirmed)
            .Sum(b => (b.EndTime - b.StartTime).TotalHours);

        return totalHours > 0 ? (decimal)(bookedHours / totalHours) : 0;
    }
}
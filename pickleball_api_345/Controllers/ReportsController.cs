using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using pickleball_api_345.DTOs;
using pickleball_api_345.Services;

namespace pickleball_api_345.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin,Treasurer")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportsController> _logger;

    public ReportsController(IReportService reportService, ILogger<ReportsController> logger)
    {
        _reportService = reportService;
        _logger = logger;
    }

    [HttpGet("revenue")]
    public async Task<ActionResult<RevenueReportDto>> GetRevenueReport(
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate)
    {
        try
        {
            var report = await _reportService.GetRevenueReportDataAsync(fromDate, toDate);
            return Ok(report);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating revenue report");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi tạo báo cáo doanh thu" });
        }
    }

    [HttpGet("members")]
    public async Task<ActionResult<List<MemberReportDto>>> GetMemberReport()
    {
        try
        {
            var report = await _reportService.GetMemberReportDataAsync();
            return Ok(report);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating member report");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi tạo báo cáo thành viên" });
        }
    }

    [HttpPost("export")]
    public async Task<IActionResult> ExportReport([FromBody] ExportRequestDto request)
    {
        try
        {
            byte[] fileBytes;
            string fileName;
            string contentType;

            switch (request.ReportType.ToLower())
            {
                case "revenue":
                    fileBytes = await _reportService.ExportRevenueReportAsync(
                        request.FromDate, request.ToDate, request.Format);
                    fileName = $"BaoCaoDoanhThu_{request.FromDate:yyyyMMdd}_{request.ToDate:yyyyMMdd}";
                    break;

                case "members":
                    fileBytes = await _reportService.ExportMemberListAsync(request.Format);
                    fileName = $"DanhSachThanhVien_{DateTime.Now:yyyyMMdd}";
                    break;

                case "tournament":
                    if (!request.TournamentId.HasValue)
                        return BadRequest("Tournament ID is required for tournament report");
                    
                    fileBytes = await _reportService.ExportTournamentReportAsync(
                        request.TournamentId.Value, request.Format);
                    fileName = $"BaoCaoGiaiDau_{request.TournamentId}_{DateTime.Now:yyyyMMdd}";
                    break;

                default:
                    return BadRequest("Invalid report type");
            }

            if (request.Format.ToLower() == "excel")
            {
                contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                fileName += ".xlsx";
            }
            else if (request.Format.ToLower() == "pdf")
            {
                contentType = "application/pdf";
                fileName += ".pdf";
            }
            else
            {
                return BadRequest("Invalid format");
            }

            return File(fileBytes, contentType, fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting report");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi xuất báo cáo" });
        }
    }

    [HttpGet("revenue/export")]
    public async Task<IActionResult> ExportRevenueReport(
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate,
        [FromQuery] string format = "excel")
    {
        try
        {
            var fileBytes = await _reportService.ExportRevenueReportAsync(fromDate, toDate, format);
            var fileName = $"BaoCaoDoanhThu_{fromDate:yyyyMMdd}_{toDate:yyyyMMdd}";
            
            if (format.ToLower() == "excel")
            {
                return File(fileBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
                           fileName + ".xlsx");
            }
            else
            {
                return File(fileBytes, "application/pdf", fileName + ".pdf");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting revenue report");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi xuất báo cáo doanh thu" });
        }
    }

    [HttpGet("members/export")]
    public async Task<IActionResult> ExportMemberList([FromQuery] string format = "excel")
    {
        try
        {
            var fileBytes = await _reportService.ExportMemberListAsync(format);
            var fileName = $"DanhSachThanhVien_{DateTime.Now:yyyyMMdd}";
            
            if (format.ToLower() == "excel")
            {
                return File(fileBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
                           fileName + ".xlsx");
            }
            else
            {
                return File(fileBytes, "application/pdf", fileName + ".pdf");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting member list");
            return StatusCode(500, new { message = "Có lỗi xảy ra khi xuất danh sách thành viên" });
        }
    }
}
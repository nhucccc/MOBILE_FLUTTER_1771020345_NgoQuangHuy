using pickleball_api_345.DTOs;

namespace pickleball_api_345.Services;

public interface IReportService
{
    Task<RevenueReportDto> GetRevenueReportDataAsync(DateTime fromDate, DateTime toDate);
    Task<List<MemberReportDto>> GetMemberReportDataAsync();
    Task<byte[]> ExportRevenueReportAsync(DateTime fromDate, DateTime toDate, string format = "excel");
    Task<byte[]> ExportMemberListAsync(string format = "excel");
    Task<byte[]> ExportTournamentReportAsync(int tournamentId, string format = "excel");
}
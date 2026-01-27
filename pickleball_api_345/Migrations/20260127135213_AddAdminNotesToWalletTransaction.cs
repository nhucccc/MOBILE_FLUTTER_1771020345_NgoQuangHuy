using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace pickleball_api_345.Migrations
{
    /// <inheritdoc />
    public partial class AddAdminNotesToWalletTransaction : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AdminNotes",
                table: "345_WalletTransactions",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AdminNotes",
                table: "345_WalletTransactions");
        }
    }
}

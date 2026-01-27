using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace pickleball_api_345.Migrations
{
    /// <inheritdoc />
    public partial class AddChatMessagesAndBonusFeatures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "RowVersion",
                table: "345_Bookings",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.CreateTable(
                name: "345_ChatMessages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TournamentId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Message = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    EditedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    MessageType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    AttachmentUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_345_ChatMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_345_ChatMessages_345_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "345_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_345_ChatMessages_345_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "345_Tournaments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_345_ChatMessages_MemberId",
                table: "345_ChatMessages",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_345_ChatMessages_TournamentId_CreatedDate",
                table: "345_ChatMessages",
                columns: new[] { "TournamentId", "CreatedDate" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "345_ChatMessages");

            migrationBuilder.DropColumn(
                name: "RowVersion",
                table: "345_Bookings");
        }
    }
}

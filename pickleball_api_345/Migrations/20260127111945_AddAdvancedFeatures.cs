using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace pickleball_api_345.Migrations
{
    /// <inheritdoc />
    public partial class AddAdvancedFeatures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "345_Tournaments",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "RegistrationDeadline",
                table: "345_Tournaments",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<decimal>(
                name: "DuprRating",
                table: "345_Members",
                type: "decimal(3,1)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "CancelReason",
                table: "345_Bookings",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledDate",
                table: "345_Bookings",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ReminderSent",
                table: "345_Bookings",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "345_Tournaments");

            migrationBuilder.DropColumn(
                name: "RegistrationDeadline",
                table: "345_Tournaments");

            migrationBuilder.DropColumn(
                name: "DuprRating",
                table: "345_Members");

            migrationBuilder.DropColumn(
                name: "CancelReason",
                table: "345_Bookings");

            migrationBuilder.DropColumn(
                name: "CancelledDate",
                table: "345_Bookings");

            migrationBuilder.DropColumn(
                name: "ReminderSent",
                table: "345_Bookings");
        }
    }
}

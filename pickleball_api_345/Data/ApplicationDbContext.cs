using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using pickleball_api_345.Models;

namespace pickleball_api_345.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    // DbSets for custom entities
    public DbSet<Member_345> Members_345 { get; set; }
    public DbSet<WalletTransaction_345> WalletTransactions_345 { get; set; }
    public DbSet<News_345> News_345 { get; set; }
    public DbSet<TransactionCategory_345> TransactionCategories_345 { get; set; }
    public DbSet<Court_345> Courts_345 { get; set; }
    public DbSet<Booking_345> Bookings_345 { get; set; }
    public DbSet<Tournament_345> Tournaments_345 { get; set; }
    public DbSet<TournamentParticipant_345> TournamentParticipants_345 { get; set; }
    public DbSet<Match_345> Matches_345 { get; set; }
    public DbSet<Notification_345> Notifications_345 { get; set; }
    public DbSet<ChatMessage_345> ChatMessages_345 { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Configure relationships and constraints
        
        // Member_345 - ApplicationUser (One-to-One)
        builder.Entity<Member_345>()
            .HasOne(m => m.User)
            .WithOne(u => u.Member)
            .HasForeignKey<Member_345>(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // WalletTransaction_345 - Member_345 (Many-to-One)
        builder.Entity<WalletTransaction_345>()
            .HasOne(wt => wt.Member)
            .WithMany(m => m.WalletTransactions)
            .HasForeignKey(wt => wt.MemberId)
            .OnDelete(DeleteBehavior.Cascade);

        // Booking_345 relationships
        builder.Entity<Booking_345>()
            .HasOne(b => b.Court)
            .WithMany(c => c.Bookings)
            .HasForeignKey(b => b.CourtId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Booking_345>()
            .HasOne(b => b.Member)
            .WithMany(m => m.Bookings)
            .HasForeignKey(b => b.MemberId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<Booking_345>()
            .HasOne(b => b.ParentBooking)
            .WithMany(b => b.ChildBookings)
            .HasForeignKey(b => b.ParentBookingId)
            .OnDelete(DeleteBehavior.Restrict);

        // Tournament relationships
        builder.Entity<TournamentParticipant_345>()
            .HasOne(tp => tp.Tournament)
            .WithMany(t => t.Participants)
            .HasForeignKey(tp => tp.TournamentId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<TournamentParticipant_345>()
            .HasOne(tp => tp.Member)
            .WithMany(m => m.TournamentParticipants)
            .HasForeignKey(tp => tp.MemberId)
            .OnDelete(DeleteBehavior.Restrict);

        // Match relationships
        builder.Entity<Match_345>()
            .HasOne(m => m.Tournament)
            .WithMany(t => t.Matches)
            .HasForeignKey(m => m.TournamentId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<Match_345>()
            .HasOne(m => m.Team1_Player1)
            .WithMany()
            .HasForeignKey(m => m.Team1_Player1Id)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Match_345>()
            .HasOne(m => m.Team1_Player2)
            .WithMany()
            .HasForeignKey(m => m.Team1_Player2Id)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Match_345>()
            .HasOne(m => m.Team2_Player1)
            .WithMany()
            .HasForeignKey(m => m.Team2_Player1Id)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Match_345>()
            .HasOne(m => m.Team2_Player2)
            .WithMany()
            .HasForeignKey(m => m.Team2_Player2Id)
            .OnDelete(DeleteBehavior.Restrict);

        // Notification relationship
        builder.Entity<Notification_345>()
            .HasOne(n => n.Receiver)
            .WithMany(m => m.Notifications)
            .HasForeignKey(n => n.ReceiverId)
            .OnDelete(DeleteBehavior.Cascade);

        // ChatMessage relationships
        builder.Entity<ChatMessage_345>()
            .HasOne(cm => cm.Tournament)
            .WithMany()
            .HasForeignKey(cm => cm.TournamentId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<ChatMessage_345>()
            .HasOne(cm => cm.Member)
            .WithMany()
            .HasForeignKey(cm => cm.MemberId)
            .OnDelete(DeleteBehavior.Restrict);

        // Indexes for performance
        builder.Entity<WalletTransaction_345>()
            .HasIndex(wt => wt.MemberId);

        builder.Entity<Booking_345>()
            .HasIndex(b => new { b.CourtId, b.StartTime, b.EndTime });

        builder.Entity<Match_345>()
            .HasIndex(m => m.TournamentId);

        builder.Entity<Notification_345>()
            .HasIndex(n => new { n.ReceiverId, n.IsRead });

        builder.Entity<ChatMessage_345>()
            .HasIndex(cm => new { cm.TournamentId, cm.CreatedDate });
    }
}
using DAL.Models.Tables;
using DAL.Models.Views;
using Microsoft.EntityFrameworkCore;

namespace DAL.Context
{
    public class FreelanceAppContext : DbContext
    {
        private readonly string _connectionString;

        public FreelanceAppContext(string connectionString)
        {
            _connectionString = connectionString;
            Database.EnsureCreated();
        }

        // tables
        public DbSet<Role> Roles { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Project> Projects { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<Complaint> Complaints { get; set; }
        public DbSet<Portfolio> Portfolios { get; set; }
        public DbSet<AuditLog> AuditLogs { get; set; }
        public DbSet<UserNotification> UserNotifications { get; set; } = null!;
        public DbSet<UserWarning> WarningDisplays { get; set; } = null!;

        // views
        public DbSet<LocalOrderDisplay> LocalOrders { get; set; }
        public DbSet<OrderWithMyReview> LocalOrdersWithMyReview { get; set; }
        public DbSet<OrderReviewsRow> LocalOrdersReviews { get; set; }
        public DbSet<Counterpart> LocalCounterparts { get; set; }
        public DbSet<MyComplaint> LocalMyComplaints { get; set; }
        public DbSet<ModerComplaint> ModerComplaints { get; set; } = null!;
        public DbSet<FreelancerRow> FreelancerRows { get; set; } = null!;
        public DbSet<ProjectWithoutStatus> ProjectWithoutStatuses { get; set; } = null!;

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseNpgsql(_connectionString);
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.HasDefaultSchema("core");

            // === User : Role ===
            modelBuilder
                .Entity<User>()
                .HasOne(u => u.Role)
                .WithMany(r => r.Users)
                .HasForeignKey(u => u.RoleId)
                .OnDelete(DeleteBehavior.Restrict);

            // for bytea array
            modelBuilder.Entity<User>()
                .Property(u => u.Photo)
                .HasColumnType("bytea");


            // === Project : Customer(User) ===
            modelBuilder
                .Entity<Project>()
                .HasOne(p => p.Customer)
                .WithMany(u => u.ProjectsAsCustomer)
                .HasForeignKey(p => p.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            // === Review : Author & Recipient (User) ===
            modelBuilder
                .Entity<Review>()
                .HasOne(r => r.Author)
                .WithMany(u => u.ReviewsAuthored)
                .HasForeignKey(r => r.AuthorId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder
                .Entity<Review>()
                .HasOne(r => r.Recipient)
                .WithMany(u => u.ReviewsReceived)
                .HasForeignKey(r => r.RecipientId)
                .OnDelete(DeleteBehavior.Cascade);

            // === Order : Project ===
            modelBuilder
                .Entity<Order>()
                .HasOne(o => o.Project)
                .WithMany(p => p.Orders)
                .HasForeignKey(o => o.ProjectId)
                .OnDelete(DeleteBehavior.Cascade);

            // === Order : Freelancer(User) ===
            modelBuilder
                .Entity<Order>()
                .HasOne(o => o.Freelancer)
                .WithMany(u => u.OrdersAsFreelancer)
                .HasForeignKey(o => o.FreelancerId)
                .OnDelete(DeleteBehavior.Cascade);

            // === Complaint : UserCom / FiledBy / Moderator / Project ===
            modelBuilder.Entity<Complaint>(b =>
            {
                // На кого подали
                b.HasOne(c => c.UserCom)
                 .WithMany(u => u.ComplaintsAgainstMe)
                 .HasForeignKey(c => c.UserComId)
                 .OnDelete(DeleteBehavior.Cascade);

                // Кто подал
                b.HasOne(c => c.FiledBy)
                 .WithMany(u => u.ComplaintsFiledByMe)
                 .HasForeignKey(c => c.FiledById)
                 .OnDelete(DeleteBehavior.Cascade);

                // Назначенный модератор
                b.HasOne(c => c.Moderator)
                 .WithMany(u => u.ComplaintsModerated)
                 .HasForeignKey(c => c.ModeratorId)
                 .OnDelete(DeleteBehavior.SetNull);
            });


            // === Portfolio : User ===
            modelBuilder
                .Entity<Portfolio>()
                .HasOne(p => p.User)
                .WithOne(u => u.Portfolio)
                .HasForeignKey<Portfolio>(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // === AuditLog : User ===
            modelBuilder
                .Entity<AuditLog>()
                .HasOne(l => l.User)
                .WithMany(u => u.AuditLogs)
                .HasForeignKey(l => l.UserId)
                .OnDelete(DeleteBehavior.SetNull);

            // === Notification : Sender(User) / Project ===
            modelBuilder.Entity<UserNotification>(entity =>
            {
                entity.HasNoKey(); // потому что это DTO из VIEW, а не реальная таблица
                entity.ToView("v_user_notifications", "core");

                entity.Property(n => n.Id_Notification).HasColumnName("id_notification");
                entity.Property(n => n.Id_Project).HasColumnName("id_project");
                entity.Property(n => n.Project_Title).HasColumnName("project_title");
                entity.Property(n => n.Id_Sender).HasColumnName("id_sender");
                entity.Property(n => n.Sender_Name).HasColumnName("sender_name");
                entity.Property(n => n.Created_At).HasColumnName("created_at");
            });
        }
    }
}

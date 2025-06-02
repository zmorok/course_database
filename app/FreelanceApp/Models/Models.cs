using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace FreelanceApp.Models
{
    [Table("roles", Schema = "core")]
    public class Role
    {
        [Key]
        [Column("id_role")]
        public int Id { get; set; }

        [Required, MaxLength(50)]
        [Column("role_name")]
        public string Name { get; set; }

        [Required]
        [Column("role_privileges", TypeName = "jsonb")]
        public JsonDocument Privileges { get; set; }

        public ICollection<User> Users { get; set; }
    }

    [Table("users", Schema = "core")]
    public class User
    {
        [Key]
        [Column("id_user")]
        public int Id { get; set; }

        [Required, StringLength(128)]
        [Column("password", TypeName = "char(128)")]
        public string Password { get; set; }

        [Required]
        [Column("role")]
        public int RoleId { get; set; }
        public Role Role { get; set; }

        [Required, MaxLength(100)]
        [Column("last_name")]
        public string LastName { get; set; }

        [Required, MaxLength(100)]
        [Column("first_name")]
        public string FirstName { get; set; }

        [MaxLength(100)]
        [Column("middle_name")]
        public string? MiddleName { get; set; }

        [MaxLength(10)]
        [Column("gender")]
        public string Gender { get; set; }

        [MaxLength(20)]
        [Column("phone_number")]
        public string? PhoneNumber { get; set; }

        [Required, MaxLength(100)]
        [Column("email")]
        public string Email { get; set; }

        [Required]
        [Column("registration_date")]
        public DateTime RegistrationDate { get; set; }

        [Column("last_online_time")]
        public DateTime? LastOnlineTime { get; set; }

        [Column("rating", TypeName = "decimal(2,1)")]
        public decimal Rating { get; set; }

        [Column("photo")]
        public byte[]? Photo { get; set; }

        public ICollection<Project> ProjectsAsCustomer { get; set; } = [];
        public ICollection<Review> ReviewsAuthored { get; set; } = [];
        public ICollection<Review> ReviewsReceived { get; set; } = [];
        public ICollection<Order> OrdersAsFreelancer { get; set; } = [];
        public ICollection<Complaint> ComplaintsFiled { get; set; } = [];
        public ICollection<Complaint> ComplaintsModerated { get; set; } = [];
        public ICollection<Complaint> ComplaintsAgainstMe { get; set; } = [];
        public ICollection<Complaint> ComplaintsFiledByMe { get; set; } = [];
        public Portfolio Portfolio { get; set; } = null!;
        public ICollection<AuditLog> AuditLogs { get; set; } = [];
    }

    [Table("projects", Schema = "core")]
    public class Project
    {
        [Key]
        [Column("id_project")]
        public int Id { get; set; }

        [Required]
        [Column("id_customer")]
        public int CustomerId { get; set; }
        public User Customer { get; set; }

        [Required, MaxLength(200)]
        [Column("title")]
        public string Title { get; set; }

        [Required, MaxLength(50)]
        [Column("status")]
        public string? Status { get; set; }

        [Required]
        [Column("description")]
        public string Description { get; set; }

        [Column("media", TypeName = "jsonb")]
        public JsonDocument Media { get; set; }

        public ICollection<Order> Orders { get; set; }
        public ICollection<Complaint> Complaints { get; set; } = new List<Complaint>();
    }

    [Table("reviews", Schema = "core")]
    public class Review
    {
        [Key]
        [Column("id_review")]
        public int Id { get; set; }

        [Required]
        [Column("id_author")]
        public int AuthorId { get; set; }
        public User Author { get; set; }

        [Required]
        [Column("id_recipient")]
        public int RecipientId { get; set; }
        public User Recipient { get; set; }

        [Required]
        [Column("comment")]
        public string Comment { get; set; }

        [Required]
        [Column("rating")]
        public int Rating { get; set; }

        [Column("media", TypeName = "jsonb")]
        public JsonDocument Media { get; set; }
    }

    [Table("orders", Schema = "core")]
    public class Order
    {
        [Key]
        [Column("id_order")]
        public int Id { get; set; }

        [Required]
        [Column("id_project")]
        public int ProjectId { get; set; }
        public Project Project { get; set; }

        [Required]
        [Column("id_freelancer")]
        public int FreelancerId { get; set; }
        public User Freelancer { get; set; }

        [Required, MaxLength(50)]
        [Column("status")]
        public string Status { get; set; }

        [Required]
        [Column("creation_date")]
        public DateTime CreationDate { get; set; }

        [Column("deadline")]
        public DateTime? Deadline { get; set; }
    }

    [Table("complaints", Schema = "core")]
    public class Complaint
    {
        [Key]
        [Column("id_complaint")]
        public int Id { get; set; }

        // На кого подали жалобу
        [Required]
        [Column("id_user")]
        public int UserComId { get; set; }
        [ForeignKey(nameof(UserComId))]
        public virtual User UserCom { get; set; } = null!;

        // Кто подал жалобу
        [Required]
        [Column("filed_by")]
        public int FiledById { get; set; }
        [ForeignKey(nameof(FiledById))]
        public virtual User FiledBy { get; set; } = null!;

        // Назначенный модератор (может быть NULL)
        [Column("id_moderator")]
        public int? ModeratorId { get; set; }
        [ForeignKey(nameof(ModeratorId))]
        public virtual User? Moderator { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("status")]
        public string Status { get; set; } = string.Empty;

        [Required]
        [Column("description")]
        public string Description { get; set; } = string.Empty;

        [Column("media", TypeName = "jsonb")]
        public JsonDocument? Media { get; set; }
    }

    [Table("portfolio", Schema = "core")]
    public class Portfolio
    {
        [Key]
        [Column("id_portfolio")]
        public int Id { get; set; }

        [Required]
        [Column("id_user")]
        public int UserId { get; set; }
        public User User { get; set; }

        [Required]
        [Column("description")]
        public string Description { get; set; }

        [Column("media", TypeName = "jsonb")]
        public JsonDocument Media { get; set; }

        [Required]
        [Column("skills")]
        public string[] Skills { get; set; }

        [Column("experience")]
        public string Experience { get; set; }
    }

    [Table("audit_logs", Schema = "core")]
    public class AuditLog
    {
        [Key]
        [Column("id_log")]
        public int Id { get; set; }

        [Column("user_id")]
        public int? UserId { get; set; }

        [NotMapped]
        public User User { get; set; }

        [Column("proc_name"), MaxLength(100)]
        public string ProcName { get; set; }

        [Required, MaxLength(10)]
        [Column("action")]
        public string Action { get; set; }

        [Required, MaxLength(50)]
        [Column("table_name")]
        public string TableName { get; set; }

        [Required]
        [Column("record_id")]
        public int RecordId { get; set; }

        [Column("old_data", TypeName = "jsonb")]
        public JsonDocument? OldData { get; set; }

        [Column("new_data", TypeName = "jsonb")]
        public JsonDocument? NewData { get; set; }

        [Required]
        [Column("changed_at")]
        public DateTime ChangedAt { get; set; }
    }
}

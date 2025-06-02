using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DAL.Models.Tables
{
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
}

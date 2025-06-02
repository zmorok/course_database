using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace DAL.Models.Tables
{
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
}

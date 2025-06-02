using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DAL.Models.Tables
{
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
}

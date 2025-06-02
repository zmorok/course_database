using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace DAL.Models.Tables
{
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
}

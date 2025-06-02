using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;

namespace DAL.Models.Tables
{
    [Table("complaints", Schema = "core")]
    public class Complaint
    {
        [Key]
        [Column("id_complaint")]
        public int Id { get; set; }

        [Required]
        [Column("id_user")]
        public int UserComId { get; set; }
        [ForeignKey(nameof(UserComId))]
        public virtual User UserCom { get; set; } = null!;

        [Required]
        [Column("filed_by")]
        public int FiledById { get; set; }
        [ForeignKey(nameof(FiledById))]
        public virtual User FiledBy { get; set; } = null!;

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
}

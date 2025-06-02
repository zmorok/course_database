using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DAL.Models.Tables
{
    [Table("v_user_warnings", Schema = "core")]
    public class UserWarning
    {
        [Key]
        [Column("id_warning")]
        public int WarningId { get; set; }

        [Column("moderator_name")]
        public string ModeratorName { get; set; } = string.Empty;

        [Column("message")]
        public string Message { get; set; } = string.Empty;

        [Column("expires_at")]
        public DateTime ExpiresAt { get; set; }
    }
}

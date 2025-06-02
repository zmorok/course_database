using System.ComponentModel.DataAnnotations;

namespace DAL.Models.Views
{
    public sealed class Counterpart
    {
        [Key]
        public int Id { get; set; }
        public string FullName { get; set; } = "";
    }
}

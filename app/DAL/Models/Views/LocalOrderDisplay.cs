using System.ComponentModel.DataAnnotations;

namespace DAL.Models.Views
{
    public class LocalOrderDisplay
    {
        [Key]
        public int OrderId { get; set; }
        public string OrderStatus { get; set; }
        public DateTime OrderCreationDate { get; set; }
        public DateTime? OrderDeadline { get; set; }

        public int ProjectId { get; set; }
        public string ProjectTitle { get; set; }
        public string ProjectStatus { get; set; }

        public int CustomerId { get; set; }
        public string CustomerFullName { get; set; }

        public int? FreelancerId { get; set; }
        public string FreelancerFullName { get; set; }
    }
}

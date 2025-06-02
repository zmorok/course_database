using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DAL.Models.Views
{
    public class AdminRoleView
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Privileges { get; set; }
    }
}

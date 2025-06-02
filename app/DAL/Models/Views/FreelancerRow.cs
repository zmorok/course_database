using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DAL.Models.Views
{
    // DTO?
    public sealed class FreelancerRow
    {
        public int Id { get; init; }
        public string FullName { get; init; } = "";
        public string SkillsPreview { get; init; } = "";
        public bool CanInvite { get; init; } // отключаем кнопку, если уже есть уведомление
    }
}

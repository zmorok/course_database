using DAL.Context;
using DAL.Models.Tables;
using DAL.Models.Views;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace DAL.Repository.AdminRepositories
{
    public interface IAdminRolesRepository
    {
        Task<List<AdminRoleView>> GetRolesAsync();
        Task CreateRole(int actorId, string text, JsonElement json);
        Task UpdateRole(int actorId, int roleId, JsonElement json);
        Task DeleteRole(int actorId, int roleId);
    }

    public class AdminRolesRepository(FreelanceAppContext context) : IAdminRolesRepository
    {
        private readonly FreelanceAppContext _context = context;

        public async Task<List<AdminRoleView>> GetRolesAsync()
        {
            var rawList = await _context.Set<Role>()
                                .FromSqlRaw("SELECT * FROM core.admin_get_roles()")
                                .ToListAsync();

            return rawList.Select(p => new AdminRoleView
                    {
                        Id = p.Id,
                        Name = p.Name,
                        Privileges = p.Privileges?.RootElement.GetRawText() ?? "[]"
                    }).ToList();
        }

        public async Task CreateRole(int actorId, string text, JsonElement json)
        {
            await context.Database.ExecuteSqlInterpolatedAsync(
                            $@"CALL core.admin_create_role(
                                {actorId},
                                {text},
                                {json})"
            );
        }

        public async Task UpdateRole(int actorId, int roleId, JsonElement json)
        {
            await context.Database.ExecuteSqlInterpolatedAsync(
                            $@"CALL core.admin_update_role(
                                {actorId},
                                {roleId},
                                {json})"
            );
        }

        public async Task DeleteRole(int actorId, int roleId)
        {
            await context.Database.ExecuteSqlInterpolatedAsync(
                            $@"CALL core.admin_delete_role(
                                {actorId},
                                {roleId})"
            );
        }
    }
}

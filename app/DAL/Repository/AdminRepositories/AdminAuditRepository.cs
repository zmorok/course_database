using DAL.Context;
using DAL.Models.Tables;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DAL.Repository.AdminRepositories
{
    public interface IAdminAuditRepository
    {
        Task<IEnumerable> GetLogs(DateTime? since = null, DateTime? until = null, int? limit = 500);
        Task ExportLogs(string filename, DateTime? since = null, DateTime? until = null);
        Task ImportLogs(string filename);
    }

    public class AdminAuditRepository(FreelanceAppContext context) : IAdminAuditRepository
    {
        private readonly FreelanceAppContext _context = context;
        
        public async Task<IEnumerable> GetLogs(DateTime? since = null, DateTime? until = null, int? limit = 500)
        {
            since = DateTime.SpecifyKind((since ?? DateTime.MinValue), DateTimeKind.Utc);
            until = DateTime.SpecifyKind((until ?? DateTime.Now), DateTimeKind.Utc);

            var rawLogs = await _context
                    .Set<AuditLog>()
                    .FromSqlInterpolated(
                        $@"SELECT * 
                            FROM core.admin_get_audit_logs
                            (CAST({since} as TIMESTAMP),
                            CAST({until} as TIMESTAMP))
                            LIMIT {limit}"
                    )
                    .ToListAsync();

            IEnumerable logs = rawLogs.Select(l => new
            {
                l.Id,
                l.UserId,
                l.ProcName,
                l.Action,
                l.TableName,
                l.RecordId,
                l.ChangedAt,
                OldData = l.OldData?.RootElement.GetRawText() ?? "{}",
                NewData = l.NewData?.RootElement.GetRawText() ?? "{}",
            }).OrderBy(l => l.Id);

            return logs;
        }

        public async Task ExportLogs(string filename, DateTime? since, DateTime? until)
        {
            await _context.Database.ExecuteSqlInterpolatedAsync(
                    $@"CALL core.admin_export_audit_logs_json(
                    {filename},{since},{until})"
                );
        }

        public async Task ImportLogs(string filename)
        {
            await _context.Database.ExecuteSqlInterpolatedAsync(
                    $@"CALL core.admin_import_audit_logs_json({filename})"
                );
        }
    }
}
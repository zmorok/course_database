using DAL.Context;
using DAL.Models.Views;
using Microsoft.EntityFrameworkCore;

namespace DAL.Repository.UserRepositories
{
    public interface IUserComplaintsRepository
    {
        Task<List<Counterpart>> GetCounterpartsAsync(int userId);
        Task<List<MyComplaint>> GetComplaintsAsync(int userId);
        Task CreateComplaintAsync(int actorId, int filedById, int targetUserId, string description);
        Task UpdateComplaintAsync(int actorId, int complaintId, string description);
        Task DeleteComplaintAsync(int actorId, int complaintId);
    }

    public class UserComplaintsRepository(FreelanceAppContext context) : IUserComplaintsRepository
    {
        private readonly FreelanceAppContext _context = context;

        public Task<List<Counterpart>> GetCounterpartsAsync(int userId)
        {
            return _context.Set<Counterpart>()
                .FromSqlInterpolated($@"
                    SELECT *
                      FROM core.user_counterparts({userId})
                ")
                .ToListAsync();
        }

        public Task<List<MyComplaint>> GetComplaintsAsync(int userId)
        {
            return _context.Set<MyComplaint>()
                .FromSqlInterpolated($@"
                    SELECT *
                      FROM core.user_get_complaints({userId})
                ")
                .ToListAsync();
        }

        public Task CreateComplaintAsync(int actorId, int filedById, int targetUserId, string description)
        {
            return _context.Database.ExecuteSqlInterpolatedAsync($@"
                CALL core.user_create_complaint(
                    {actorId},
                    {filedById},
                    {targetUserId},
                    {description},
                    CAST(NULL AS jsonb)
                )
            ");
        }

        public Task UpdateComplaintAsync(int actorId, int complaintId, string description)
        {
            return _context.Database.ExecuteSqlInterpolatedAsync($@"
                CALL core.user_update_complaint(
                    {actorId},
                    {complaintId},
                    NULL, NULL, NULL,
                    {description}
                )
            ");
        }

        public Task DeleteComplaintAsync(int actorId, int complaintId)
        {
            return _context.Database.ExecuteSqlInterpolatedAsync($@"
                CALL core.user_delete_complaint(
                    {actorId},
                    {complaintId}
                )
            ");
        }
    }
}

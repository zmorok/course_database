using Microsoft.EntityFrameworkCore.Storage;
using DAL.Context;
using DAL.Repository.UserRepositories;
using DAL.Repository.AdminRepositories;

namespace DAL
{
    public interface IUnitOfWork : IDisposable
    {
        IUserProfileRepository Users { get; }
        IUserPortfolioRepository Portfolios { get; }
        IUserOrdersRepository Orders { get; }
        IUserProjectsRepository Projects { get; }
        IUserReviewsRepository Reviews { get; }
        IUserComplaintsRepository Complaints { get; }
        IUserSearchRepository Search { get; }

        IAdminUsersRepository AdminUsers { get; }
        IAdminRolesRepository AdminRoles { get; }
        IAdminAuditRepository AdminAudit { get; }

        //TODO
        // репозитории админа и модератора

        //TODO
        // почистить приложение от логики работы с бд

        Task<int> CompleteAsync();
        Task BeginTransactionAsync();
        Task CommitAsync();
        Task RollbackAsync();
    }

    public class UnitOfWork : IUnitOfWork
    {
        private readonly FreelanceAppContext _context;
        private IDbContextTransaction? _transaction;

        public IUserProfileRepository Users { get; }
        public IUserPortfolioRepository Portfolios { get; }
        public IUserOrdersRepository Orders { get; }
        public IUserProjectsRepository Projects { get; }
        public IUserReviewsRepository Reviews { get; }
        public IUserComplaintsRepository Complaints { get; }
        public IUserSearchRepository Search { get; }

        public IAdminUsersRepository AdminUsers { get; }
        public IAdminRolesRepository AdminRoles { get; }
        public IAdminAuditRepository AdminAudit { get; }

        public UnitOfWork(FreelanceAppContext context)
        {
            _context = context;
            Users = new UserProfileRepository(_context);
            Portfolios = new UserPortfolioRepository(_context);
            Orders = new UserOrdersRepository(_context);
            Projects = new UserProjectsRepository(_context);
            Reviews = new UserReviewsRepository(_context);
            Complaints = new UserComplaintsRepository(_context);
            Search = new UserSearchRepository(_context);

            AdminUsers = new AdminUsersRepository(_context);
            AdminRoles = new AdminRolesRepository(_context);
            AdminAudit = new AdminAuditRepository(_context);

        }

        public async Task BeginTransactionAsync()
        {
            _transaction ??= await _context.Database.BeginTransactionAsync();
        }

        public async Task<int> CompleteAsync()
        {
            return await _context.SaveChangesAsync();
        }

        public async Task CommitAsync()
        {
            if (_transaction is not null)
            {
                await _transaction.CommitAsync();
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }

        public async Task RollbackAsync()
        {
            if (_transaction is not null)
            {
                await _transaction.RollbackAsync();
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }

        public void Dispose()
        {
            _transaction?.Dispose();
            _context.Dispose();
        }
    }
}

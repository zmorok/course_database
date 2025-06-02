using System.Data;
using System.Data.Common;
using System.Windows;
using System.Windows.Controls;
using DAL.Models.Tables;
using FreelanceApp.Services;
using Microsoft.EntityFrameworkCore;

namespace FreelanceApp.Windows.AdminControls
{
    public partial class RawSqlControl : UserControl
    {
        private readonly User _currentUser;
        private readonly Dictionary<string, string> _examples = new()
        {
            ["Все пользователи"] = "SELECT * FROM core.admin_get_users();",
            ["Все роли"] = "SELECT * FROM core.admin_get_roles();",
            ["Логи аудита (последние)"] = "SELECT * FROM core.admin_get_audit_logs(NULL, NULL);",
        };

        public RawSqlControl(User user)
        {
            InitializeComponent();
            _currentUser = user;
            ExamplesList.ItemsSource = _examples.Keys;
        }

        private void ExamplesList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (ExamplesList.SelectedItem is string key && _examples.TryGetValue(key, out var sql))
            {
                SqlTextBox.Text = sql;
            }
        }

        private async void OnExecuteClick(object sender, RoutedEventArgs e)
        {
            string sql = SqlTextBox.Text.Trim();
            if (string.IsNullOrEmpty(sql))
            {
                MessageBox.Show(
                    "Введите SQL-запрос или выберите пример.",
                    "Внимание",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning
                );
                return;
            }

            try
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);
                // Открыть подключение и выполнить команду
                DbConnection conn = context.Database.GetDbConnection();
                await conn.OpenAsync();

                using var cmd = conn.CreateCommand();
                cmd.CommandText = sql;

                using var reader = await cmd.ExecuteReaderAsync();
                var table = new DataTable();
                table.Load(reader);

                ResultGrid.ItemsSource = table.DefaultView;
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка выполнения запроса:\n{ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
            finally
            {
                await using var context = DbContextFactory.CreateDbContext(_currentUser);
                await context.Database.GetDbConnection().CloseAsync();
            }
        }
    }
}

using DAL.Models.Tables;
using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Microsoft.EntityFrameworkCore;
using Microsoft.Win32;             // SaveFileDialog / OpenFileDialog
using FreelanceApp.Services;
using System.Text.RegularExpressions;

namespace FreelanceApp.Windows.AdminControls
{
    public partial class ImportExportControl : UserControl
    {
        private readonly User _currentUser;
        public ObservableCollection<OperationStat> OperationStats { get; } = new();

        public ImportExportControl(User user)
        {
            InitializeComponent();
            _currentUser = user;
            DataContext = this;
        }

        private async void ExportButton_Click(object sender, RoutedEventArgs e)
        {

            try
            {
                MessageBox.Show("Выберите путь без кириллицы.");

                var dlg = new SaveFileDialog
                {
                    Title = "Сохранить дамп БД в JSON-файл",
                    Filter = "JSON-файлы (*.json)|*.json|Все файлы (*.*)|*.*",
                    FileName = "db_dump.json"
                };
                if (dlg.ShowDialog() != true)
                    return;

                if (Regex.IsMatch(dlg.FileName, @"\p{IsCyrillic}"))
                {
                    MessageBox.Show("В вашем пути есть кириллица.");
                    return;
                }

                string filePath = dlg.FileName;

                var dir = Path.GetDirectoryName(filePath);
                if (!Directory.Exists(dir))
                    Directory.CreateDirectory(dir);             // создаём, если нет

                await using var ctx = DbContextFactory.CreateDbContext(_currentUser);
                await ctx.Database
                         .ExecuteSqlInterpolatedAsync($"CALL core.admin_export_db({filePath})");

                OperationStats.Add(new OperationStat
                {
                    TableName = "all",
                    OperationType = "Экспорт",
                    RowsAffected = 0
                });

                MessageBox.Show(
                    $"Экспорт завершён.\nФайл: {filePath}",
                    "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка экспорта:\n{ex.Message}",
                    "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void ImportButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                MessageBox.Show("Выберите путь без кириллицы.");
                var dlg = new OpenFileDialog
                {
                    Title = "Выберите JSON-файл дампа БД",
                    Filter = "JSON-файлы (*.json)|*.json|Все файлы (*.*)|*.*",
                    Multiselect = false
                };
                if (dlg.ShowDialog() != true)
                    return;

                if (Regex.IsMatch(dlg.FileName, @"\p{IsCyrillic}"))
                {
                    MessageBox.Show("В вашем пути есть кириллица.");
                    return;
                }

                string filePath = dlg.FileName;

                await using var ctx = DbContextFactory.CreateDbContext(_currentUser);
                await ctx.Database
                         .ExecuteSqlInterpolatedAsync($"CALL core.admin_import_db({filePath})");

                OperationStats.Add(new OperationStat
                {
                    TableName = "all",
                    OperationType = "Импорт",
                    RowsAffected = 0
                });

                MessageBox.Show(
                    $"Импорт завершён из файла:\n{filePath}",
                    "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка импорта:\n{ex.Message}",
                    "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }

    /* Модель строки статистики */
    public class OperationStat
    {
        public string TableName { get; set; }
        public string OperationType { get; set; }  // "Импорт" или "Экспорт"
        public int RowsAffected { get; set; }
    }
}

using System;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using Microsoft.EntityFrameworkCore;
using Microsoft.Win32;
using DAL.Models.Tables;
using FreelanceApp.Services;

namespace FreelanceApp.Windows.AdminControls
{
    public partial class ReportControl : UserControl
    {
        private readonly User _currentUser;

        public ReportControl(User currentUser)
        {
            InitializeComponent();
            _currentUser = currentUser;
            FormatComboBox.SelectedIndex = 0;
        }

        private async void ExportButton_Click(object sender, RoutedEventArgs e)
        {
            var selected = FormatComboBox.SelectedItem as ComboBoxItem;
            var format = (selected?.Tag ?? "csv").ToString();

            // Show SaveFileDialog
            var dlg = new SaveFileDialog
            {
                Title = "Сохранить отчёт",
                Filter = "CSV-файл (*.csv)|*.csv|Текстовый файл (*.txt)|*.txt|JSON-файл (*.json)|*.json|HTML-файл (*.html)|*.html|Все файлы|*.*",
                DefaultExt = "." + format,
                FileName = $"schema_report_{DateTime.Now:yyyyMMdd_HHmmss}.{format}"
            };

            if (dlg.ShowDialog() != true)
                return;

            var path = dlg.FileName;

            // Блокируем кириллицу
            if (Regex.IsMatch(path, @"\p{IsCyrillic}"))
            {
                MessageBox.Show(
                    "Путь к файлу не должен содержать кириллицу.",
                    "Неверный путь",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning
                );
                return;
            }

            try
            {
                // Выполняем процедуру на сервере
                await using var ctx = DbContextFactory.CreateDbContext(_currentUser);
                await ctx.Database.ExecuteSqlRawAsync(
                    "CALL core.export_schema_report({0}, {1}, {2})",
                    "core",        // схема
                    path,          // путь
                    format         // формат
                );

                MessageBox.Show(
                    $"Отчёт успешно сохранён в:\n{path}",
                    "Готово",
                    MessageBoxButton.OK,
                    MessageBoxImage.Information
                );
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Не удалось экспортировать отчёт:\n{ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
            }
        }
    }
}

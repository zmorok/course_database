using DAL;
using DAL.Models.Tables;
using FreelanceApp.Services;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace FreelanceApp.Windows.UserControls
{
    public partial class PortfolioControl : UserControl
    {
        private IUnitOfWork? _uow;
        private User? _currentUser;
        private Portfolio? _selectedPortfolio;

        public PortfolioControl()
        {
            InitializeComponent();
            Loaded += async (_, _) => await LoadPortfoliosAsync();
        }

        public void Initialize(User user)
        {
            _currentUser = user;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
        }

        private async Task LoadPortfoliosAsync()
        {
            if (_currentUser == null || _uow == null)
            {
                PortfolioItemsControl.ItemsSource = null;
                return;
            }

            try
            {
                var list = await _uow.Portfolios.GetPortfoliosAsync(_currentUser.Id);

                var viewList = list
                    .Select(p => new
                    {
                        p.Id,
                        p.Description,
                        p.Experience,
                        Media = TryParseJson(p.Media),
                        Skills = p.Skills != null ? string.Join(", ", p.Skills) : "",
                        Original = p
                    })
                    .ToList();

                PortfolioItemsControl.ItemsSource = viewList;
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при загрузке портфолио:\n{ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private static string TryParseJson(JsonDocument? doc)
        {
            if (doc == null) return "";
            try { return doc.RootElement.ToString(); }
            catch { return ""; }
        }

        #region Add / Edit Form

        private void OnAddClick(object sender, RoutedEventArgs e)
        {
            _selectedPortfolio = null;
            ClearForm();
            AddFormPanel.Visibility = Visibility.Visible;
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            AddFormPanel.Visibility = Visibility.Collapsed;
            ClearForm();
            _selectedPortfolio = null;
        }

        private async void OnSaveClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null) return;

            var description = DescriptionBox.Text;
            var mediaJson = MediaJsonBox.Text;
            var skills = SkillsBox.Text
                                 .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            var experience = ExperienceBox.Text;

            try
            {
                if (_selectedPortfolio == null)
                {
                    await _uow.Portfolios.CreatePortfolioAsync(
                        _currentUser.Id,
                        _currentUser.Id,
                        description,
                        mediaJson,
                        skills,
                        experience);
                    MessageBox.Show("Портфолио добавлено.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                }
                else
                {
                    await _uow.Portfolios.UpdatePortfolioAsync(
                        _currentUser.Id,
                        _currentUser.Id,
                        _selectedPortfolio.Id,
                        description,
                        mediaJson,
                        skills,
                        experience);
                    MessageBox.Show("Портфолио обновлено.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                }

                AddFormPanel.Visibility = Visibility.Collapsed;
                ClearForm();
                _selectedPortfolio = null;
                await LoadPortfoliosAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при сохранении портфолио:\n{ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        private void ClearForm()
        {
            DescriptionBox.Text = "";
            MediaJsonBox.Text = "";
            SkillsBox.Text = "";
            ExperienceBox.Text = "";
        }

        #endregion

        #region Delete

        private async void OnDeleteClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null || _selectedPortfolio == null)
            {
                MessageBox.Show(
                    "Выберите портфолио для удаления.",
                    "Предупреждение",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);
                return;
            }

            var result = MessageBox.Show(
                $"Удалить портфолио №{_selectedPortfolio.Id}?\n{_selectedPortfolio.Description}",
                "Подтвердите удаление",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (result != MessageBoxResult.Yes) return;

            try
            {
                await _uow.Portfolios.DeletePortfolioAsync(
                    _currentUser.Id,
                    _currentUser.Id,
                    _selectedPortfolio.Id);
                MessageBox.Show("Портфолио удалено.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                _selectedPortfolio = null;
                AddFormPanel.Visibility = Visibility.Collapsed;
                ClearForm();
                await LoadPortfoliosAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Ошибка при удалении портфолио:\n{ex.Message}",
                    "Ошибка",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }

        #endregion

        #region Selection

        private void OnPortfolioClick(object sender, MouseButtonEventArgs e)
        {
            if (sender is FrameworkElement fe && fe.DataContext is { } data)
            {
                var originalProp = data.GetType().GetProperty("Original");
                if (originalProp?.GetValue(data) is Portfolio p)
                {
                    _selectedPortfolio = p;
                    DescriptionBox.Text = p.Description ?? "";
                    MediaJsonBox.Text = TryParseJson(p.Media);
                    SkillsBox.Text = p.Skills != null ? string.Join(", ", p.Skills) : "";
                    ExperienceBox.Text = p.Experience ?? "";
                    AddFormPanel.Visibility = Visibility.Visible;
                }
            }
        }

        #endregion
    }
}

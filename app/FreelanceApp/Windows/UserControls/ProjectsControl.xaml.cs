using DAL;
using DAL.Repository;
using DAL.Models.Tables;
using DAL.Models.Views;
using FreelanceApp.Services;

using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace FreelanceApp.Windows.UserControls
{
    public partial class ProjectsControl : UserControl
    {
        private IUnitOfWork? _uow;
        private User? _currentUser;
        private Project? _selectedProject;
        private bool _showOnlyMine = false;
        private string _statusFilter = string.Empty;

        public ProjectsControl()
        {
            InitializeComponent();

            Loaded += async (_, _) => await LoadProjectsAsync();
        }

        public void Initialize(User user)
        {
            _currentUser = user;
            _uow = new UnitOfWork(DbContextFactory.CreateDbContext(_currentUser));
        }

        private async Task LoadProjectsAsync()
        {
            if (IsLoaded)
            {
                if (_currentUser == null || _uow == null)
                {
                    ProjectsItemsControl.ItemsSource = null;
                    return;
                }

                try
                {
                    var existingOrders = await _uow.Orders.GetOrdersByCustomerAsync(_currentUser.Id, limit: 100);
                    var respondedProjectIds = existingOrders.Select(o => o.ProjectId).ToHashSet();

                    IEnumerable<dynamic> items;

                    if (_showOnlyMine)
                    {
                        // свои проекты
                        var myList = string.IsNullOrEmpty(_statusFilter)
                            ? await _uow.Projects.GetProjectsByCustomerAsync(_currentUser.Id, limit: 100)
                            : await _uow.Projects.GetProjectsByCustomerAndStatusAsync(_currentUser.Id, _statusFilter, limit: 100);

                        items = myList.Select(p => new
                        {
                            Project = p,
                            p.Status,
                            IsMine = true,
                            ShowRespondButton = false
                        });
                    }
                    else
                    {
                        // чужие или все проекты
                        if (!string.IsNullOrEmpty(_statusFilter))
                        {
                            var withoutStatus = await _uow.Projects.GetProjectsWithoutStatusAsync(_statusFilter, limit: 100);
                            items = withoutStatus.Select(p => new
                            {
                                Project = p,
                                Status = _statusFilter,
                                IsMine = p.Id_Customer == _currentUser.Id,
                                ShowRespondButton = p.Id_Customer != _currentUser.Id
                                                    && !respondedProjectIds.Contains(p.Id_Project)
                            });
                        }
                        else
                        {
                            var allList = await _uow.Projects.GetAllProjectsAsync(limit: 100);
                            items = allList.Select(p => new
                            {
                                Project = p,
                                p.Status,
                                IsMine = p.CustomerId == _currentUser.Id,
                                ShowRespondButton = p.CustomerId != _currentUser.Id
                                                    && !respondedProjectIds.Contains(p.Id)
                            });
                        }
                    }

                    ProjectsItemsControl.ItemsSource = items;
                }
                catch (Exception ex)
                {
                    MessageBox.Show(
                        $"Ошибка при загрузке проектов:\n{ex.Message}",
                        "Ошибка",
                        MessageBoxButton.OK,
                        MessageBoxImage.Error);
                }
            }
            
        }

        private static string TryParseJson(JsonDocument? doc)
        {
            if (doc == null) return string.Empty;
            try
            {
                return doc.RootElement.ToString();
            }
            catch
            {
                return string.Empty;
            }
        }

        private void OnStatusFilterChanged(object sender, SelectionChangedEventArgs e)
        {
            if (StatusFilterComboBox.SelectedItem is ComboBoxItem item)
            {
                _statusFilter = item.Tag?.ToString() ?? string.Empty;
                _ = LoadProjectsAsync();
            }
        }

        private async void OnRespondClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null) return;
            if (sender is Button btn && btn.Tag is Project project)
            {
                try
                {
                    await _uow.Orders.CreateOrderAsync(
                        actorId: _currentUser.Id,
                        projectId: project.Id,
                        freelancerId: _currentUser.Id,
                        status: "pending",
                        deadline: null);
                    MessageBox.Show("Вы откликнулись на проект!", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                    _ = LoadProjectsAsync();
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Ошибка при отклике: {ex.Message}", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private void OnToggleMineClick(object sender, RoutedEventArgs e)
        {
            _showOnlyMine = !_showOnlyMine;
            ToggleMineButton.Content = _showOnlyMine ? "Показать все" : "Показать только мои";
            HideForm();
            _ = LoadProjectsAsync();
        }

        private void OnAddClick(object sender, RoutedEventArgs e)
        {
            _selectedProject = null;
            ShowForm();
        }

        private void OnUpdateClick(object sender, RoutedEventArgs e)
        {
            if (_selectedProject == null)
            {
                MessageBox.Show("Выберите проект для редактирования.", "Внимание", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            ShowForm(_selectedProject);
        }

        private async void OnDeleteClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null || _selectedProject == null)
            {
                MessageBox.Show("Выберите проект.", "Внимание", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var confirm = MessageBox.Show(
                $"Удалить проект №{_selectedProject.Id}?",
                "Подтверждение",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (confirm != MessageBoxResult.Yes) return;

            try
            {
                await _uow.Projects.DeleteProjectAsync(
                    actorId: _currentUser.Id,
                    projectId: _selectedProject.Id);
                MessageBox.Show("Проект удалён.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                _selectedProject = null;
                HideForm();
                _ = LoadProjectsAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при удалении проекта:\n{ex.Message}", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void OnSaveClick(object sender, RoutedEventArgs e)
        {
            if (_currentUser == null || _uow == null) return;

            var title = TitleBox.Text;
            var description = DescriptionBox.Text;
            var status = (StatusComboBox.SelectedItem as ComboBoxItem)?.Tag?.ToString() ?? "draft";
            var media = MediaBox.Text;

            try
            {
                if (_selectedProject == null)
                {
                    await _uow.Projects.CreateProjectAsync(
                        actorId: _currentUser.Id,
                        userId: _currentUser.Id,
                        title: title,
                        status: status,
                        description: description,
                        mediaJson: media);
                    MessageBox.Show("Проект создан.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                }
                else
                {
                    await _uow.Projects.UpdateProjectAsync(
                        actorId: _currentUser.Id,
                        projectId: _selectedProject.Id,
                        title: title,
                        status: status,
                        description: description,
                        mediaJson: media);
                    MessageBox.Show("Проект обновлён.", "Успех", MessageBoxButton.OK, MessageBoxImage.Information);
                }

                HideForm();
                _ = LoadProjectsAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка при сохранении проекта:\n{ex.Message}", "Ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
            => HideForm();

        private void ShowForm(Project? project = null)
        {
            FormPanel.Visibility = Visibility.Visible;
            if (project != null)
            {
                _selectedProject = project;
                TitleBox.Text = project.Title;
                DescriptionBox.Text = project.Description;
                var element = JsonSerializer.Deserialize<JsonElement>(project.Media);
                MediaBox.Text = element.ValueKind switch
                {
                    JsonValueKind.String => element.GetString() ?? "",
                    JsonValueKind.Array => string.Join(", ", element.EnumerateArray().Select(x => x.ToString())),
                    JsonValueKind.Object => element.GetRawText(),
                    _ => element.ToString()
                };
                StatusComboBox.SelectedItem = StatusComboBox.Items
                    .Cast<ComboBoxItem>()
                    .FirstOrDefault(i => (string?)i.Tag == project.Status);
            }
            else
            {
                _selectedProject = null;
                TitleBox.Clear();
                DescriptionBox.Clear();
                MediaBox.Clear();
                StatusComboBox.SelectedIndex = -1;
            }
        }

        private void HideForm()
        {
            FormPanel.Visibility = Visibility.Collapsed;
            _selectedProject = null;
        }

        private void OnProjectSelect(object sender, MouseButtonEventArgs e)
        {
            if (_currentUser == null) return;
            if (sender is Border border && border.Tag is Project project && project.CustomerId == _currentUser.Id)
            {
                ShowForm(project);
            }
        }
    }
}

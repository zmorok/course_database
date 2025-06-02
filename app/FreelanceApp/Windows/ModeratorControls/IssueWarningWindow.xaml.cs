using System.Windows;

namespace FreelanceApp.Windows.ModeratorControls
{
    public partial class IssueWarningWindow : Window
    {
        public string WarningMessage { get; private set; } = "";
        public int ExpiresDays { get; private set; }

        public IssueWarningWindow()
        {
            InitializeComponent();
        }

        private void Ok_Click(object sender, RoutedEventArgs e)
        {
            var msg = MsgBox.Text.Trim();
            if (string.IsNullOrWhiteSpace(msg))
            {
                MessageBox.Show("Введите текст предупреждения.", "Ошибка",
                                MessageBoxButton.OK, MessageBoxImage.Error);
                return;
                
            }

            if (!int.TryParse(DaysBox.Text, out var days) || days < 0)
            {
                MessageBox.Show("Срок должен быть неотрицательным целым числом.", "Ошибка",
                                MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            WarningMessage = msg;
            ExpiresDays = days;

            DialogResult = true;
        }

        private void Cancel_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
        }
    }
}

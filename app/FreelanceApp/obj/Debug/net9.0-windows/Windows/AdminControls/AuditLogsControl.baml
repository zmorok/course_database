   M S B A M L   `   `   `  ����G  CFreelanceApp, Version=1.0.0.0, Culture=neutral, PublicKeyToken=nullA%clr-namespace:FreelanceApp.ConvertersFreelanceApp.Converters  5      W0clr-namespace:FreelanceApp.Windows.AdminControls"FreelanceApp.Windows.AdminControls  5      9    3FreelanceApp.Windows.AdminControls.AuditLogsControl   5      W SPresentationCore, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     5      R NSystem.Xaml, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      <
converters%clr-namespace:FreelanceApp.Converters     5      @d2http://schemas.microsoft.com/expression/blend/2008     5      Blocal0clr-namespace:FreelanceApp.Windows.AdminControls     5      Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5        � 	Resources  5      0   *FreelanceApp.Converters.SubstringConverter 	  Sub50   	MaxLength��%&   &	          5   
   $ 50��66   5      .��5      �  � ColumnDefinitions 5   
   �� 5      $	��250 �6   �� 5      $��* �6   .+�5   
   �� $��0��6   $��0,0,10,0q�6%   .+�5      �� $��0,0,0,10q�5      $
��Bold"�5      $ ��Фильтр по дате��5      �� 5      $��С (since):��6   (  "System.Windows.Controls.DatePicker  5      -   5          Name$ SincePicker��5      �� 5!      $��0,5,0,0q�6   $��По (until):��6)     5"      -   5        $ UntilPicker��5"      �� 5$      -   5        $��0,10,0,0q�5%      $��Загрузить��5'      �� 5)      $
��0,20q�6   �� 5+      $��0,0,0,10q�5,      $
��Bold"�5-      $!��Экспорт/Импорт��5.      �� 5/      -   5        $��0,0,5,5q�50      $��Экспорт в JSON��52      �� 53      -   5        $��Импорт из JSON��53   +   54      &   System.Windows.Controls.DataGrid  57   
   -   5          Name$ 	AuditGrid��58      $��1��59      $��0q�5:         AutoGenerateColumns$ False��5;         CanUserAddRows$ False��5<         
IsReadOnly$
 True��5=         Columns 5?      0  *System.Windows.Controls.DataGridTextColumn  5@      ,  &System.Windows.Controls.DataGridColumn	   Width5  /System.Windows.Controls.DataGridLengthConverter$	 50 5A      
   Header$
 Id��5C      1  +System.Windows.Controls.DataGridBoundColumn   Binding 5B      �� *Id+5C        5D      $		 150 5E      $
 	Procedure��5G       5F      �� *
ProcName+5G        5H      $	 80 5I      $
 UserId��5K       5J      �� *UserId+5K        5L      $		 100 5M      $
 Action��5O       5N      �� *Action+5O        5P      $		 100 5Q      $
 Table��5S       5R      �� *	TableName+5S        5T      $	 80 5U      $
 RecordId��5W       5V      �� *
RecordId+5W        5X      $		 200 5Y      $
 OldData��5[       5Z      �� *	OldData+ �� 	Converter# [  5[        5\      $		 200 5]      $
 NewData��5_       5^      �� *	NewData+# [  5_        5`      $		 140 5a      $
 	ChangedAt��5c       5b      �� *	ChangedAt+5c      5e      5f      5g      
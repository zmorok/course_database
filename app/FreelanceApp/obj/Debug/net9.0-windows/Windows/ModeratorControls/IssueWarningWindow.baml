   M S B A M L   `   `   `  ����G  CFreelanceApp, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null_4clr-namespace:FreelanceApp.Windows.ModeratorControls&FreelanceApp.Windows.ModeratorControls  5      ?    9FreelanceApp.Windows.ModeratorControls.IssueWarningWindow   5      W SPresentationCore, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     5      R NSystem.Xaml, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      @d2http://schemas.microsoft.com/expression/blend/2008     5      Flocal4clr-namespace:FreelanceApp.Windows.ModeratorControls     5      Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5        � Title$  IssueWarningWindow��5      $	��800��5	      $	��450��5
      .��5      � $��10q�6    � RowDefinitions 5   
   �� 5      $
��Auto �6   �� 5      $��* �6   �� 5      $
��Auto �6   .+�5   
   �� $��16(�5      $
��Bold"�5      $5��/Параметры предупреждения��5      �� 5   
   $��1��6   $��	0,10,0,10q�6"   .+�5      �� Сообщение:6$   �� 5      -   5         ��Name$ MsgBox��5      $��80��5       �� TextWrapping$
 Wrap=�5      �� 5      $��0,10,0,0q�6    �� Orientation$ 
Horizontal=�6+   .+�5       �� $��Center=�6   $��Срок (дней):��67   �� 5!      -   5        $ DaysBox��5"      $��40��5#      $��5,0,20,0q�5$      $��7��5%      5&      5'      �� 5)   
   $��2��5*      $��Right=�5+      $ 
Horizontal=�5,      .+�5-      �� -   5        $��80��5.      $��0,0,10,0q�5/      $��OK��51       �� 	IsDefault$
 True��52      �� 53      -   5        $��80��54      $��Отмена��56       �� IsCancel$
 True��57      58      59      5:      
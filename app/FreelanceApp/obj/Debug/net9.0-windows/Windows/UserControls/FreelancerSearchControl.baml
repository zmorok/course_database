   M S B A M L   `   `   `  ����>  :DAL, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null@+clr-namespace:DAL.Models.Views;assembly=DALDAL.Models.Views  5       FreelanceApp?   9FreelanceApp.Windows.UserControls.FreelancerSearchControl   5      W SPresentationCore, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     5      R NSystem.Xaml, Version=9.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      <data+clr-namespace:DAL.Models.Views;assembly=DAL     5      $
��Auto��5      $
��Auto��5        � 	Resources  5	         BoolToVisibility��%   &	        �� 5
   
   6'   5      .��5      � $��10q�6    � RowDefinitions 5   
   �� 5      $
��Auto �6   �� 5      $��* �6   �� 5      $
��Auto �6   .+�5   
   ��  �� Orientation$ 
Horizontal=�6   .+�5      �� -   5         ��Name$ 	SearchBox��5      $	��250��5      $��0,0,6,0q�5      $�� ��5      �� 5      -   5        $��
Найти��5   *   5      �� 5    
   -   5         ��Name$ FreelancersList��5!      $��1��5"       �� SelectionMode$ Single=�5$      ��5%      �� 5&      .R�5'      �� $��3q�5(       �� Padding$ 6q�5)      
�������$��1q�5+      ._�5,      �� .+�5-      �� $
��Bold"�6(   ��6:   �� *
FullName+�� 5.      $��11(�6(   
��������� 5/   "   $�Скиллы: ��6&    �� 50   "   �6&   �� *SkillsPreview+51      �� 52      -   5        $	��140��53   !   $��0,4,0,0q�54   !   $#��Выберите проект��56   !   {�57   !   �� *	CanInvite+58      59      5:      5<      �� 5?   
   $��2��5@      $ 6q�5A      ���#ccc$��1q�5C      y�5D      ��  �� ElementName$ ProjectsCombo�� �� Path$ HasItems�	 �� 	Converter#	 [  ._�5E      �� $ 
Horizontal=�6   .+�5F      �� $��Center=�6   $%��Выберите проект: ��67   �� 5G      -   5        
 ��Name$
 ProjectsCombo��5H      $	��250��5I       �� DisplayMemberPath$ Title��5J      �� 5K      -   5        $��6,0,0,0q�5L      $��Отправить��5N      5O      5P      5Q      5R      
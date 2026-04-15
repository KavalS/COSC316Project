# COSC316Project
Okanagan College BCIS Program
Winter 2026
Project Repo for COSC 316 course by Kavaljeet Singh

Last update: March 6, 2026 4:00 PM

Initial ideas for the project:

1. A mobile application to journal and track daily habits for self-improvement


App structure:

HabitFlow/
├── HabitFlow.xcodeproj/
│   └── project.pbxproj
└── HabitFlow/
    ├── HabitFlowApp.swift       ← App entry + SwiftData container
    ├── Models/
    │   ├── Habit.swift          ← Model class #1
    │   └── HabitCompletion.swift ← Model class #2
    └── Views/
        ├── ContentView.swift     ← Tab navigator (View #1)
        ├── TodayView.swift       ← Daily tracking (View #2)
        ├── CalendarView.swift    ← Calendar heatmap (View #3)
        ├── StatsView.swift       ← Analytics & streaks (View #4)
        └── HabitsManageView.swift ← Add/delete habits (View #5)


Legacy:

HabitFlow allows its users to track and build daily habits to promote a healthier mindset and lifestyle. For future development it would be nice add a feature of community sharing where multiple app users can post and share their progress among each other. 


Todo:

- Fix date and time box
- Decrease color selection for new habits
  




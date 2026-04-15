import SwiftUI
import SwiftData

// MARK: - Global Theme
struct Theme {
    // Backgrounds
    static let background   = Color(hex: "F5F0E8") ?? .white   // warm cream
    static let surface      = Color(hex: "EDE8DC") ?? .white   // slightly darker cream
    static let card         = Color(hex: "E8E0CF") ?? .white   // card surface

    // Text
    static let textPrimary   = Color(hex: "2C1A0E") ?? .black  // dark espresso
    static let textSecondary = Color(hex: "6B4F3A") ?? .gray   // medium brown
    static let textMuted     = Color(hex: "A08060") ?? .gray   // muted tan

    // Accent / action
    static let accent        = Color(hex: "7A4F2D") ?? .brown  // warm brown
    static let accentLight   = Color(hex: "C49A6C") ?? .brown  // golden tan
    static let accentMuted   = Color(hex: "D4B896") ?? .brown  // soft sand

    // Earthy status colours
    static let success       = Color(hex: "5C7A4A") ?? .green  // sage green
    static let warning       = Color(hex: "C47C2B") ?? .orange // amber
    static let danger        = Color(hex: "8B3A2A") ?? .red    // terracotta

    // Stroke / divider
    static let border        = Color(hex: "C8B89A") ?? .gray   // warm beige border
    static let divider       = Color(hex: "D4C4A8") ?? .gray
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today",    systemImage: "sun.max.fill") }
                .tag(0)
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(1)
            StatsView()
                .tabItem { Label("Stats",    systemImage: "chart.bar.fill") }
                .tag(2)
            HabitsManageView()
                .tabItem { Label("Manage",   systemImage: "slider.horizontal.3") }
                .tag(3)
        }
        .tint(Theme.accent)
    }
}
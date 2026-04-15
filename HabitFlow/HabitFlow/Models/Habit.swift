import SwiftUI
import SwiftData

/// Model class representing a daily habit
@Model
final class Habit {
    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var createdAt: Date
    var order: Int

    /// Relationship to all completions for this habit
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(name: String, emoji: String, colorHex: String, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = Date()
        self.order = order
    }

    // MARK: - Computed Properties

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    /// Current streak: consecutive days up to and including today
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        // If not completed today, start checking from yesterday
        if !isCompleted(on: today) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        while isCompleted(on: checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    /// Longest ever streak
    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = completions
            .map { calendar.startOfDay(for: $0.completedAt) }
            .sorted()

        guard !sortedDates.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<sortedDates.count {
            let prev = sortedDates[i - 1]
            let curr = sortedDates[i]
            if let diff = calendar.dateComponents([.day], from: prev, to: curr).day, diff == 1 {
                current += 1
                longest = max(longest, current)
            } else if let diff = calendar.dateComponents([.day], from: prev, to: curr).day, diff > 1 {
                current = 1
            }
        }
        return longest
    }

    /// Total number of completions
    var totalCompletions: Int {
        completions.count
    }

    /// Completion rate over the last 30 days
    var last30DaysRate: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else { return 0 }

        var completedDays = 0
        var checkDate = startDate
        while checkDate <= today {
            if isCompleted(on: checkDate) { completedDays += 1 }
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
        }
        return Double(completedDays) / 30.0
    }

    func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        return completions.contains {
            calendar.startOfDay(for: $0.completedAt) == target
        }
    }

    func completion(on date: Date) -> HabitCompletion? {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        return completions.first {
            calendar.startOfDay(for: $0.completedAt) == target
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - Preset Habits
extension Habit {
    static let presets: [(name: String, emoji: String, colorHex: String)] = [
        ("Morning Run", "🏃", "FF6B6B"),
        ("Read", "📚", "4ECDC4"),
        ("Meditate", "🧘", "A8E6CF"),
        ("Drink Water", "💧", "45B7D1"),
        ("Journal", "✍️", "F7DC6F"),
        ("Exercise", "💪", "E74C3C"),
        ("Sleep Early", "😴", "9B59B6"),
        ("Cook Healthy", "🥗", "2ECC71"),
        ("No Phone", "📵", "E67E22"),
        ("Practice Skill", "🎯", "3498DB"),
    ]
}

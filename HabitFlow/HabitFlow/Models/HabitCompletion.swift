import SwiftUI
import SwiftData

/// Model class representing a single completion record for a habit on a given day
@Model
final class HabitCompletion {
    var id: UUID
    var completedAt: Date
    var note: String?

    /// Back-reference to the owning habit
    var habit: Habit?

    init(completedAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.completedAt = completedAt
        self.note = note
    }

    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: completedAt)
    }
}

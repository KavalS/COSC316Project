import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Habit.order) private var habits: [Habit]

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var currentMonth = Calendar.current.startOfDay(for: Date())
    @State private var slideDir: Int = 0
    private let cal = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    monthHeader
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                        .padding(.bottom, 10)

                    weekdayRow
                        .padding(.horizontal, 18)

                    calendarGrid
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .id(currentMonth)
                        .transition(.asymmetric(
                            insertion: .move(edge: slideDir >= 0 ? .trailing : .leading).combined(with: .opacity),
                            removal:   .move(edge: slideDir >= 0 ? .leading  : .trailing).combined(with: .opacity)
                        ))

                    Divider().overlay(Theme.divider).padding(.top, 14)

                    selectedDayPanel
                        .padding(.horizontal, 18)
                        .padding(.top, 14)

                    Spacer()
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                    slideDir = -1
                    currentMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2).foregroundColor(Theme.accent)
            }
            Spacer()
            VStack(spacing: 1) {
                Text(monthYear(currentMonth))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("\(monthCompletions) completions")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                    slideDir = 1
                    currentMonth = cal.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2).foregroundColor(Theme.accent)
            }
        }
    }

    // MARK: - Weekday Row
    private var weekdayRow: some View {
        HStack {
            ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                Text(d)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Grid
    private var calendarGrid: some View {
        let days = daysInMonth(currentMonth)
        let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(days, id: \.self) { date in
                if let date {
                    CalendarDayCell(
                        date: date,
                        habits: habits,
                        isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                        isToday: cal.isDateInToday(date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                            selectedDate = date
                        }
                    }
                } else {
                    Color.clear.frame(height: 42)
                }
            }
        }
    }

    // MARK: - Day Panel
    private var selectedDayPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDayLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            let done    = habits.filter {  $0.isCompleted(on: selectedDate) }
            let pending = habits.filter { !$0.isCompleted(on: selectedDate) }

            if habits.isEmpty {
                Text("No habits tracked yet")
                    .font(.system(size: 14)).foregroundColor(Theme.textMuted)
            } else {
                ScrollView {
                    VStack(spacing: 7) {
                        ForEach(done) { h in habitChip(h, completed: true) }
                        if cal.isDateInToday(selectedDate) {
                            ForEach(pending) { h in habitChip(h, completed: false) }
                        }
                        if done.isEmpty && !cal.isDateInToday(selectedDate) {
                            Text("Nothing completed on this day")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private func habitChip(_ habit: Habit, completed: Bool) -> some View {
        HStack(spacing: 10) {
            Text(habit.emoji).font(.system(size: 17))
            Text(habit.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(completed ? Theme.textPrimary : Theme.textMuted)
            Spacer()
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(completed ? Theme.success : Theme.border)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(completed ? Theme.success.opacity(0.1) : Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(completed ? Theme.success.opacity(0.3) : Theme.border, lineWidth: 1))
        )
    }

    // MARK: - Helpers
    private func monthYear(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: d)
    }
    private var selectedDayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: selectedDate)
    }
    private var monthCompletions: Int {
        let c = cal.dateComponents([.year,.month], from: currentMonth)
        return habits.reduce(0) { sum, h in
            sum + h.completions.filter {
                let dc = cal.dateComponents([.year,.month], from: $0.completedAt)
                return dc.year == c.year && dc.month == c.month
            }.count
        }
    }
    private func daysInMonth(_ date: Date) -> [Date?] {
        let range = cal.range(of: .day, in: .month, for: date)!
        let first = cal.date(from: cal.dateComponents([.year,.month], from: date))!
        let offset = cal.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: first))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - Day Cell
struct CalendarDayCell: View {
    let date: Date; let habits: [Habit]
    let isSelected: Bool; let isToday: Bool

    private var rate: Double {
        guard !habits.isEmpty else { return 0 }
        return Double(habits.filter { $0.isCompleted(on: date) }.count) / Double(habits.count)
    }
    private var isFuture: Bool { date > Calendar.current.startOfDay(for: Date()) }
    private var dayNum: String { "\(Calendar.current.component(.day, from: date))" }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(isSelected ? Theme.accent : (rate > 0 && !isFuture ? fillColor.opacity(0.18) : Theme.surface))
            if isToday && !isSelected {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(Theme.accent, lineWidth: 1.5)
            }
            VStack(spacing: 2) {
                Text(dayNum)
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundColor(
                        isSelected ? .white :
                        isFuture   ? Theme.textMuted.opacity(0.4) : Theme.textPrimary
                    )
                if rate > 0 && !isFuture {
                    Circle()
                        .fill(isSelected ? Color.white : fillColor)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(height: 42)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
    }

    private var fillColor: Color {
        rate >= 1.0 ? Theme.success :
        rate >= 0.5 ? Theme.warning : Theme.danger
    }
}
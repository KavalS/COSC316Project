import SwiftUI
import SwiftData

// MARK: - View 2: CalendarView
struct CalendarView: View {
    @Query(sort: \Habit.order) private var habits: [Habit]

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var currentMonth = Calendar.current.startOfDay(for: Date())
    @State private var slideDirection: Int = 0  // -1 prev, 1 next

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0F0C29") ?? .black,
                             Color(hex: "302B63") ?? .indigo,
                             Color(hex: "24243E") ?? .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Month header
                    monthHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // Day of week labels
                    weekdayHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    // Calendar grid
                    calendarGrid
                        .padding(.horizontal, 20)
                        .id(currentMonth)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: slideDirection > 0 ? .trailing : .leading)
                                    .combined(with: .opacity),
                                removal: .move(edge: slideDirection > 0 ? .leading : .trailing)
                                    .combined(with: .opacity)
                            )
                        )

                    Divider()
                        .overlay(Color.white.opacity(0.1))
                        .padding(.top, 16)

                    // Selected day detail
                    selectedDayDetail
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    slideDirection = -1
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "6C63FF"))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthYearString(currentMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("\(completionCountForMonth) completions this month")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    slideDirection = 1
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "6C63FF"))
            }
        }
    }

    // MARK: - Weekday Labels
    private var weekdayHeader: some View {
        HStack {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let days = daysInMonth(currentMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        habits: habits,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = date
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
    }

    // MARK: - Selected Day Detail
    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedDateLabel)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            let completedHabits = habits.filter { $0.isCompleted(on: selectedDate) }
            let pendingHabits = habits.filter { !$0.isCompleted(on: selectedDate) }

            if habits.isEmpty {
                Text("No habits tracked yet")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        if !completedHabits.isEmpty {
                            ForEach(completedHabits) { habit in
                                HStack(spacing: 10) {
                                    Text(habit.emoji).font(.system(size: 18))
                                    Text(habit.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(habit.color)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(habit.color.opacity(0.15))
                                )
                            }
                        }

                        if !pendingHabits.isEmpty && calendar.isDateInToday(selectedDate) {
                            ForEach(pendingHabits) { habit in
                                HStack(spacing: 10) {
                                    Text(habit.emoji).font(.system(size: 18))
                                    Text(habit.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                    Spacer()
                                    Image(systemName: "circle")
                                        .foregroundColor(.white.opacity(0.2))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.04))
                                )
                            }
                        }

                        if completedHabits.isEmpty && !calendar.isDateInToday(selectedDate) {
                            Text("No habits completed on this day")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.top, 4)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    // MARK: - Helpers
    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private var selectedDateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: selectedDate)
    }

    private var completionCountForMonth: Int {
        let comps = calendar.dateComponents([.year, .month], from: currentMonth)
        var total = 0
        for habit in habits {
            total += habit.completions.filter {
                let c = calendar.dateComponents([.year, .month], from: $0.completedAt)
                return c.year == comps.year && c.month == comps.month
            }.count
        }
        return total
    }

    private func daysInMonth(_ date: Date) -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekday = calendar.component(.weekday, from: firstDay) - 1

        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(d)
            }
        }
        // Pad to full grid
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let habits: [Habit]
    let isSelected: Bool
    let isToday: Bool

    private var completionRate: Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.isCompleted(on: date) }.count
        return Double(completed) / Double(habits.count)
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var isFuture: Bool {
        date > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        ZStack {
            // Background fill based on completion
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "6C63FF") ?? .purple)
            } else if completionRate > 0 && !isFuture {
                RoundedRectangle(cornerRadius: 10)
                    .fill(completionColor.opacity(0.3))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(isToday ? 0.1 : 0.04))
            }

            // Today ring
            if isToday && !isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(hex: "6C63FF") ?? .purple, lineWidth: 1.5)
            }

            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isFuture ? .white.opacity(0.25) : .white)

                // Dot indicators
                if completionRate > 0 && !isFuture {
                    HStack(spacing: 2) {
                        ForEach(0..<min(Int(completionRate * 3) + 1, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? .white : completionColor)
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
        }
        .frame(height: 44)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var completionColor: Color {
        if completionRate >= 1.0 { return Color(hex: "4ECDC4") ?? .green }
        if completionRate >= 0.5 { return Color(hex: "F7DC6F") ?? .yellow }
        return Color(hex: "FF6B6B") ?? .red
    }
}

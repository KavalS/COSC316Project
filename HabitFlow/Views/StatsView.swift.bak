import SwiftUI
import SwiftData

// MARK: - View 3: StatsView
struct StatsView: View {
    @Query(sort: \Habit.order) private var habits: [Habit]

    @State private var animateCharts = false

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

                ScrollView {
                    VStack(spacing: 20) {
                        // Overview cards
                        overviewCards
                            .padding(.top, 8)

                        // Streak leaderboard
                        streakSection

                        // 30-day completion rates
                        completionRateSection

                        // Weekly heatmap
                        weeklyOverviewSection

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateCharts = true
                }
            }
        }
    }

    // MARK: - Overview Cards
    private var overviewCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Best Streak",
                value: "\(overallBestStreak)",
                unit: "days",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "Total Done",
                value: "\(totalCompletions)",
                unit: "times",
                icon: "checkmark.circle.fill",
                color: Color(hex: "4ECDC4") ?? .teal
            )
            StatCard(
                title: "Habits",
                value: "\(habits.count)",
                unit: "/ 10",
                icon: "list.bullet",
                color: Color(hex: "6C63FF") ?? .purple
            )
        }
    }

    // MARK: - Streak Leaderboard
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Current Streaks", icon: "🔥")

            if habits.isEmpty {
                placeholderText("Add habits to see your streaks")
            } else {
                ForEach(habits.sorted { $0.currentStreak > $1.currentStreak }) { habit in
                    StreakBar(habit: habit, maxStreak: maxCurrentStreak, animate: animateCharts)
                }
            }
        }
        .padding(18)
        .background(glassCard)
    }

    // MARK: - Completion Rate Section
    private var completionRateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "30-Day Completion", icon: "📊")

            if habits.isEmpty {
                placeholderText("Add habits to see completion rates")
            } else {
                ForEach(habits.sorted { $0.last30DaysRate > $1.last30DaysRate }) { habit in
                    CompletionRateRow(habit: habit, animate: animateCharts)
                }
            }
        }
        .padding(18)
        .background(glassCard)
    }

    // MARK: - Weekly Overview
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Last 7 Days", icon: "📅")

            let last7 = last7Days()

            // Columns: habits vs days
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(last7, id: \.self) { date in
                        VStack(spacing: 6) {
                            Text(shortDayLabel(date))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))

                            ForEach(habits) { habit in
                                let done = habit.isCompleted(on: date)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(done ? habit.color : Color.white.opacity(0.07))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text(done ? habit.emoji : "")
                                            .font(.system(size: 13))
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: done)
                            }
                        }
                    }
                }
            }

            // Habit legend
            VStack(alignment: .leading, spacing: 4) {
                ForEach(habits) { habit in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(habit.color)
                            .frame(width: 14, height: 14)
                        Text(habit.name)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(glassCard)
    }

    // MARK: - Helpers
    private var overallBestStreak: Int {
        habits.map { $0.longestStreak }.max() ?? 0
    }

    private var totalCompletions: Int {
        habits.reduce(0) { $0 + $1.totalCompletions }
    }

    private var maxCurrentStreak: Int {
        habits.map { $0.currentStreak }.max() ?? 1
    }

    private func last7Days() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private func shortDayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(2))
    }

    private func placeholderText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.4))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 4)
            }
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(color.opacity(0.25), lineWidth: 1)
                )
        )
        .scaleEffect(appear ? 1 : 0.85)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct StreakBar: View {
    let habit: Habit
    let maxStreak: Int
    let animate: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(habit.emoji)
                .font(.system(size: 18))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(habit.currentStreak) days")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(
                                width: animate ? geo.size.width * ratio : 0,
                                height: 6
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private var ratio: CGFloat {
        guard maxStreak > 0 else { return 0 }
        return min(CGFloat(habit.currentStreak) / CGFloat(maxStreak), 1.0)
    }
}

struct CompletionRateRow: View {
    let habit: Habit
    let animate: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(habit.emoji)
                .font(.system(size: 18))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(habit.last30DaysRate * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(habit.color)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(habit.color)
                            .frame(
                                width: animate ? geo.size.width * habit.last30DaysRate : 0,
                                height: 6
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: animate)
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Habit.order) private var habits: [Habit]
    @State private var animated = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        overviewCards.padding(.top, 4)
                        streakSection
                        completionSection
                        weekSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(0.2)) { animated = true }
            }
        }
    }

    // MARK: - Overview Cards
    private var overviewCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "Best Streak",     value: "\(bestStreak)",      unit: "days",  icon: "flame.fill",           color: Theme.warning)
            StatCard(title: "Total Done",      value: "\(totalCompletions)",unit: "times", icon: "checkmark.circle.fill", color: Theme.success)
            StatCard(title: "Habits",          value: "\(habits.count)",    unit: "/ 10",  icon: "list.bullet",           color: Theme.accent)
        }
    }

    // MARK: - Streak Section
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Current Streaks", icon: "🔥")
            if habits.isEmpty {
                placeholder("Add habits to see your streaks")
            } else {
                ForEach(habits.sorted { $0.currentStreak > $1.currentStreak }) { h in
                    StreakBar(habit: h, maxStreak: maxStreak, animate: animated)
                }
            }
        }
        .padding(16)
        .background(cardBG)
    }

    // MARK: - Completion Section
    private var completionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("30-Day Completion", icon: "📊")
            if habits.isEmpty {
                placeholder("Add habits to see completion rates")
            } else {
                ForEach(habits.sorted { $0.last30DaysRate > $1.last30DaysRate }) { h in
                    CompletionRateRow(habit: h, animate: animated)
                }
            }
        }
        .padding(16)
        .background(cardBG)
    }

    // MARK: - Week Section
    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Last 7 Days", icon: "📅")
            let days = last7()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { date in
                        VStack(spacing: 6) {
                            Text(shortDay(date))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                            ForEach(habits) { h in
                                let done = h.isCompleted(on: date)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(done ? h.color.opacity(0.7) : Theme.surface)
                                    .frame(width: 30, height: 30)
                                    .overlay(Text(done ? h.emoji : "").font(.system(size: 13)))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(done ? h.color : Theme.border, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            // Legend
            VStack(alignment: .leading, spacing: 4) {
                ForEach(habits) { h in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3).fill(h.color)
                            .frame(width: 12, height: 12)
                        Text(h.name)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(cardBG)
    }

    // MARK: - Helpers
    private var bestStreak: Int    { habits.map { $0.longestStreak }.max() ?? 0 }
    private var totalCompletions: Int { habits.reduce(0) { $0 + $1.totalCompletions } }
    private var maxStreak: Int     { habits.map { $0.currentStreak }.max() ?? 1 }

    private func last7() -> [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }
    }
    private func shortDay(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return String(f.string(from: d).prefix(2))
    }
    private func placeholder(_ t: String) -> some View {
        Text(t).font(.system(size: 13)).foregroundColor(Theme.textMuted)
            .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 6)
    }
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Text(icon)
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.textPrimary)
        }
    }
    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String; let value: String; let unit: String
    let icon: String;  let color: Color
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            HStack(alignment: .bottom, spacing: 2) {
                Text(value).font(.system(size: 24, weight: .bold)).foregroundColor(Theme.textPrimary)
                Text(unit).font(.system(size: 11)).foregroundColor(Theme.textMuted).padding(.bottom, 3)
            }
            Text(title).font(.system(size: 11)).foregroundColor(Theme.textMuted)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
        )
        .scaleEffect(appeared ? 1 : 0.88).opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Streak Bar
struct StreakBar: View {
    let habit: Habit; let maxStreak: Int; let animate: Bool
    var body: some View {
        HStack(spacing: 10) {
            Text(habit.emoji).font(.system(size: 17)).frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.name).font(.system(size: 13, weight: .medium)).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("\(habit.currentStreak)d").font(.system(size: 12)).foregroundColor(Theme.warning)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Theme.border).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4).fill(Theme.warning)
                            .frame(width: animate ? g.size.width * ratio : 0, height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animate)
                    }
                }.frame(height: 6)
            }
        }
    }
    private var ratio: CGFloat { maxStreak > 0 ? min(CGFloat(habit.currentStreak) / CGFloat(maxStreak), 1) : 0 }
}

// MARK: - Completion Rate Row
struct CompletionRateRow: View {
    let habit: Habit; let animate: Bool
    var body: some View {
        HStack(spacing: 10) {
            Text(habit.emoji).font(.system(size: 17)).frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.name).font(.system(size: 13, weight: .medium)).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("\(Int(habit.last30DaysRate * 100))%").font(.system(size: 12)).foregroundColor(Theme.accent)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Theme.border).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4).fill(Theme.accent)
                            .frame(width: animate ? g.size.width * habit.last30DaysRate : 0, height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: animate)
                    }
                }.frame(height: 6)
            }
        }
    }
}
import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var habits: [Habit]

    @State private var showAddHabit = false
    @State private var celebrationHabit: Habit?
    @State private var headerAppeared = false

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var completedToday: Int { habits.filter { $0.isCompleted(on: today) }.count }
    private var progress: Double { habits.isEmpty ? 0 : Double(completedToday) / Double(habits.count) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                            .opacity(headerAppeared ? 1 : 0)
                            .offset(y: headerAppeared ? 0 : 16)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.4)) { headerAppeared = true }
                            }

                        if habits.isEmpty {
                            emptyState
                        } else {
                            habitList
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }

                if let habit = celebrationHabit {
                    CelebrationOverlay(habit: habit) {
                        withAnimation { celebrationHabit = nil }
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddHabit = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.accent)
                    }
                    .disabled(habits.count >= 10)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(todayLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showAddHabit) { AddHabitView() }
        }
    }

    // MARK: - Header
    private var headerCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(greetingText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                    Text(motivationalText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Theme.accentMuted.opacity(0.4))
                        .frame(width: 54, height: 54)
                    Text("\(completedToday)/\(habits.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.border)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.accent)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border, lineWidth: 1))
        )
    }

    // MARK: - Habit List
    private var habitList: some View {
        LazyVStack(spacing: 10) {
            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(habit: habit, onToggle: { toggleHabit(habit) })
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8)
                        .delay(Double(index) * 0.04), value: habits.count)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🌱")
                .font(.system(size: 52))
                .padding(.top, 50)
            Text("No habits yet")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text("Tap + to add your first habit\n(up to 10 habits)")
                .font(.system(size: 14))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers
    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning ☀️" }
        if h < 17 { return "Good afternoon 🌤" }
        return "Good evening 🌙"
    }

    private var todayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private var motivationalText: String {
        guard !habits.isEmpty else { return "Let's build something great" }
        switch completedToday {
        case 0:           return "Ready when you are 💪"
        case habits.count: return "Perfect day — all done! 🏆"
        default:          return "\(habits.count - completedToday) left for today"
        }
    }

    private func toggleHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if habit.isCompleted(on: today) {
                if let c = habit.completion(on: today) { modelContext.delete(c) }
            } else {
                let c = HabitCompletion(completedAt: today)
                c.habit = habit
                modelContext.insert(c)
                try? modelContext.save()
                celebrationHabit = habit
            }
        }
        try? modelContext.save()
    }
}

// MARK: - Habit Row
struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    @State private var checkScale: CGFloat = 1.0
    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var isCompleted: Bool { habit.isCompleted(on: today) }

    // Map habit's stored colour to an earthy tint for the row
    private var rowTint: Color { habit.color }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { checkScale = 1.35 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { checkScale = 1.0 }
            }
            onToggle()
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCompleted ? rowTint.opacity(0.25) : Theme.surface)
                        .frame(width: 46, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(isCompleted ? rowTint.opacity(0.5) : Theme.border, lineWidth: 1)
                        )
                    Text(habit.emoji).font(.system(size: 22))
                }
                .animation(.easeInOut(duration: 0.25), value: isCompleted)

                // Name + streak
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    if habit.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.warning)
                            Text("\(habit.currentStreak) day streak")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                    } else {
                        Text("Start your streak today")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textMuted.opacity(0.7))
                    }
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .fill(isCompleted ? rowTint : Color.clear)
                        .frame(width: 28, height: 28)
                    Circle()
                        .strokeBorder(isCompleted ? rowTint : Theme.border, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(checkScale)
                .animation(.easeInOut(duration: 0.2), value: isCompleted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isCompleted ? rowTint.opacity(0.08) : Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isCompleted ? rowTint.opacity(0.3) : Theme.border, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.25), value: isCompleted)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    let habit: Habit
    let dismiss: () -> Void

    @State private var particles: [ParticleData] = []
    @State private var cardScale: CGFloat = 0.7
    @State private var cardOpacity: Double = 0

    private let earthyConfetti: [Color] = [
        Theme.accent, Theme.accentLight, Theme.success,
        Theme.warning, Theme.accentMuted, Theme.danger
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea().onTapGesture { dismiss() }

            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }

            VStack(spacing: 10) {
                Text(habit.emoji).font(.system(size: 64))
                Text("Great work!").font(.system(size: 22, weight: .bold)).foregroundColor(Theme.textPrimary)
                Text("\(habit.name) done").font(.system(size: 15)).foregroundColor(Theme.textSecondary)
                if habit.currentStreak > 0 {
                    Text("🔥 \(habit.currentStreak) day streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.warning)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Theme.background)
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.border, lineWidth: 1.5))
                    .shadow(color: Theme.accent.opacity(0.15), radius: 20, y: 6)
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            spawnParticles()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                cardScale = 1.0; cardOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
        }
    }

    private func spawnParticles() {
        particles = (0..<24).map { i in
            ParticleData(id: i,
                         x: CGFloat.random(in: -140...140),
                         y: CGFloat.random(in: -260...260),
                         size: CGFloat.random(in: 5...11),
                         color: earthyConfetti.randomElement() ?? Theme.accent,
                         opacity: Double.random(in: 0.7...1.0))
        }
        withAnimation(.easeOut(duration: 1.4)) {
            particles = particles.map { p in
                var u = p; u.x *= 2.2; u.y *= 2.2; u.opacity = 0; return u
            }
        }
    }
}

struct ParticleData: Identifiable {
    let id: Int
    var x, y, size: CGFloat
    var color: Color
    var opacity: Double
}
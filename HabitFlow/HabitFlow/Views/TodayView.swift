import SwiftUI
import SwiftData

// MARK: - View 1: TodayView
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var habits: [Habit]

    @State private var showAddHabit = false
    @State private var celebrationHabit: Habit?
    @State private var headerScale: CGFloat = 0.9
    @State private var headerOpacity: Double = 0

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    private var completedToday: Int {
        habits.filter { $0.isCompleted(on: today) }.count
    }

    private var progress: Double {
        habits.isEmpty ? 0 : Double(completedToday) / Double(habits.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "0F0C29") ?? .black,
                             Color(hex: "302B63") ?? .indigo,
                             Color(hex: "24243E") ?? .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header card
                        headerCard
                            .scaleEffect(headerScale)
                            .opacity(headerOpacity)
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    headerScale = 1.0
                                    headerOpacity = 1.0
                                }
                            }

                        // Habit list
                        if habits.isEmpty {
                            emptyState
                        } else {
                            habitList
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                // Celebration overlay
                if let habit = celebrationHabit {
                    CelebrationOverlay(habit: habit) {
                        withAnimation { celebrationHabit = nil }
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "6C63FF"))
                    }
                    .disabled(habits.count >= 10)
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView()
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(todayLabel)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                // Completion badge
                ZStack {
                    Circle()
                        .fill(Color(hex: "6C63FF")?.opacity(0.3) ?? Color.purple.opacity(0.3))
                        .frame(width: 56, height: 56)
                    Text("\(completedToday)/\(habits.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6C63FF") ?? .purple,
                                         Color(hex: "FF6584") ?? .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 10)

            Text(motivationalText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Habit List
    private var habitList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(habit: habit, onToggle: { toggleHabit(habit) })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05),
                               value: habits.count)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🌱")
                .font(.system(size: 60))
            Text("No habits yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Text("Tap + to add your first habit\n(up to 10 habits)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Helpers
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning ☀️" }
        if hour < 17 { return "Good afternoon 🌤" }
        return "Good evening 🌙"
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var motivationalText: String {
        switch completedToday {
        case 0: return "Let's get started! You've got this 💪"
        case habits.count: return "Perfect day! All habits completed! 🏆"
        default: return "\(habits.count - completedToday) habit\(habits.count - completedToday == 1 ? "" : "s") remaining"
        }
    }

    private func toggleHabit(_ habit: Habit) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if habit.isCompleted(on: today) {
                // Remove completion
                if let existing = habit.completion(on: today) {
                    modelContext.delete(existing)
                }
            } else {
                // Add completion + celebrate
                let completion = HabitCompletion(completedAt: today)
                completion.habit = habit
                modelContext.insert(completion)
                try? modelContext.save()
                celebrationHabit = habit
            }
        }
        try? modelContext.save()
    }
}

// MARK: - Habit Row View
struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    @State private var isPressed = false
    @State private var checkmarkScale: CGFloat = 1.0

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var isCompleted: Bool { habit.isCompleted(on: today) }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                checkmarkScale = 1.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
            }
            onToggle()
        }) {
            HStack(spacing: 16) {
                // Emoji + color indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(habit.color.opacity(isCompleted ? 1.0 : 0.2))
                        .frame(width: 48, height: 48)
                        .animation(.easeInOut(duration: 0.3), value: isCompleted)
                    Text(habit.emoji)
                        .font(.system(size: 22))
                }

                // Name + streak
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 4) {
                        if habit.currentStreak > 0 {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("\(habit.currentStreak) day streak")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                        } else {
                            Text("Start your streak today!")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .strokeBorder(
                            isCompleted ? habit.color : Color.white.opacity(0.25),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)
                        .animation(.easeInOut(duration: 0.25), value: isCompleted)

                    if isCompleted {
                        Circle()
                            .fill(habit.color)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(checkmarkScale)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isCompleted
                          ? habit.color.opacity(0.12)
                          : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                isCompleted ? habit.color.opacity(0.4) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.3), value: isCompleted)
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
    @State private var emojiScale: CGFloat = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Particles
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }

            // Center card
            VStack(spacing: 12) {
                Text(habit.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(emojiScale)
                Text("Well done! 🎉")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                Text("\(habit.name) completed!")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(textOpacity)
                if habit.currentStreak > 0 {
                    Text("🔥 \(habit.currentStreak) day streak!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                        .opacity(textOpacity)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A1A2E") ?? .black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(habit.color.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .shadow(color: habit.color.opacity(0.4), radius: 24)
        }
        .onAppear {
            spawnParticles()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                emojiScale = 1.0
                textOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { dismiss() }
        }
    }

    private func spawnParticles() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        particles = (0..<30).map { i in
            ParticleData(
                id: i,
                x: CGFloat.random(in: -160...160),
                y: CGFloat.random(in: -280...280),
                size: CGFloat.random(in: 4...12),
                color: colors.randomElement() ?? .yellow,
                opacity: Double.random(in: 0.6...1.0)
            )
        }
        withAnimation(.easeOut(duration: 1.5)) {
            particles = particles.map { p in
                var updated = p
                updated.x *= 2.5
                updated.y *= 2.5
                updated.opacity = 0
                return updated
            }
        }
    }
}

struct ParticleData: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

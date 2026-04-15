import SwiftUI
import SwiftData

// MARK: - View 4: HabitsManageView
struct HabitsManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var habits: [Habit]

    @State private var showAddHabit = false
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirm = false

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
                    VStack(spacing: 16) {
                        // Capacity indicator
                        capacityBar
                            .padding(.top, 8)

                        if habits.isEmpty {
                            emptyState
                        } else {
                            habitCards
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                }

                // Floating add button
                if habits.count < 10 {
                    VStack {
                        Spacer()
                        Button {
                            showAddHabit = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Add Habit")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "6C63FF") ?? .purple,
                                                     Color(hex: "FF6584") ?? .pink],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "6C63FF")?.opacity(0.5) ?? .purple.opacity(0.5),
                                    radius: 12, y: 4)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Manage Habits")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddHabit) {
                AddHabitView()
            }
            .alert("Delete Habit?", isPresented: $showDeleteConfirm, presenting: habitToDelete) { habit in
                Button("Delete", role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        modelContext.delete(habit)
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { habit in
                Text("This will delete '\(habit.name)' and all its completion history.")
            }
        }
    }

    // MARK: - Capacity Bar
    private var capacityBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Habit Slots")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(habits.count) / 10")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6C63FF") ?? .purple,
                                         Color(hex: "FF6584") ?? .pink],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (Double(habits.count) / 10.0), height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: habits.count)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Habit Cards
    private var habitCards: some View {
        LazyVStack(spacing: 12) {
            ForEach(habits) { habit in
                HabitManageCard(habit: habit) {
                    habitToDelete = habit
                    showDeleteConfirm = true
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("✨")
                .font(.system(size: 56))
                .padding(.top, 40)
            Text("No habits yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Text("Add up to 10 daily habits to track")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Habit Manage Card
struct HabitManageCard: View {
    let habit: Habit
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Color + emoji
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(habit.color.opacity(0.25))
                    .frame(width: 52, height: 52)
                Text(habit.emoji)
                    .font(.system(size: 24))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 12) {
                    Label("\(habit.currentStreak)d streak", systemImage: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Label("\(habit.totalCompletions) total", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(habit.color)
                }
            }

            Spacer()

            // Delete button
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(habit.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Add Habit View (Sheet)
struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.order) private var existingHabits: [Habit]

    @State private var name = ""
    @State private var selectedEmoji = "⭐️"
    @State private var selectedColorHex = "6C63FF"
    @State private var usePreset = true
    @State private var selectedPreset: Int? = nil
    @State private var formOpacity: Double = 0
    @State private var formOffset: CGFloat = 40

    private let colorPalette = [
        "FF6B6B", "FF6584", "FFA07A", "F7DC6F",
        "A8E6CF", "4ECDC4", "45B7D1", "6C63FF",
        "9B59B6", "E74C3C", "2ECC71", "E67E22"
    ]

    private let emojis = [
        "⭐️","🏃","📚","🧘","💧","✍️","💪","😴",
        "🥗","📵","🎯","🎸","🎨","🌿","🦷","🧠",
        "🏋️","🚴","🤸","☕️","🫁","💊","📱","🛌"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F0C29")?.ignoresSafeArea() ?? Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preset picker
                        presetSection

                        // Custom section
                        if !usePreset || selectedPreset == nil {
                            customSection
                        }

                        // Preview
                        previewCard

                        // Add button
                        addButton
                    }
                    .padding(20)
                    .opacity(formOpacity)
                    .offset(y: formOffset)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            formOpacity = 1
                            formOffset = 0
                        }
                    }
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Preset Section
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ADD")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .kerning(1.2)

            let available = Habit.presets.filter { preset in
                !existingHabits.contains { $0.name == preset.name }
            }

            if available.isEmpty {
                Text("All presets already added!")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(available.enumerated()), id: \.offset) { idx, preset in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPreset = idx
                                name = preset.name
                                selectedEmoji = preset.emoji
                                selectedColorHex = preset.colorHex
                                usePreset = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(preset.emoji)
                                Text(preset.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPreset == idx
                                          ? (Color(hex: preset.colorHex)?.opacity(0.3) ?? Color.purple.opacity(0.3))
                                          : Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                selectedPreset == idx
                                                    ? (Color(hex: preset.colorHex) ?? .purple)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                        }
                    }
                }
            }

            Button {
                withAnimation {
                    usePreset = false
                    selectedPreset = nil
                    name = ""
                }
            } label: {
                Label("Custom habit", systemImage: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "6C63FF") ?? .purple)
            }
        }
        .padding(18)
        .background(glassCard)
    }

    // MARK: - Custom Section
    private var customSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CUSTOM HABIT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .kerning(1.2)

            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                TextField("e.g. Morning Walk", text: $name)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                    )
            }

            // Emoji picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Emoji")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button {
                            withAnimation(.spring(response: 0.2)) { selectedEmoji = emoji }
                        } label: {
                            Text(emoji)
                                .font(.system(size: 20))
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedEmoji == emoji
                                              ? Color.white.opacity(0.2) : Color.clear)
                                )
                        }
                    }
                }
            }

            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                HStack(spacing: 10) {
                    ForEach(colorPalette, id: \.self) { hex in
                        Button {
                            withAnimation(.spring(response: 0.2)) { selectedColorHex = hex }
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .purple)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColorHex == hex ? 2.5 : 0)
                                )
                                .scaleEffect(selectedColorHex == hex ? 1.2 : 1.0)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(glassCard)
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill((Color(hex: selectedColorHex) ?? .purple).opacity(0.25))
                    .frame(width: 46, height: 46)
                Text(selectedEmoji)
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Habit name" : name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(name.isEmpty ? .white.opacity(0.3) : .white)
                Text("0 day streak")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Circle()
                .strokeBorder(Color(hex: selectedColorHex) ?? .purple, lineWidth: 2)
                .frame(width: 26, height: 26)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder((Color(hex: selectedColorHex) ?? .purple).opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            let habit = Habit(
                name: name.trimmingCharacters(in: .whitespaces),
                emoji: selectedEmoji,
                colorHex: selectedColorHex,
                order: existingHabits.count
            )
            modelContext.insert(habit)
            try? modelContext.save()
            dismiss()
        } label: {
            Text("Add Habit")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            name.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.white.opacity(0.15)
                            : LinearGradient(
                                colors: [Color(hex: "6C63FF") ?? .purple,
                                         Color(hex: "FF6584") ?? .pink],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                )
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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

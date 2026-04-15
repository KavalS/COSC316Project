import SwiftUI
import SwiftData

struct HabitsManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var habits: [Habit]

    @State private var showAdd = false
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        capacityBar.padding(.top, 4)

                        if habits.isEmpty { emptyState }
                        else { habitCards }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 18)
                }

                if habits.count < 10 {
                    VStack {
                        Spacer()
                        Button { showAdd = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus").font(.system(size: 15, weight: .semibold))
                                Text("Add Habit").font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28).padding(.vertical, 14)
                            .background(Capsule().fill(Theme.accent))
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, y: 4)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Manage Habits")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAdd) { AddHabitView() }
            .alert("Delete Habit?", isPresented: $showDeleteConfirm, presenting: habitToDelete) { h in
                Button("Delete", role: .destructive) {
                    withAnimation { modelContext.delete(h); try? modelContext.save() }
                }
                Button("Cancel", role: .cancel) {}
            } message: { h in
                Text("This will permanently delete '\(h.name)' and all its history.")
            }
        }
    }

    // MARK: - Capacity Bar
    private var capacityBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Habit Slots").font(.system(size: 13)).foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(habits.count) / 10").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.textPrimary)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(Theme.border).frame(height: 7)
                    RoundedRectangle(cornerRadius: 5).fill(Theme.accent)
                        .frame(width: g.size.width * (Double(habits.count) / 10.0), height: 7)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: habits.count)
                }
            }
            .frame(height: 7)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
        )
    }

    // MARK: - Habit Cards
    private var habitCards: some View {
        LazyVStack(spacing: 10) {
            ForEach(habits) { h in
                HabitManageCard(habit: h) {
                    habitToDelete = h; showDeleteConfirm = true
                }
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("✨").font(.system(size: 50)).padding(.top, 40)
            Text("No habits yet").font(.system(size: 19, weight: .semibold)).foregroundColor(Theme.textPrimary)
            Text("Add up to 10 daily habits to track")
                .font(.system(size: 14)).foregroundColor(Theme.textMuted)
        }
    }
}

// MARK: - Habit Manage Card
struct HabitManageCard: View {
    let habit: Habit; let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(habit.color.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(habit.color.opacity(0.35), lineWidth: 1))
                Text(habit.emoji).font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.textPrimary)
                HStack(spacing: 12) {
                    Label("\(habit.currentStreak)d", systemImage: "flame.fill")
                        .font(.system(size: 12)).foregroundColor(Theme.warning)
                    Label("\(habit.totalCompletions) total", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12)).foregroundColor(Theme.success)
                }
            }
            Spacer()
            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.danger.opacity(0.75))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
        )
    }
}

// MARK: - Add Habit View
struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.order) private var existingHabits: [Habit]

    @State private var name = ""
    @State private var selectedEmoji = "⭐️"
    @State private var selectedColorHex = "7A4F2D"
    @State private var selectedPreset: Int? = nil
    @State private var formOpacity: Double = 0
    @State private var formOffset: CGFloat = 30

    // Earthy colour palette
    private let colorPalette = [
        "7A4F2D", "C49A6C", "D4B896", "A08060",
        "5C7A4A", "8B6914", "C47C2B", "8B3A2A",
        "6B4F3A", "4A6B5C", "7A6B4A", "5C4A6B"
    ]

    private let emojis = [
        "⭐️","🏃","📚","🧘","💧","✍️","💪","😴",
        "🥗","📵","🎯","🎸","🎨","🌿","🦷","🧠",
        "🏋️","🚴","🤸","☕️","🫁","💊","📱","🛌"
    ]

    private var availablePresets: [(name: String, emoji: String, colorHex: String)] {
        Habit.presets.filter { p in !existingHabits.contains { $0.name == p.name } }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        previewCard.padding(.top, 4)
                        nameField
                        emojiPicker
                        colorPickerSection
                        if !availablePresets.isEmpty { presetPicker }
                        addButton.padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16).padding(.top, 8)
                    .opacity(formOpacity).offset(y: formOffset)
                    .onAppear {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            formOpacity = 1; formOffset = 0
                        }
                    }
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Preview
    private var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill((Color(hex: selectedColorHex) ?? Theme.accent).opacity(0.2))
                    .frame(width: 46, height: 46)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder((Color(hex: selectedColorHex) ?? Theme.accent).opacity(0.4), lineWidth: 1))
                Text(selectedEmoji).font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Habit name" : name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(name.isEmpty ? Theme.textMuted : Theme.textPrimary).lineLimit(1)
                Text("0 day streak").font(.system(size: 12)).foregroundColor(Theme.textMuted)
            }
            Spacer()
            Circle().strokeBorder(Color(hex: selectedColorHex) ?? Theme.accent, lineWidth: 2)
                .frame(width: 24, height: 24)
        }
        .padding(14).background(card)
        .animation(.easeInOut(duration: 0.2), value: selectedEmoji)
        .animation(.easeInOut(duration: 0.2), value: selectedColorHex)
    }

    // MARK: - Name Field
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Habit Name")
            TextField("e.g. Morning Walk", text: $name)
                .font(.system(size: 15)).foregroundColor(Theme.textPrimary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(name.isEmpty ? Theme.border
                                          : (Color(hex: selectedColorHex) ?? Theme.accent).opacity(0.6), lineWidth: 1))
                )
                .submitLabel(.done)
        }
        .padding(14).background(card)
    }

    // MARK: - Emoji Picker
    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Icon")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 8) {
                ForEach(emojis, id: \.self) { e in
                    Button { withAnimation(.spring(response: 0.2)) { selectedEmoji = e } } label: {
                        Text(e).font(.system(size: 21))
                            .frame(maxWidth: .infinity).frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEmoji == e
                                          ? (Color(hex: selectedColorHex) ?? Theme.accent).opacity(0.2)
                                          : Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(selectedEmoji == e
                                                      ? (Color(hex: selectedColorHex) ?? Theme.accent)
                                                      : Color.clear, lineWidth: 1.5))
                            )
                    }
                }
            }
        }
        .padding(14).background(card)
    }

    // MARK: - Colour Picker
    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Colour")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 10) {
                ForEach(colorPalette, id: \.self) { hex in
                    Button { withAnimation(.spring(response: 0.2)) { selectedColorHex = hex } } label: {
                        Circle()
                            .fill(Color(hex: hex) ?? Theme.accent)
                            .frame(height: 32).frame(maxWidth: .infinity)
                            .overlay(Circle().strokeBorder(
                                selectedColorHex == hex ? Theme.textPrimary : Color.clear, lineWidth: 2).padding(2))
                            .scaleEffect(selectedColorHex == hex ? 1.15 : 1.0)
                    }
                }
            }
        }
        .padding(14).background(card)
    }

    // MARK: - Presets
    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Quick Add")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(availablePresets.enumerated()), id: \.offset) { idx, p in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPreset = idx; name = p.name
                            selectedEmoji = p.emoji; selectedColorHex = p.colorHex
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(p.emoji)
                            Text(p.name).font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textPrimary).lineLimit(1)
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPreset == idx ? Theme.accentMuted.opacity(0.3) : Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(selectedPreset == idx ? Theme.accent : Theme.border, lineWidth: 1))
                        )
                    }
                }
            }
        }
        .padding(14).background(card)
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            let h = Habit(name: name.trimmingCharacters(in: .whitespaces),
                          emoji: selectedEmoji, colorHex: selectedColorHex,
                          order: existingHabits.count)
            modelContext.insert(h); try? modelContext.save(); dismiss()
        } label: {
            Text("Add Habit")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(RoundedRectangle(cornerRadius: 13)
                    .fill(name.trimmingCharacters(in: .whitespaces).isEmpty
                          ? Theme.border : Theme.accent))
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        .animation(.easeInOut(duration: 0.2), value: name.isEmpty)
    }

    // MARK: - Helpers
    private func label(_ t: String) -> some View {
        Text(t).font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.textMuted).kerning(0.8).textCase(.uppercase)
    }
    private var card: some View {
        RoundedRectangle(cornerRadius: 14).fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
    }
}
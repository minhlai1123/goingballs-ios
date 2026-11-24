import SwiftUI

/**
 * 40-Level Grid Selection Modal (iOS SwiftUI Implementation)
 * Allows browsing and selecting any of the 40 levels across Easy, Normal, Hard, and Expert
 * 100% Zero-Ads Invariant
 */
struct LevelSelectModal: View {
    let currentLevel: Int
    let onSelectLevel: (Int) -> Void
    let onClose: () -> Void

    @State private var selectedFilter: LevelDifficulty? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var filteredLevels: [Int] {
        (1...40).filter { lvl in
            guard let filter = selectedFilter else { return true }
            return LevelCourseBuilder.getDifficulty(for: lvl) == filter
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    GameAudioManager.shared.playButton()
                    onClose()
                }

            VStack(spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🎮 SELECT LEVEL (1 - 40)")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(Color(hex: 0x0284C7))
                        Text("Pick your favorite track to play!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: 0x64748B))
                    }
                    Spacer()
                    Button(action: {
                        GameAudioManager.shared.playButton()
                        onClose()
                    }) {
                        Text("✕")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0x334155))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: 0xE2E8F0))
                            .clipShape(Circle())
                    }
                }

                // Filter Tabs
                HStack(spacing: 4) {
                    FilterTabButton(title: "ALL", isSelected: selectedFilter == nil, color: Color(hex: 0x0284C7)) {
                        selectedFilter = nil
                    }
                    FilterTabButton(title: "EASY", isSelected: selectedFilter == .easy, color: Color(hex: LevelDifficulty.easy.hexColor)) {
                        selectedFilter = .easy
                    }
                    FilterTabButton(title: "NORM", isSelected: selectedFilter == .normal, color: Color(hex: LevelDifficulty.normal.hexColor)) {
                        selectedFilter = .normal
                    }
                    FilterTabButton(title: "HARD", isSelected: selectedFilter == .hard, color: Color(hex: LevelDifficulty.hard.hexColor)) {
                        selectedFilter = .hard
                    }
                    FilterTabButton(title: "EXP", isSelected: selectedFilter == .expert, color: Color(hex: LevelDifficulty.expert.hexColor)) {
                        selectedFilter = .expert
                    }
                }

                // Scrollable Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredLevels, id: \.self) { lvl in
                            let diff = LevelCourseBuilder.getDifficulty(for: lvl)
                            let diffColor = Color(hex: diff.hexColor)
                            let isCurrent = lvl == currentLevel
                            let name = LevelCourseBuilder.getLevelName(for: lvl)

                            Button(action: {
                                GameAudioManager.shared.playButton()
                                onSelectLevel(lvl)
                            }) {
                                VStack(spacing: 2) {
                                    HStack(spacing: 3) {
                                        Text("\(lvl)")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(isCurrent ? Color(hex: 0xB45309) : Color(hex: 0x1E293B))
                                        Circle()
                                            .fill(diffColor)
                                            .frame(width: 6, height: 6)
                                    }

                                    Text(name)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Color(hex: 0x475569))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(height: 20)

                                    Text(diff.label)
                                        .font(.system(size: 7, weight: .heavy))
                                        .foregroundColor(diffColor)
                                }
                                .padding(4)
                                .frame(maxWidth: .infinity)
                                .frame(height: 66)
                                .background(isCurrent ? Color(hex: 0xFEF3C7) : Color(hex: 0xF8FAFC))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isCurrent ? Color(hex: 0xF59E0B) : diffColor.opacity(0.4), lineWidth: isCurrent ? 2 : 1)
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.96))
            .cornerRadius(22)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: 0x38BDF8), lineWidth: 3))
            .padding(16)
        }
    }
}

private struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            GameAudioManager.shared.playButton()
            action()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(isSelected ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(hex: 0xF1F5F9))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 1))
        }
    }
}

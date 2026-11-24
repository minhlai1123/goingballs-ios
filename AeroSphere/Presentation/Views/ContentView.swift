import SwiftUI

/**
 * AeroSphere 3D Native iOS Main Content View
 * Full 3D Rolling Adventure Gameplay with 40 Progressive Levels, Bright Kid-Friendly Graphics, and Audio
 * 100% Zero-Ads Invariant
 */
struct ContentView: View {
    @State private var currentLevel: Int = 1
    @State private var showPlinko: Bool = false

    var body: some View {
        ZStack {
            if showPlinko {
                PlinkoMinigameView(
                    onContinueNextLevel: { _ in
                        currentLevel = (currentLevel < 40) ? currentLevel + 1 : 1
                        showPlinko = false
                    }
                )
            } else {
                GamePlayView(
                    initialLevel: currentLevel,
                    onSelectLevel: { selected in
                        currentLevel = max(1, min(40, selected))
                    },
                    onOpenPlinko: {
                        showPlinko = true
                    }
                )
                .id(currentLevel) // Triggers fresh level initialization upon level change
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}

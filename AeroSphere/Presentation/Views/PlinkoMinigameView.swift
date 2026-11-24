import SwiftUI

/**
 * 3D Plinko Bonus Minigame (iOS SwiftUI Implementation)
 * Upgraded with Bright, Colorful Carnival Styling & Real Audio SFX for Kids
 * 100% Zero-Ads: Free drops earned by skill, NO "Watch Video for x3" advertisements!
 */
struct PlinkoMinigameView: View {
    let onContinueNextLevel: (Int) -> Void

    @State private var hammerMeter: Double = 10.0
    @State private var isDropping: Bool = false
    @State private var droppedCoinsEarned: Int = 0
    @State private var targetSlot: Int? = nil
    @State private var ballPosition: CGPoint = CGPoint(x: 180, y: 60)

    let slotValues = [10, 50, 100, 50, 10]

    // Pegs layout (Triangle Lattice)
    private var pegs: [CGPoint] {
        var list: [CGPoint] = []
        let rows = 7
        let startY: CGFloat = 120
        let spacingY: CGFloat = 45
        for r in 0..<rows {
            let count = r + 4
            let startX = 170.0 - CGFloat(count - 1) * 22.0
            for c in 0..<count {
                list.append(CGPoint(x: startX + CGFloat(c) * 44.0, y: startY + CGFloat(r) * spacingY))
            }
        }
        return list
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x38BDF8), Color(hex: 0x0284C7), Color(hex: 0x1E3A8A)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Text("🎪 BONUS PLINKO 🎪")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color(hex: 0xFEF08A))
                    Text("Drop the golden ball for free bonus coins!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Piggy Bank Header Box with Hammer Meter
                HStack {
                    Text("🐷 PIGGY BANK")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: 0xEC4899))
                    Spacer()
                    Text("HAMMER: \(Int(hammerMeter))%")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: 0xD97706))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(width: 320)
                .background(Color.white.opacity(0.95))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xFBBF24), lineWidth: 2))

                // Main Plinko Board Canvas
                ZStack {
                    // Board Background
                    Color(hex: 0x0D9488)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: 0xFDE047), lineWidth: 3))

                    Canvas { context, size in
                        let scaleX = size.width / 340.0
                        let scaleY = size.height / 440.0

                        // 1. Draw Pegs
                        for peg in pegs {
                            let p = CGPoint(x: peg.x * scaleX, y: peg.y * scaleY)
                            context.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)), with: .color(Color(hex: 0xFDE047)))
                            context.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 4, width: 4, height: 4)), with: .color(.white))
                        }

                        // 2. Draw 2 Skin Pockets in Middle
                        let pocket1 = CGPoint(x: 110 * scaleX, y: 220 * scaleY)
                        let pocket2 = CGPoint(x: 230 * scaleX, y: 220 * scaleY)
                        for p in [pocket1, pocket2] {
                            context.fill(Path(ellipseIn: CGRect(x: p.x - 22, y: p.y - 22, width: 44, height: 44)), with: .color(Color(hex: 0x042F2E)))
                            context.stroke(Path(ellipseIn: CGRect(x: p.x - 22, y: p.y - 22, width: 44, height: 44)), with: .color(Color(hex: 0xFBBF24)), lineWidth: 3)
                            context.fill(Path(ellipseIn: CGRect(x: p.x - 14, y: p.y - 14, width: 28, height: 28)), with: .color(.black))
                        }

                        // 3. Draw Slot Dividers
                        let slotW = (size.width - 20) / 5.0
                        for i in 0...5 {
                            let divX = 10.0 + CGFloat(i) * slotW
                            var linePath = Path()
                            linePath.move(to: CGPoint(x: divX, y: size.height - 65))
                            linePath.addLine(to: CGPoint(x: divX, y: size.height - 8))
                            context.stroke(linePath, with: .color(Color(hex: 0xFDE047)), lineWidth: 3)
                        }

                        // 4. Draw Golden Ball
                        let bp = CGPoint(x: ballPosition.x * scaleX, y: ballPosition.y * scaleY)
                        context.fill(Path(ellipseIn: CGRect(x: bp.x - 14, y: bp.y - 14, width: 28, height: 28)), with: .color(Color(hex: 0xFDE047)))
                        context.stroke(Path(ellipseIn: CGRect(x: bp.x - 14, y: bp.y - 14, width: 28, height: 28)), with: .color(Color(hex: 0xEA580C)), lineWidth: 2)
                        context.fill(Path(ellipseIn: CGRect(x: bp.x - 6, y: bp.y - 8, width: 8, height: 8)), with: .color(.white))
                    }

                    // Slot labels at bottom
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(0..<slotValues.count, id: \.self) { idx in
                                let isSelected = targetSlot == idx
                                Text("+\(slotValues[idx])")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(isSelected ? .white : Color(hex: 0xFDE047))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color(hex: 0xF59E0B) : Color(hex: 0x042F2E).opacity(0.85))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.white : Color(hex: 0x2DD4BF), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                    }
                }
                .frame(width: 320, height: 420)

                // Action Buttons
                if !isDropping && targetSlot == nil {
                    Button(action: startDrop) {
                        Text("⭐ DROP BALL ⭐")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 220, height: 48)
                            .background(Color(hex: 0xF59E0B))
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white, lineWidth: 2))
                    }
                } else if let _ = targetSlot {
                    VStack(spacing: 8) {
                        Text("🎉 YOU WON +\(droppedCoinsEarned) COINS! 🎉")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color(hex: 0xFEF08A))

                        Button(action: {
                            GameAudioManager.shared.playButton()
                            onContinueNextLevel(droppedCoinsEarned)
                        }) {
                            Text("CONTINUE ▶")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 220, height: 46)
                                .background(Color(hex: 0x22C55E))
                                .cornerRadius(23)
                                .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.white, lineWidth: 2))
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func startDrop() {
        GameAudioManager.shared.playButton()
        isDropping = true
        targetSlot = nil

        var x: CGFloat = 160.0 + CGFloat.random(in: -30...30)
        var y: CGFloat = 50.0
        var vx: CGFloat = CGFloat.random(in: -1.5...1.5)
        var vy: CGFloat = 2.0

        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            vy += 0.80 // Gravity
            x += vx
            y += vy

            // Collisions with pegs
            for peg in pegs {
                let dx = x - peg.x
                let dy = y - peg.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < 18.0 {
                    let nx = dx / dist
                    let ny = dy / dist
                    let dot = vx * nx + vy * ny
                    vx = (vx - 1.6 * dot * nx) + CGFloat.random(in: -1.0...1.0)
                    vy = max(1.5, vy - 1.6 * dot * ny)
                    x = peg.x + nx * 18.5
                    y = peg.y + ny * 18.5
                    GameAudioManager.shared.playPlinkoPeg()
                }
            }

            if x < 35 { x = 35; vx = abs(vx) }
            if x > 305 { x = 305; vx = -abs(vx) }

            ballPosition = CGPoint(x: x, y: y)

            if y >= 390 {
                timer.invalidate()
                let slotW: CGFloat = 300.0 / 5.0
                let slotIdx = max(0, min(4, Int((x - 20) / slotW)))
                targetSlot = slotIdx
                droppedCoinsEarned = slotValues[slotIdx]
                hammerMeter = min(100.0, hammerMeter + 10.0)
                GameAudioManager.shared.playCoin()
                isDropping = false
            }
        }
    }
}

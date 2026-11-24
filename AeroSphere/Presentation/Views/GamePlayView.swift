import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var color: Color
    var size: CGFloat
    var rotation: Double
}

struct FloatingPopupText: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    let worldPos: Vector3D
    var alpha: Double = 1.0
    var offsetY: CGFloat = 0.0
}

/**
 * 3D Rolling Adventure Gameplay Screen (iOS SwiftUI Implementation)
 * Featuring Vibrant, Bright, Cheerful Kid-Friendly Graphics & Real Native Sound Effects + BGM + Victory Fanfare
 * 40 Progressive Levels & 100% Zero-Ads Invariant
 */
struct GamePlayView: View {
    let initialLevel: Int
    let onSelectLevel: (Int) -> Void
    let onOpenPlinko: () -> Void

    @State private var engine: GameplayEngine
    @State private var ballPos: Vector3D
    @State private var ballSpeed: Double = 0.0
    @State private var ballRotAngle: Double = 0.0
    @State private var gameState: GameState
    @State private var currentLevelNum: Int
    @State private var lives: Int
    @State private var coins: Int
    @State private var keys: Int

    @State private var showLevelSelector: Bool = false
    @State private var isMuted: Bool = false
    @State private var floatingTexts: [FloatingPopupText] = []
    @State private var confettiPieces: [ConfettiPiece] = []

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    init(initialLevel: Int = 1, onSelectLevel: @escaping (Int) -> Void, onOpenPlinko: @escaping () -> Void) {
        self.initialLevel = initialLevel
        self.onSelectLevel = onSelectLevel
        self.onOpenPlinko = onOpenPlinko

        let eng = GameplayEngine(course: LevelCourseBuilder.buildLevel(initialLevel))
        _engine = State(initialValue: eng)
        _ballPos = State(initialValue: eng.ballPosition)
        _gameState = State(initialValue: eng.state)
        _currentLevelNum = State(initialValue: eng.currentLevel)
        _lives = State(initialValue: eng.lives)
        _coins = State(initialValue: eng.coinsCollected)
        _keys = State(initialValue: eng.keysCollected)
    }

    var body: some View {
        GeometryReader { geometry in
            let screenW = geometry.size.width
            let screenH = geometry.size.height

            ZStack {
                // Background fallback
                Color(hex: 0x38BDF8).ignoresSafeArea()

                // 1. 3D Perspective Viewport Canvas
                Canvas { context, size in
                    render3DScene(context: context, size: size)
                }
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if engine.state == .ready {
                                GameAudioManager.shared.startBgm()
                                engine.startRoll()
                            }
                            let forward = Double(-value.translation.height * 0.08).clamped(to: -1.0...1.0)
                            let steer = Double(value.translation.width * 0.05).clamped(to: -1.0...1.0)
                            engine.setInputs(forward: forward, steer: steer)
                        }
                        .onEnded { _ in
                            engine.setInputs(forward: 0.0, steer: 0.0)
                        }
                )

                // 2. HUD Overlay
                VStack {
                    topHUDHeader
                    Spacer()
                    bottomStatsBanner
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 12)

                // 3. Start Game Prompt (Modeled after Going Balls ready screen)
                if gameState == .ready && !showLevelSelector {
                    readyScreenPrompt
                }

                // 4. Level Completed Screen (Victory Fanfare plays!)
                if gameState == .levelCompleted && !showLevelSelector {
                    levelCompletedScreen
                }

                // 5. 40-Level Grid Selection Modal
                if showLevelSelector {
                    LevelSelectModal(
                        currentLevel: currentLevelNum,
                        onSelectLevel: { selected in
                            GameAudioManager.shared.playButton()
                            GameAudioManager.shared.stopVictoryFanfare()
                            GameAudioManager.shared.startBgm()
                            showLevelSelector = false
                            onSelectLevel(selected)
                        },
                        onClose: {
                            showLevelSelector = false
                        }
                    )
                }
            }
            .onAppear {
                setupEventListener()
            }
            .onReceive(timer) { _ in
                engine.update(dt: 0.016)
                ballPos = engine.ballPosition
                ballSpeed = engine.ballVelocity.length()
                ballRotAngle = engine.ballRotationAngle
                gameState = engine.state
                currentLevelNum = engine.currentLevel
                lives = engine.lives
                coins = engine.coinsCollected
                keys = engine.keysCollected

                // Update confetti
                if gameState == .levelCompleted {
                    for i in 0..<confettiPieces.count {
                        confettiPieces[i].x += confettiPieces[i].vx
                        confettiPieces[i].y += confettiPieces[i].vy
                        confettiPieces[i].rotation += 5.0
                    }
                }
            }
        }
    }

    // MARK: - Event Listener Setup
    private func setupEventListener() {
        engine.onEvent = { event in
            switch event {
            case .coinCollected(let amount, let pos):
                GameAudioManager.shared.playCoin()
                floatingTexts.append(FloatingPopupText(text: "+\(amount) 🪙", color: Color(hex: 0xFDE047), worldPos: pos))
            case .keyCollected(_, let pos):
                GameAudioManager.shared.playKey()
                floatingTexts.append(FloatingPopupText(text: "KEY! 🔑", color: Color(hex: 0x38BDF8), worldPos: pos))
            case .lifeGained(_, let pos):
                GameAudioManager.shared.playLife()
                floatingTexts.append(FloatingPopupText(text: "+1 BALL! ⚽", color: Color(hex: 0x34D399), worldPos: pos))
            case .obstacleShattered(_, let pos):
                GameAudioManager.shared.playSmash()
                floatingTexts.append(FloatingPopupText(text: "SMASH! ★", color: Color(hex: 0xF43F5E), worldPos: pos))
            case .checkpointReached:
                GameAudioManager.shared.playCheckpoint()
            case .levelFinished:
                GameAudioManager.shared.playVictoryFanfare()
                spawnConfetti()
            default:
                break
            }
        }
    }

    private func spawnConfetti() {
        confettiPieces.removeAll()
        let colors = [
            Color(hex: 0xF43F5E), Color(hex: 0x38BDF8), Color(hex: 0x10B981),
            Color(hex: 0xFBBF24), Color(hex: 0xA855F7), Color(hex: 0xFFFF7A00)
        ]
        for _ in 0..<80 {
            confettiPieces.append(
                ConfettiPiece(
                    x: CGFloat.random(in: 20...380),
                    y: CGFloat.random(in: -50...150),
                    vx: CGFloat.random(in: -3.0...3.0),
                    vy: CGFloat.random(in: 3.0...7.0),
                    color: colors.randomElement() ?? .yellow,
                    size: CGFloat.random(in: 8...14),
                    rotation: Double.random(in: 0...360)
                )
            )
        }
    }

    // MARK: - 3D Scene Rendering
    private func render3DScene(context: GraphicsContext, size: CGSize) {
        let screenW = size.width
        let screenH = size.height

        let camDistance = 4.5
        let camHeight = 2.2
        let camX = ballPos.x * 0.4
        let camY = ballPos.y + camHeight
        let camZ = ballPos.z - camDistance

        let speedFactor = max(0.0, min(1.0, ballSpeed / 25.0))
        let fovDeg = 60.0 + speedFactor * 14.0
        let fovRad = fovDeg * .pi / 180.0
        let focalLength = (screenH / 2.0) / tan(fovRad / 2.0)

        func project(_ worldX: Double, _ worldY: Double, _ worldZ: Double) -> CGPoint? {
            let relZ = worldZ - camZ
            if relZ <= 0.2 { return nil }
            let relX = worldX - camX
            let relY = worldY - camY
            let u = (screenW / 2.0) + (relX / relZ) * focalLength
            let v = (screenH * 0.58) - (relY / relZ) * focalLength
            return CGPoint(x: u, y: v)
        }

        let horizonY = screenH * 0.58

        // A. Sunny Daytime Cartoon Sky
        let skyRect = CGRect(x: 0, y: 0, width: screenW, height: horizonY)
        context.fill(
            Path(skyRect),
            with: .linearGradient(
                Gradient(colors: [Color(hex: 0x38BDF8), Color(hex: 0x7DD3FC), Color(hex: 0xBAE6FD), Color(hex: 0xFEF3C7)]),
                startPoint: CGPoint(x: screenW * 0.5, y: 0),
                endPoint: CGPoint(x: screenW * 0.5, y: horizonY)
            )
        )

        // B. Glowing Cartoon Sun
        let sunCenter = CGPoint(x: screenW * 0.82, y: screenH * 0.15)
        context.fill(Path(ellipseIn: CGRect(x: sunCenter.x - 70, y: sunCenter.y - 70, width: 140, height: 140)), with: .color(Color(hex: 0xFDE047).opacity(0.35)))
        context.fill(Path(ellipseIn: CGRect(x: sunCenter.x - 42, y: sunCenter.y - 42, width: 84, height: 84)), with: .color(Color(hex: 0xFEF08A)))
        context.fill(Path(ellipseIn: CGRect(x: sunCenter.x - 24, y: sunCenter.y - 24, width: 48, height: 48)), with: .color(.white))

        // C. Rolling Green Hills at Horizon
        var hillBack = Path()
        hillBack.move(to: CGPoint(x: 0, y: horizonY))
        hillBack.addQuadCurve(to: CGPoint(x: screenW * 0.5, y: horizonY - 18), control: CGPoint(x: screenW * 0.25, y: horizonY - 45))
        hillBack.addQuadCurve(to: CGPoint(x: screenW, y: horizonY - 22), control: CGPoint(x: screenW * 0.75, y: horizonY - 50))
        hillBack.addLine(to: CGPoint(x: screenW, y: screenH))
        hillBack.addLine(to: CGPoint(x: 0, y: screenH))
        hillBack.closeSubpath()
        context.fill(hillBack, with: .color(Color(hex: 0x86EFAC)))

        var hillFront = Path()
        hillFront.move(to: CGPoint(x: 0, y: horizonY))
        hillFront.addQuadCurve(to: CGPoint(x: screenW * 0.65, y: horizonY - 38), control: CGPoint(x: screenW * 0.35, y: horizonY - 30))
        hillFront.addQuadCurve(to: CGPoint(x: screenW, y: horizonY), control: CGPoint(x: screenW * 0.85, y: horizonY - 14))
        hillFront.addLine(to: CGPoint(x: screenW, y: screenH))
        hillFront.addLine(to: CGPoint(x: 0, y: screenH))
        hillFront.closeSubpath()
        context.fill(hillFront, with: .color(Color(hex: 0x4ADE80)))

        // Ground under track
        let groundRect = CGRect(x: 0, y: horizonY, width: screenW, height: screenH - horizonY)
        context.fill(Path(groundRect), with: .color(Color(hex: 0x22C55E)))

        // 1. Draw Track Runway Planks & Candy Cane Rails
        for seg in engine.course.segments {
            if seg.endZ < camZ - 2.0 || seg.startZ > camZ + 85.0 { continue }

            let stepZ = 2.5
            var currZ = max(seg.startZ, camZ - 1.0)
            while currZ < seg.endZ {
                let nextZ = min(seg.endZ, currZ + stepZ)
                let y1 = seg.getHeightAt(currZ)
                let y2 = seg.getHeightAt(nextZ)
                let hw = seg.width / 2.0

                if let pTL = project(-hw, y1, currZ),
                   let pTR = project(hw, y1, currZ),
                   let pBR = project(hw, y2, nextZ),
                   let pBL = project(-hw, y2, nextZ) {

                    var plankPath = Path()
                    plankPath.move(to: pTL)
                    plankPath.addLine(to: pTR)
                    plankPath.addLine(to: pBR)
                    plankPath.addLine(to: pBL)
                    plankPath.closeSubpath()

                    let isBooster = seg.isBooster
                    let plankColor: Color = isBooster ? Color(hex: 0x10B981) : ((Int(currZ) / 2) % 2 == 0 ? Color(hex: 0xFDE68A) : Color(hex: 0xF59E0B))

                    context.fill(plankPath, with: .color(plankColor))

                    // Track edge curbs
                    var edgeL = Path()
                    edgeL.move(to: pTL)
                    edgeL.addLine(to: pBL)
                    context.stroke(edgeL, with: .color(Color(hex: 0xB45309)), lineWidth: 3)

                    var edgeR = Path()
                    edgeR.move(to: pTR)
                    edgeR.addLine(to: pBR)
                    context.stroke(edgeR, with: .color(Color(hex: 0xB45309)), lineWidth: 3)

                    // Candy cane rails
                    if seg.hasLeftRail,
                       let rL1 = project(-hw - 0.25, y1 + 0.45, currZ),
                       let rL2 = project(-hw - 0.25, y2 + 0.45, nextZ) {
                        let railCol = (Int(currZ) % 2 == 0) ? Color(hex: 0xEF4444) : .white
                        var rPath = Path()
                        rPath.move(to: rL1)
                        rPath.addLine(to: rL2)
                        context.stroke(rPath, with: .color(railCol), lineWidth: 6)
                    }

                    if seg.hasRightRail,
                       let rR1 = project(hw + 0.25, y1 + 0.45, currZ),
                       let rR2 = project(hw + 0.25, y2 + 0.45, nextZ) {
                        let railCol = (Int(currZ) % 2 == 0) ? Color(hex: 0xEF4444) : .white
                        var rPath = Path()
                        rPath.move(to: rR1)
                        rPath.addLine(to: rR2)
                        context.stroke(rPath, with: .color(railCol), lineWidth: 6)
                    }
                }
                currZ = nextZ
            }
        }

        // 2. Draw Checkpoints, Items, & Finish Line
        for item in engine.course.items {
            if item.position.z < camZ - 2.0 || item.position.z > camZ + 75.0 { continue }
            switch item.type {
            case .checkpoint:
                if let p = project(item.position.x, item.position.y, item.position.z) {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 30, y: p.y - 30, width: 60, height: 60)), with: .color(Color(hex: 0x06B6D4).opacity(0.35)))
                    context.stroke(Path(ellipseIn: CGRect(x: p.x - 18, y: p.y - 18, width: 36, height: 36)), with: .color(Color(hex: 0x06B6D4)), lineWidth: 4)
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14)), with: .color(Color(hex: 0xFDE047)))
                }
            case .finishLine:
                if let pL = project(-2.0, item.position.y, item.position.z),
                   let pR = project(2.0, item.position.y, item.position.z) {
                    var finishPath = Path()
                    finishPath.move(to: pL)
                    finishPath.addLine(to: pR)
                    context.stroke(finishPath, with: .color(.white), lineWidth: 16)
                    context.stroke(finishPath, with: .color(Color(hex: 0xEF4444)), lineWidth: 8)
                }
            case .coin:
                if !item.isCollected, let p = project(item.position.x, item.position.y + 0.3, item.position.z) {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 14, y: p.y - 14, width: 28, height: 28)), with: .color(Color(hex: 0xFBBF24)))
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20)), with: .color(Color(hex: 0xFEF08A)))
                    context.stroke(Path(ellipseIn: CGRect(x: p.x - 14, y: p.y - 14, width: 28, height: 28)), with: .color(Color(hex: 0xB45309)), lineWidth: 2)
                }
            case .goldenKey:
                if !item.isCollected, let p = project(item.position.x, item.position.y + 0.4, item.position.z) {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 18, y: p.y - 18, width: 36, height: 36)), with: .color(Color(hex: 0xFBBF24)))
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)), with: .color(.white))
                }
            case .spareBall:
                if !item.isCollected, let p = project(item.position.x, item.position.y + 0.45, item.position.z) {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 16, y: p.y - 16, width: 32, height: 32)), with: .color(Color(hex: 0x38BDF8)))
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 8, width: 10, height: 10)), with: .color(.white))
                }
            }
        }

        // 3. Draw Destructible Toy Star Cubes
        for cube in engine.course.obstacles {
            if cube.isShattered || cube.position.z < camZ - 2.0 || cube.position.z > camZ + 80.0 { continue }
            if let p = project(cube.position.x, cube.position.y, cube.position.z) {
                let relZ = cube.position.z - camZ
                let cubeSize = CGFloat(((cube.size / relZ) * focalLength)).clamped(to: 10...120)
                let halfS = cubeSize / 2.0

                let cRect = CGRect(x: p.x - halfS, y: p.y - halfS, width: cubeSize, height: cubeSize)
                context.fill(Path(roundedRect: cRect, cornerRadius: 6), with: .color(Color(hex: 0xEC4899)))
                context.stroke(Path(roundedRect: cRect, cornerRadius: 6), with: .color(Color(hex: 0xFBBF24)), lineWidth: max(2, cubeSize * 0.1))
                context.fill(Path(ellipseIn: CGRect(x: p.x - cubeSize * 0.2, y: p.y - cubeSize * 0.2, width: cubeSize * 0.4, height: cubeSize * 0.4)), with: .color(Color(hex: 0xFDE047)))
            }
        }

        // 4. Draw Rolling Ball (Glossy Superhero Cyan & Coral Swirl Ball)
        if let pBall = project(ballPos.x, ballPos.y, ballPos.z) {
            let relZ = ballPos.z - camZ
            let ballR = CGFloat(((PhysicsConstants.ballRadius / relZ) * focalLength)).clamped(to: 18...150)

            // Contact Shadow
            if let pShadow = project(ballPos.x, ballPos.y - PhysicsConstants.ballRadius, ballPos.z) {
                let shadowRect = CGRect(x: pShadow.x - ballR * 0.9, y: pShadow.y - ballR * 0.25, width: ballR * 1.8, height: ballR * 0.5)
                context.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.4)))
            }

            // Ball Sphere Body (Glossy Cyan & Ocean Blue)
            let ballRect = CGRect(x: pBall.x - ballR, y: pBall.y - ballR, width: ballR * 2, height: ballR * 2)
            context.fill(
                Path(ellipseIn: ballRect),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: 0x67E8F9), Color(hex: 0x0284C7), Color(hex: 0x1E3A8A)]),
                    center: CGPoint(x: pBall.x - ballR * 0.35, y: pBall.y - ballR * 0.35),
                    startRadius: 2,
                    endRadius: ballR * 1.3
                )
            )

            // Dynamic Racing Rolling Stripe
            let rotX = CGFloat(cos(ballRotAngle)) * ballR * 0.65
            var stripePath = Path()
            stripePath.move(to: CGPoint(x: pBall.x - rotX, y: pBall.y - ballR * 0.7))
            stripePath.addLine(to: CGPoint(x: pBall.x + rotX, y: pBall.y + ballR * 0.7))
            context.stroke(stripePath, with: .color(Color(hex: 0xFDE047)), lineWidth: max(3, ballR * 0.14))

            // Specular Marble Gloss Highlight
            let specRect = CGRect(x: pBall.x - ballR * 0.55, y: pBall.y - ballR * 0.55, width: ballR * 0.55, height: ballR * 0.55)
            context.fill(Path(ellipseIn: specRect), with: .color(.white.opacity(0.85)))
        }

        // 5. Draw Confetti
        if gameState == .levelCompleted {
            for piece in confettiPieces {
                context.fill(Path(CGRect(x: piece.x, y: piece.y, width: piece.size, height: piece.size * 0.6)), with: .color(piece.color))
            }
        }
    }

    // MARK: - Subviews (HUD, Prompts, Modals)

    private var topHUDHeader: some View {
        HStack(spacing: 8) {
            // Map Button
            Button(action: {
                GameAudioManager.shared.playButton()
                showLevelSelector = true
            }) {
                VStack(spacing: 1) {
                    Text("🗺️").font(.system(size: 14))
                    Text("MAP").font(.system(size: 7, weight: .heavy)).foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .background(Color(hex: 0x0284C7))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            // Sound Toggle (🔊 / 🔇)
            Button(action: {
                isMuted = GameAudioManager.shared.toggleMute()
            }) {
                Text(isMuted ? "🔇" : "🔊")
                    .font(.system(size: 16))
                    .frame(width: 44, height: 44)
                    .background(isMuted ? Color(hex: 0xEF4444) : Color(hex: 0x10B981))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            // Level Title & Progress Bar
            VStack(spacing: 3) {
                HStack(spacing: 6) {
                    Text("LEVEL \(currentLevelNum)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0x8B5CF6))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xFBBF24), lineWidth: 2))

                    let diff = engine.course.difficulty
                    Text(diff.label)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: diff.hexColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1.5))
                }

                Text(engine.course.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: 0x0F172A))
                    .lineLimit(1)

                // Progress Bar
                let progress = CGFloat(ballPos.z / engine.course.totalLength).clamped(to: 0...1)
                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.3))
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: 0xFDE047), Color(hex: 0xF59E0B)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: barGeo.size.width * progress)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                GameAudioManager.shared.playButton()
                showLevelSelector = true
            }

            // 5-Ball Lives Column
            VStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    let hasLife = i < lives
                    Circle()
                        .fill(hasLife ? Color(hex: 0x38BDF8) : Color(hex: 0xEF4444).opacity(0.8))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .overlay(
                            Text(hasLife ? "●" : "✕")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }

    private var bottomStatsBanner: some View {
        HStack {
            Text("🔑 KEYS: \(keys) / 3")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Color(hex: 0xFEF08A))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(hex: 0x0284C7).opacity(0.9))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1.5))

            Spacer()

            Text("🪙 COINS: \(coins)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(hex: 0xF59E0B).opacity(0.9))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1.5))
        }
    }

    private var readyScreenPrompt: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("🌟 AEROSPHERE 3D 🌟")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Color(hex: 0x0284C7))

                HStack(spacing: 8) {
                    Text("LVL \(currentLevelNum): \(engine.course.name)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: 0xB45309))

                    let diff = engine.course.difficulty
                    Text(diff.label)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: diff.hexColor))
                        .cornerRadius(6)
                }

                Text("Swipe forward/backward to roll & brake\nDrag left/right to steer!")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x475569))
                    .multilineTextAlignment(.center)

                Button(action: {
                    GameAudioManager.shared.playButton()
                    GameAudioManager.shared.startBgm()
                    engine.startRoll()
                }) {
                    Text("▶ PLAY NOW")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: 0x22C55E))
                        .cornerRadius(25)
                }

                Button(action: {
                    GameAudioManager.shared.playButton()
                    showLevelSelector = true
                }) {
                    Text("🗺️ SELECT LEVEL (1-40)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color(hex: 0x0284C7))
                        .cornerRadius(21)
                }
            }
            .padding(24)
            .frame(width: 310)
            .background(Color.white.opacity(0.96))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: 0x38BDF8), lineWidth: 3))
        }
    }

    private var levelCompletedScreen: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("LEVEL \(currentLevelNum)")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0x8B5CF6))
                    .cornerRadius(12)

                Text(engine.course.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x334155))

                Text("🎉 COMPLETED! 🎉")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0x10B981))
                    .cornerRadius(10)

                VStack(spacing: 4) {
                    Text("COLLECTED COINS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0x64748B))
                    Text("+\(coins) COINS 🪙")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color(hex: 0xD97706))
                    Text("Keys Collected: \(keys) / 3 🔑")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x0284C7))
                }

                Button(action: {
                    GameAudioManager.shared.playButton()
                    GameAudioManager.shared.stopVictoryFanfare()
                    onOpenPlinko()
                }) {
                    Text("🎁 CLAIM REWARD (PLINKO)")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color(hex: 0xF59E0B))
                        .cornerRadius(23)
                }

                let nextLvl = (currentLevelNum < 40) ? currentLevelNum + 1 : 1
                Button(action: {
                    GameAudioManager.shared.playButton()
                    GameAudioManager.shared.stopVictoryFanfare()
                    GameAudioManager.shared.startBgm()
                    onSelectLevel(nextLvl)
                }) {
                    Text("NEXT LEVEL (LVL \(nextLvl)) ▶")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color(hex: 0x22C55E))
                        .cornerRadius(21)
                }

                Button(action: {
                    GameAudioManager.shared.playButton()
                    showLevelSelector = true
                }) {
                    Text("🗺️ SELECT LEVEL (1-40)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(hex: 0x64748B))
                        .cornerRadius(18)
                }
            }
            .padding(22)
            .frame(width: 310)
            .background(Color.white.opacity(0.96))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: 0xFBBF24), lineWidth: 3))
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

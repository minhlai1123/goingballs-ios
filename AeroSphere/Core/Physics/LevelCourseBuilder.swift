import Foundation

/**
 * 40-Level Progressive Course Builder (iOS Swift Implementation)
 * Generates 40 unique, deterministic, handcrafted-quality levels
 * covering Easy, Normal, Hard, and Expert difficulties.
 * 100% Zero-Ads Invariant
 */
public struct LevelCourseBuilder {

    public static let levelNames: [String] = [
        // World 1: Timber Highlands (Easy, Levels 1-10)
        "Green Meadow", "Timber Slope", "Gentle Breeze", "Forest Pathway", "Oak Rapids",
        "River Crossing", "Sunlit Bridge", "Whispering Pines", "Maple Ridge", "Timber Summit",
        // World 2: Canyon Springs (Normal, Levels 11-20)
        "Canyon Descent", "Redwood Chasm", "S-Curve Valley", "Rocky Slopes", "Echo Gorge",
        "Boulder Run", "Narrow Ledge", "Speedway Canyon", "Twin Barricades", "Chasm Crossroad",
        // World 3: Alpine Ridge (Hard, Levels 21-30)
        "Alpine Crest", "Frostbite Dip", "Glacier Slalom", "Razor Edge", "Skyline Leap",
        "Spiral Ridge", "Avalanche Run", "Thunder Peak", "Mist Canyon", "Sky Sanctuary",
        // World 4: Apex Skyway (Expert, Levels 31-40)
        "Apex Citadel", "Titan's Rampart", "Steel & Timber", "Vortex Way", "Highwire Sprint",
        "Labyrinth Curve", "Meteor Drop", "Zenith Runway", "Shadow Pass", "The Titan's Gauntlet"
    ]

    public static func getLevelName(for levelNumber: Int) -> String {
        let idx = max(0, min(levelNames.count - 1, levelNumber - 1))
        return levelNames[idx]
    }

    public static func getDifficulty(for levelNumber: Int) -> LevelDifficulty {
        switch levelNumber {
        case 1...10: return .easy
        case 11...20: return .normal
        case 21...30: return .hard
        default: return .expert
        }
    }

    /// Linear congruential PRNG for deterministic cross-platform level generation
    private class DeterministicRNG {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed
        }

        func nextDouble(min: Double = 0.0, max: Double = 1.0) -> Double {
            state = (state &* 6364136223846793005 &+ 1442695040888963407)
            let normalized = Double(state >> 11) / Double(1 << 53)
            return min + normalized * (max - min)
        }
    }

    public static func buildLevel(_ levelNumber: Int) -> LevelCourse {
        let clamped = max(1, min(40, levelNumber))
        let name = getLevelName(for: clamped)
        let difficulty = getDifficulty(for: clamped)

        let rng = DeterministicRNG(seed: UInt64(clamped * 1337 + 42))

        let totalLength = 100.0 + Double(clamped - 1) * 4.0
        let parTime = max(18, Int(totalLength / 5.5))
        let baseWidth = max(2.2, min(4.5, 4.5 - Double(clamped - 1) * 0.058))

        var segments: [TrackSegment] = []
        var obstacles: [DestructibleCube] = []
        var items: [TrackItem] = []

        // 1. Generate Track Segments
        var currentZ = 0.0
        var currentY = 0.0
        var segmentIdx = 0

        while currentZ < totalLength {
            let segLength = min(totalLength - currentZ, rng.nextDouble(min: 18.0, max: 32.0))
            let nextZ = currentZ + segLength

            let isStartOrEnd = (currentZ == 0.0 || nextZ >= totalLength - 15.0)
            let isDip = !isStartOrEnd && (segmentIdx % 2 == 1)
            let isBooster = !isStartOrEnd && (clamped >= 5 && rng.nextDouble() < 0.35)

            let railProb: Double = {
                switch difficulty {
                case .easy: return 1.0
                case .normal: return 0.75
                case .hard: return 0.45
                case .expert: return 0.30
                }
            }()

            let hasLeftRail = isStartOrEnd || rng.nextDouble() < railProb
            let hasRightRail = isStartOrEnd || rng.nextDouble() < railProb

            let deltaY = isStartOrEnd ? 0.0 : rng.nextDouble(min: -1.8, max: 0.4)
            let nextY = currentY + deltaY
            let dipDepth = isDip ? rng.nextDouble(min: 2.0, max: 3.0 + Double(clamped) * 0.05) : 0.0

            segments.append(
                TrackSegment(
                    startZ: currentZ,
                    endZ: nextZ,
                    width: baseWidth,
                    startY: currentY,
                    endY: nextY,
                    hasLeftRail: hasLeftRail,
                    hasRightRail: hasRightRail,
                    isBooster: isBooster,
                    isCurvedDip: isDip,
                    dipDepth: dipDepth
                )
            )

            currentZ = nextZ
            currentY = nextY
            segmentIdx += 1
        }

        func getFloorY(_ z: Double) -> Double {
            for s in segments {
                if s.containsZ(z) { return s.getHeightAt(z) }
            }
            return 0.0
        }

        // 2. Generate Destructible Cube Obstacles
        let clusterCount: Int = {
            switch difficulty {
            case .easy: return (clamped == 1) ? 1 : 2
            case .normal: return 3
            case .hard: return 4
            case .expert: return 5
            }
        }()

        let stepDist = totalLength / Double(clusterCount + 1)
        for i in 1...clusterCount {
            let clusterZ = Double(i) * stepDist + rng.nextDouble(min: -4.0, max: 4.0)
            let floorY = getFloorY(clusterZ)

            if difficulty == .easy && clamped <= 3 {
                obstacles.append(DestructibleCube(id: "l\(clamped)_c\(i)_1", position: Vector3D(x: -0.7, y: floorY + 0.3, z: clusterZ)))
                obstacles.append(DestructibleCube(id: "l\(clamped)_c\(i)_2", position: Vector3D(x: 0.7, y: floorY + 0.3, z: clusterZ + 2.5)))
            } else {
                let cols = (baseWidth < 3.0) ? [-0.5, 0.5] : [-0.65, 0.0, 0.65]
                let rows = [0.0, 0.65]
                for c in cols {
                    for r in rows {
                        obstacles.append(
                            DestructibleCube(
                                id: "l\(clamped)_c\(i)_\(c)_\(r)",
                                position: Vector3D(x: c, y: floorY + 0.3 + r, z: clusterZ)
                            )
                        )
                    }
                }
            }
        }

        // 3. Generate Checkpoints & Spare Balls
        let checkpointCount: Int = {
            switch difficulty {
            case .easy: return 1
            case .normal, .hard: return 2
            case .expert: return 3
            }
        }()

        for cp in 1...checkpointCount {
            let cpZ = (Double(cp) / Double(checkpointCount + 1)) * totalLength
            let cpY = getFloorY(cpZ)
            items.append(TrackItem(id: "l\(clamped)_chk_\(cp)", type: .checkpoint, position: Vector3D(x: 0.0, y: cpY + 0.1, z: cpZ), radius: 1.8))
            items.append(TrackItem(id: "l\(clamped)_ball_\(cp)", type: .spareBall, position: Vector3D(x: 0.0, y: cpY + 0.8, z: cpZ + 5.0)))
        }

        // 4. Generate Golden Keys
        if clamped % 2 != 0 || clamped == 2 {
            let keyZ = totalLength * 0.45 + rng.nextDouble(min: -6.0, max: 6.0)
            let keyY = getFloorY(keyZ)
            items.append(TrackItem(id: "l\(clamped)_key", type: .goldenKey, position: Vector3D(x: 0.0, y: keyY + 0.7, z: keyZ)))
        }

        // 5. Generate Coins (15 to 45 coins)
        let coinCount = 15 + clamped
        let coinStep = (totalLength - 20.0) / Double(coinCount)
        for c in 1...coinCount {
            let coinZ = 10.0 + Double(c) * coinStep + rng.nextDouble(min: -2.0, max: 2.0)
            let coinY = getFloorY(coinZ)
            let coinX = (rng.nextDouble() < 0.4) ? rng.nextDouble(min: -1.0, max: 1.0) * (baseWidth * 0.3) : 0.0
            items.append(TrackItem(id: "l\(clamped)_coin_\(c)", type: .coin, position: Vector3D(x: coinX, y: coinY + 0.6, z: coinZ)))
        }

        // 6. Finish Line
        let finishY = getFloorY(totalLength)
        items.append(TrackItem(id: "l\(clamped)_finish", type: .finishLine, position: Vector3D(x: 0.0, y: finishY + 0.1, z: totalLength), radius: 2.0))

        return LevelCourse(
            levelNumber: clamped,
            name: name,
            difficulty: difficulty,
            totalLength: totalLength,
            segments: segments,
            obstacles: obstacles,
            items: items,
            startPosition: Vector3D(x: 0.0, y: getFloorY(2.0) + 0.5, z: 2.0),
            parTimeSeconds: parTime
        )
    }
}

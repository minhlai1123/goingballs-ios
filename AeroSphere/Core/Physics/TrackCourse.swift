import Foundation

/**
 * AeroSphere 3D - Native iOS Track Course Models
 * Document Authority: SPEC-PHYS-005-REV02.3, MTX-SCOPE-023-REV01.0
 * 100% Zero-Ads, Arcade 2.0g Physics (g = 19.620 m/s²)
 */

public enum CollectibleType: String, Sendable {
    case coin = "COIN"
    case goldenKey = "GOLDEN_KEY"
    case spareBall = "SPARE_BALL"
    case checkpoint = "CHECKPOINT"
    case finishLine = "FINISH_LINE"
}

public struct TrackItem: Identifiable, Sendable {
    public let id: String
    public let type: CollectibleType
    public let position: Vector3D
    public let radius: Double
    public var isCollected: Bool

    public init(id: String, type: CollectibleType, position: Vector3D, radius: Double = 1.0, isCollected: Bool = false) {
        self.id = id
        self.type = type
        self.position = position
        self.radius = radius
        self.isCollected = isCollected
    }
}

public struct DestructibleCube: Identifiable, Sendable {
    public let id: String
    public var position: Vector3D
    public let size: Double
    public var isShattered: Bool

    public init(id: String, position: Vector3D, size: Double = 0.65, isShattered: Bool = false) {
        self.id = id
        self.position = position
        self.size = size
        self.isShattered = isShattered
    }
}

public struct TrackSegment: Sendable {
    public let startZ: Double
    public let endZ: Double
    public let width: Double
    public let startY: Double
    public let endY: Double
    public let hasLeftRail: Bool
    public let hasRightRail: Bool
    public let isBooster: Bool
    public let isCurvedDip: Bool
    public let dipDepth: Double

    public init(
        startZ: Double,
        endZ: Double,
        width: Double = 4.0,
        startY: Double = 0.0,
        endY: Double = 0.0,
        hasLeftRail: Bool = true,
        hasRightRail: Bool = true,
        isBooster: Bool = false,
        isCurvedDip: Bool = false,
        dipDepth: Double = 0.0
    ) {
        self.startZ = startZ
        self.endZ = endZ
        self.width = width
        self.startY = startY
        self.endY = endY
        self.hasLeftRail = hasLeftRail
        self.hasRightRail = hasRightRail
        self.isBooster = isBooster
        self.isCurvedDip = isCurvedDip
        self.dipDepth = dipDepth
    }

    public func containsZ(_ z: Double) -> Bool {
        return z >= startZ && z <= endZ
    }

    public func getHeightAt(_ z: Double) -> Double {
        if endZ <= startZ { return startY }
        let t = (z - startZ) / (endZ - startZ)
        let linearY = startY + t * (endY - startY)
        if isCurvedDip {
            // Quadratic dip: 4 * t * (1 - t) peaks at t = 0.5
            let dip = 4.0 * t * (1.0 - t) * dipDepth
            return linearY - dip
        }
        return linearY
    }
}

public enum LevelDifficulty: String, CaseIterable, Sendable {
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"
    case expert = "EXPERT"

    public var label: String { rawValue }

    public var hexColor: UInt32 {
        switch self {
        case .easy: return 0xFF22C55E   // Green
        case .normal: return 0xFF0284C7 // Sky Blue
        case .hard: return 0xFFF59E0B   // Amber Gold
        case .expert: return 0xFFEF4444 // Crimson Red
        }
    }
}

public class LevelCourse: @unchecked Sendable {
    public let levelNumber: Int
    public let name: String
    public let difficulty: LevelDifficulty
    public let totalLength: Double
    public let segments: [TrackSegment]
    public var obstacles: [DestructibleCube]
    public var items: [TrackItem]
    public let startPosition: Vector3D
    public let parTimeSeconds: Int

    public init(
        levelNumber: Int,
        name: String,
        difficulty: LevelDifficulty,
        totalLength: Double,
        segments: [TrackSegment],
        obstacles: [DestructibleCube],
        items: [TrackItem],
        startPosition: Vector3D = Vector3D(x: 0.0, y: 0.5, z: 2.0),
        parTimeSeconds: Int = 30
    ) {
        self.levelNumber = levelNumber
        self.name = name
        self.difficulty = difficulty
        self.totalLength = totalLength
        self.segments = segments
        self.obstacles = obstacles
        self.items = items
        self.startPosition = startPosition
        self.parTimeSeconds = parTimeSeconds
    }

    public func getTrackHeightAt(_ z: Double) -> Double {
        for segment in segments {
            if segment.containsZ(z) {
                return segment.getHeightAt(z)
            }
        }
        return 0.0
    }

    public func getSegmentAt(_ z: Double) -> TrackSegment? {
        return segments.first { segment in segment.containsZ(z) }
    }
}

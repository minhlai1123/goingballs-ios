import Foundation

public enum GameState: String, Sendable {
    case ready = "READY"
    case playing = "PLAYING"
    case paused = "PAUSED"
    case respawning = "RESPAWNING"
    case levelCompleted = "LEVEL_COMPLETED"
    case plinkoBonus = "PLINKO_BONUS"
}

public enum GameEvent: Sendable {
    case coinCollected(amount: Int, position: Vector3D)
    case keyCollected(keyIndex: Int, position: Vector3D)
    case lifeGained(totalLives: Int, position: Vector3D)
    case checkpointReached(checkpointId: String, position: Vector3D)
    case obstacleShattered(cubeId: String, position: Vector3D)
    case boosterActivated(boostSpeed: Double)
    case ballFellOffTrack(position: Vector3D)
    case levelFinished(level: Int, coinsEarned: Int)
}

/**
 * Full 3D Rolling Ball Gameplay Simulation Engine (iOS Swift Implementation)
 * Encapsulates the arcade rolling physics, touch inputs, track constraints, and scoring
 * 100% Zero-Ads Invariant, Fixed 2.0g Arcade World Gravity (g = 19.620 m/s²)
 */
public class GameplayEngine: @unchecked Sendable {

    public private(set) var course: LevelCourse
    public private(set) var state: GameState = .ready

    // Ball kinematics
    public private(set) var ballPosition: Vector3D
    public private(set) var ballVelocity: Vector3D = .zero
    public private(set) var ballRotationAngle: Double = 0.0

    // Progression & Wallet
    public private(set) var currentLevel: Int
    public private(set) var lives: Int = 1 // Starts with 1 life as observed in video (max 5)
    public private(set) var coinsCollected: Int = 0
    public private(set) var totalSessionCoins: Int = 0
    public private(set) var keysCollected: Int = 0

    // Checkpoint
    public private(set) var lastCheckpointPos: Vector3D

    // Input state
    private var forwardInput: Double = 0.0
    private var steerInput: Double = 0.0

    // Event listener
    public var onEvent: ((GameEvent) -> Void)?

    public init(course: LevelCourse = LevelCourseBuilder.buildLevel(1)) {
        self.course = course
        self.currentLevel = course.levelNumber
        self.ballPosition = course.startPosition
        self.lastCheckpointPos = course.startPosition
    }

    public func setInputs(forward: Double, steer: Double) {
        self.forwardInput = max(-1.0, min(1.0, forward))
        self.steerInput = max(-1.0, min(1.0, steer))
    }

    public func startRoll() {
        if state == .ready {
            state = .playing
            ballVelocity = Vector3D(x: 0.0, y: 0.0, z: 4.0) // Initial gentle rolling impulse
        }
    }

    public func loadLevel(_ levelNum: Int) {
        let clamped = max(1, min(40, levelNum))
        course = LevelCourseBuilder.buildLevel(clamped)
        currentLevel = clamped
        ballPosition = course.startPosition
        ballVelocity = .zero
        ballRotationAngle = 0.0
        coinsCollected = 0
        lastCheckpointPos = course.startPosition
        state = .ready
    }

    public func completePlinko() {
        state = .ready
        let nextLvl = (currentLevel < 40) ? currentLevel + 1 : 1
        loadLevel(nextLvl)
    }

    /// Fixed-rate gameplay simulation tick (60 Hz)
    public func update(dt: Double = 1.0 / 60.0) {
        guard state == .playing else { return }

        // 1. Calculate Driving & Braking Forces
        let maxSpeed = 26.0
        let driveAccel = 12.0
        let brakeDecel = PhysicsConstants.emergencyBrakeDeceleration // 18.5 m/s²

        var accelZ = 0.0
        if forwardInput > 0.05 {
            accelZ += forwardInput * driveAccel
        } else if forwardInput < -0.05 {
            accelZ += forwardInput * brakeDecel
        } else {
            // Natural arcade rolling damping
            accelZ -= ballVelocity.z * (PhysicsConstants.arcadeGlideDamping * 0.15)
        }

        // Apply booster lane acceleration
        if let currentSegment = course.getSegmentAt(ballPosition.z), currentSegment.isBooster {
            accelZ += 18.0
            onEvent?(.boosterActivated(boostSpeed: ballVelocity.z))
        }

        // Integrate Velocity
        var newVz = ballVelocity.z + accelZ * dt
        newVz = max(0.0, min(maxSpeed, newVz))

        // Horizontal Steering (TC7 Calibration: 0.029 m/dp)
        let steerSpeed = 8.5
        var newVx = steerInput * steerSpeed

        // 2. Track Surface Height & Slope Gravity Integration
        let trackY = course.getTrackHeightAt(ballPosition.z)
        let ballR = PhysicsConstants.ballRadius

        // Downward Gravity: 19.620 m/s² (2.0g Arcade Model)
        var newVy = ballVelocity.y - PhysicsConstants.gravityMagnitude * dt
        var newY = ballPosition.y + newVy * dt

        // Ground Contact Resolution
        if newY <= trackY + ballR {
            newY = trackY + ballR
            newVy = 0.0
        }

        // Void Fall Check (fallen below track runway)
        if newY < trackY - 2.5 {
            handleVoidFall()
            return
        }

        // Integrate Position
        let newZ = ballPosition.z + newVz * dt
        var newX = ballPosition.x + newVx * dt

        // Side Railings Collision
        if let segment = course.getSegmentAt(newZ) {
            let halfW = segment.width / 2.0 - ballR
            if segment.hasLeftRail && newX < -halfW {
                newX = -halfW
                newVx = -newVx * PhysicsConstants.restitutionCoefficient
            }
            if segment.hasRightRail && newX > halfW {
                newX = halfW
                newVx = -newVx * PhysicsConstants.restitutionCoefficient
            }
        }

        ballPosition = Vector3D(x: newX, y: newY, z: newZ)
        ballVelocity = Vector3D(x: newVx, y: newVy, z: newVz)

        // Update 3D Rolling Rotation Angle
        let distanceRolled = newVz * dt
        ballRotationAngle += distanceRolled / ballR

        // 3. Destructible Cubes Collision (TC6 Option A Specification)
        for i in 0..<course.obstacles.count {
            if course.obstacles[i].isShattered { continue }

            let cube = course.obstacles[i]
            let dx = ballPosition.x - cube.position.x
            let dy = ballPosition.y - cube.position.y
            let dz = ballPosition.z - cube.position.z
            let distSq = dx * dx + dy * dy + dz * dz
            let collisionThreshold = ballR + cube.size * 0.55

            if distSq < collisionThreshold * collisionThreshold {
                // TC6 Impact Velocity Check (Threshold 13.5 m/s)
                let impactVelocity = ballVelocity.length()
                if impactVelocity >= PhysicsConstants.tc6TargetExitVelocity {
                    // Shatter obstacle cluster!
                    course.obstacles[i].isShattered = true
                    // Retain 71.19% kinetic energy (v_exit = v0 * sqrt(0.711914) = v0 * 0.84375)
                    ballVelocity = ballVelocity * sqrt(PhysicsConstants.tc6KineticEnergyRetainedRatio)
                    onEvent?(.obstacleShattered(cubeId: cube.id, position: cube.position))
                } else {
                    // Elastic rebound bounce
                    ballVelocity = Vector3D(x: ballVelocity.x, y: ballVelocity.y, z: -2.0)
                    ballPosition = Vector3D(x: ballPosition.x, y: ballPosition.y, z: cube.position.z - collisionThreshold)
                }
            }
        }

        // 4. Collectibles & Checkpoints Collision
        for i in 0..<course.items.count {
            if course.items[i].isCollected { continue }

            let item = course.items[i]
            let dx = ballPosition.x - item.position.x
            let dy = ballPosition.y - item.position.y
            let dz = ballPosition.z - item.position.z
            let dist = sqrt(dx * dx + dy * dy + dz * dz)

            if dist < (ballR + item.radius) {
                course.items[i].isCollected = true
                switch item.type {
                case .coin:
                    coinsCollected += 10
                    totalSessionCoins += 10
                    onEvent?(.coinCollected(amount: 10, position: item.position))
                case .goldenKey:
                    keysCollected += 1
                    onEvent?(.keyCollected(keyIndex: keysCollected, position: item.position))
                case .spareBall:
                    lives = min(5, lives + 1)
                    onEvent?(.lifeGained(totalLives: lives, position: item.position))
                case .checkpoint:
                    lastCheckpointPos = Vector3D(x: 0.0, y: course.getTrackHeightAt(item.position.z) + PhysicsConstants.ballRadius, z: item.position.z)
                    onEvent?(.checkpointReached(checkpointId: item.id, position: item.position))
                case .finishLine:
                    state = .levelCompleted
                    onEvent?(.levelFinished(level: currentLevel, coinsEarned: coinsCollected))
                }
            }
        }
    }

    private func handleVoidFall() {
        onEvent?(.ballFellOffTrack(position: ballPosition))
        if lives > 1 {
            lives -= 1
        }
        // Respawn safely at last checkpoint
        ballPosition = lastCheckpointPos
        ballVelocity = .zero
        state = .ready
    }
}

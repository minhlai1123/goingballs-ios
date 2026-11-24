import Foundation
import simd

/**
 * AeroSphere 3D - Shared Physics Contract (iOS Native Implementation)
 * Document Authority: SPEC-PHYS-005-REV02.3, MTX-SCOPE-023-REV01.0
 * Standard SI Units: Meter (m), Second (s), Kilogram (kg), Newton (N), Radian (rad)
 */

public enum PhysicsConstants {
    // World Gravity - 2.0g Arcade Model (FROZEN BY PROJECT OWNER)
    public static let gravityMagnitude: Double = 19.620
    public static let worldGravity: Vector3D = Vector3D(x: 0.0, y: -19.620, z: 0.0)

    // Simulation Clock
    public static let fixedTimestepHz: Double = 60.0
    public static let fixedDeltaTime: Double = 1.0 / fixedTimestepHz

    // Ball Rigid Body Dynamics
    public static let ballRadius: Double = 0.500
    public static let ballMass: Double = 5.000
    public static let ballInertia: Double = (2.0 / 5.0) * ballMass * ballRadius * ballRadius // 0.500 kg*m^2

    // Material & Contact Properties
    public static let restitutionCoefficient: Double = 0.180
    public static let kineticFrictionCoefficient: Double = 0.450
    public static let staticFrictionCoefficient: Double = 0.650
    public static let rollingResistanceCoefficient: Double = 0.020

    // Gameplay Regulation Forces
    public static let arcadeGlideDamping: Double = 6.164
    public static let emergencyBrakeDeceleration: Double = 18.500

    // TC6 Option A Approved Target Specifications (Pending Prototype Validation)
    public static let tc6InitialVelocity: Double = 16.000
    public static let tc6TargetExitVelocity: Double = 13.500
    public static let tc6ExitVelocityTolerance: Double = 0.500
    public static let tc6KineticEnergyRetainedRatio: Double = 0.711914
    public static let tc6KineticEnergyLossRatio: Double = 0.288086

    // TC7 Input Calibration Target (Provisional)
    public static let tc7InputSwipeDp: Double = 50.0
    public static let tc7TargetDisplacementX: Double = 1.450
    public static let tc7SensitivityKInput: Double = 0.029
    public static let tc7AssumedResponseWindow: Double = 1.000

    // TC8 Touch Latency Budget (Target - Not Measured)
    public static let tc8MaxTouchToPhotonLatencyMs: Double = 35.0
}

public struct Vector3D: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static let zero = Vector3D(x: 0, y: 0, z: 0)
    public static let up = Vector3D(x: 0, y: 1, z: 0)
    public static let forward = Vector3D(x: 0, y: 0, z: 1)
    public static let right = Vector3D(x: 1, y: 0, z: 0)

    public static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    public static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    public static func * (lhs: Vector3D, rhs: Double) -> Vector3D {
        Vector3D(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    public static func / (lhs: Vector3D, rhs: Double) -> Vector3D {
        Vector3D(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }

    public static prefix func - (v: Vector3D) -> Vector3D {
        Vector3D(x: -v.x, y: -v.y, z: -v.z)
    }

    public func dot(_ other: Vector3D) -> Double {
        x * other.x + y * other.y + z * other.z
    }

    public func cross(_ other: Vector3D) -> Vector3D {
        Vector3D(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }

    public func lengthSquared() -> Double {
        x * x + y * y + z * z
    }

    public func length() -> Double {
        sqrt(lengthSquared())
    }

    public func normalized() -> Vector3D {
        let len = length()
        return len > 1e-9 ? self / len : .zero
    }

    public func distance(to other: Vector3D) -> Double {
        (self - other).length()
    }
}

public struct Quaternion: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double

    public init(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0, w: Double = 1.0) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public static let identity = Quaternion(x: 0, y: 0, z: 0, w: 1)

    public func normalized() -> Quaternion {
        let len = sqrt(x * x + y * y + z * z + w * w)
        guard len > 1e-9 else { return .identity }
        return Quaternion(x: x / len, y: y / len, z: z / len, w: w / len)
    }
}

public struct BallState: Equatable, Sendable {
    public var position: Vector3D
    public var velocity: Vector3D
    public var orientation: Quaternion
    public var angularVelocity: Vector3D
    public var isGrounded: Boolean

    public init(
        position: Vector3D = .zero,
        velocity: Vector3D = .zero,
        orientation: Quaternion = .identity,
        angularVelocity: Vector3D = .zero,
        isGrounded: Boolean = false
    ) {
        self.position = position
        self.velocity = velocity
        self.orientation = orientation
        self.angularVelocity = angularVelocity
        self.isGrounded = isGrounded
    }
}

public typealias Boolean = Bool

public struct RaycastHit: Equatable, Sendable {
    public var hasHit: Bool
    public var hitPoint: Vector3D
    public var normal: Vector3D
    public var distance: Double
    public var surfaceMaterialId: String

    public init(
        hasHit: Bool = false,
        hitPoint: Vector3D = .zero,
        normal: Vector3D = .up,
        distance: Double = 0.0,
        surfaceMaterialId: String = "default"
    ) {
        self.hasHit = hasHit
        self.hitPoint = hitPoint
        self.normal = normal
        self.distance = distance
        self.surfaceMaterialId = surfaceMaterialId
    }
}

public struct ContactEvent: Equatable, Sendable {
    public var contactPoint: Vector3D
    public var contactNormal: Vector3D
    public var penetrationDepth: Double
    public var relativeVelocity: Vector3D
    public var impulseMagnitude: Double

    public init(
        contactPoint: Vector3D,
        contactNormal: Vector3D,
        penetrationDepth: Double,
        relativeVelocity: Vector3D,
        impulseMagnitude: Double
    ) {
        self.contactPoint = contactPoint
        self.contactNormal = contactNormal
        self.penetrationDepth = penetrationDepth
        self.relativeVelocity = relativeVelocity
        self.impulseMagnitude = impulseMagnitude
    }
}

public protocol IBallController: AnyObject {
    func applyForce(_ force: Vector3D)
    func applyImpulse(_ impulse: Vector3D)
    func applyTorque(_ torque: Vector3D)
    func applyAngularImpulse(_ angularImpulse: Vector3D)
    func getBallState() -> BallState
    func resetBall(position: Vector3D, velocity: Vector3D)
}

public protocol ITrackCollider: AnyObject {
    func raycast(origin: Vector3D, direction: Vector3D, maxDistance: Double) -> RaycastHit
    func checkSweptSphere(start: Vector3D, end: Vector3D, radius: Double) -> RaycastHit
}

public protocol IPhysicsWorldBridge: AnyObject {
    func stepSimulation(deltaTime: Double)
    func setGravity(_ gravity: Vector3D)
    func getGravity() -> Vector3D
    func registerContactListener(_ listener: @escaping (ContactEvent) -> Void)
}

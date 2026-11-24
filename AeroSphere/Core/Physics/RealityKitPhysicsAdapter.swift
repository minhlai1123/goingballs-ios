import Foundation
import RealityKit
import simd

/**
 * RealityKit Physics Adapter implementing IBallController interface from PAL
 * Document Authority: WP01, WP03 - MTX-SCOPE-023-REV01.0
 */
public final class RealityKitPhysicsAdapter: IBallController {
    private weak var ballEntity: ModelEntity?

    public init(ballEntity: ModelEntity? = nil) {
        self.ballEntity = ballEntity
    }

    public func setEntity(_ entity: ModelEntity) {
        self.ballEntity = entity
    }

    public func applyForce(_ force: Vector3D) {
        let simdForce = SIMD3<Float>(Float(force.x), Float(force.y), Float(force.z))
        ballEntity?.applyLinearImpulse(simdForce * Float(PhysicsConstants.fixedDeltaTime), relativeTo: nil)
    }

    public func applyImpulse(_ impulse: Vector3D) {
        let simdImpulse = SIMD3<Float>(Float(impulse.x), Float(impulse.y), Float(impulse.z))
        ballEntity?.applyLinearImpulse(simdImpulse, relativeTo: nil)
    }

    public func applyTorque(_ torque: Vector3D) {
        let simdTorque = SIMD3<Float>(Float(torque.x), Float(torque.y), Float(torque.z))
        ballEntity?.applyAngularImpulse(simdTorque * Float(PhysicsConstants.fixedDeltaTime), relativeTo: nil)
    }

    public func applyAngularImpulse(_ angularImpulse: Vector3D) {
        let simdAngImp = SIMD3<Float>(Float(angularImpulse.x), Float(angularImpulse.y), Float(angularImpulse.z))
        ballEntity?.applyAngularImpulse(simdAngImp, relativeTo: nil)
    }

    public func getBallState() -> BallState {
        guard let entity = ballEntity else { return BallState() }
        let pos = entity.position
        let quat = entity.orientation
        return BallState(
            position: Vector3D(x: Double(pos.x), y: Double(pos.y), z: Double(pos.z)),
            velocity: Vector3D.zero,
            orientation: Quaternion(
                x: Double(quat.vector.x),
                y: Double(quat.vector.y),
                z: Double(quat.vector.z),
                w: Double(quat.vector.w)
            ),
            angularVelocity: Vector3D.zero,
            isGrounded: false
        )
    }

    public func resetBall(position: Vector3D, velocity: Vector3D = .zero) {
        ballEntity?.position = SIMD3<Float>(Float(position.x), Float(position.y), Float(position.z))
        ballEntity?.orientation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    }
}

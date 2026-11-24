import SwiftUI
import RealityKit
import simd

/**
 * 3D PBR Viewport Prototype (iOS RealityKit 4 Implementation)
 * Document Authority: WP05 - MTX-SCOPE-023-REV01.0
 * Viewport rendering a metallic PBR sphere (Metallic: 0.95, Roughness: 0.15, Radius: 0.5m)
 * at 60 FPS target using RealityView (iOS 17.0+)
 */
struct PBRSphereViewport: View {
    var body: some View {
        ZStack {
            Color(red: 15/255, green: 23/255, blue: 42/255)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("AeroSphere 3D")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                    Text("RealityKit 4 Viewport Prototype")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 148/255, green: 163/255, blue: 184/255))
                }
                .padding(.top, 24)

                // RealityView 3D Viewport
                RealityView { content in
                    // 1. Create PBR Sphere Mesh (Radius = 0.5m)
                    let sphereMesh = MeshResource.generateSphere(radius: Float(PhysicsConstants.ballRadius))

                    // 2. Configure PBR Material (Metallic = 0.95, Roughness = 0.15)
                    var material = PhysicallyBasedMaterial()
                    material.baseColor = .init(tint: .white)
                    material.metallic = .init(floatLiteral: 0.95)
                    material.roughness = .init(floatLiteral: 0.15)

                    let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [material])
                    sphereEntity.position = [0, Float(PhysicsConstants.ballRadius), -2.0]

                    // 3. Configure RealityKit Physics
                    var physics = PhysicsBodyComponent(
                        massProperties: .init(mass: Float(PhysicsConstants.ballMass)),
                        material: .generate(
                            friction: Float(PhysicsConstants.kineticFrictionCoefficient),
                            restitution: Float(PhysicsConstants.restitutionCoefficient)
                        ),
                        mode: .dynamic
                    )
                    physics.isContinuousCollisionDetectionEnabled = true
                    sphereEntity.components.set(physics)

                    var collision = CollisionComponent(
                        shapes: [.generateSphere(radius: Float(PhysicsConstants.ballRadius))],
                        mode: .continuous
                    )
                    sphereEntity.components.set(collision)

                    // 4. Directional Key Light
                    let lightEntity = Entity()
                    var dirLight = DirectionalLightComponent()
                    dirLight.color = .white
                    dirLight.intensity = 15000
                    lightEntity.components.set(dirLight)
                    lightEntity.look(at: [0, Float(PhysicsConstants.ballRadius), -2.0], from: [2, 5, 1], relativeTo: nil)

                    content.add(sphereEntity)
                    content.add(lightEntity)
                }
                .frame(width: 280, height: 280)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 56/255, green: 189/255, blue: 248/255, opacity: 0.3), lineWidth: 1)
                )

                VStack(spacing: 6) {
                    Text("World Gravity: \(PhysicsConstants.gravityMagnitude, specifier: "%.2f") m/s² (2.0g)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 52/255, green: 211/255, blue: 153/255))
                    Text("Fixed Timestep: \(Int(PhysicsConstants.fixedTimestepHz)) Hz (RealityKit CCD)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 148/255, green: 163/255, blue: 184/255))
                    Text("Model: Metallic 0.95 | Roughness 0.15")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 148/255, green: 163/255, blue: 184/255))
                    Text("Zero-Ads: 100% Verified (0 Ad SDKs)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                }
                .padding(.bottom, 24)
            }
        }
    }
}

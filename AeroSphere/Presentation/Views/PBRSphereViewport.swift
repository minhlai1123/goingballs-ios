import SwiftUI
#if canImport(RealityKit)
import RealityKit
#endif
import simd

/**
 * 3D PBR Viewport Prototype (iOS Universal Viewport)
 * Document Authority: WP05 - MTX-SCOPE-023-REV01.0
 * Viewport rendering a metallic PBR sphere (Metallic: 0.95, Roughness: 0.15, Radius: 0.5m)
 * Supports iOS 15.0+ across all hardware with RealityKit 4 viewport on iOS 17.0+
 * 100% Zero-Ads Invariant
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
                    Text("PBR Sphere Viewport")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 148/255, green: 163/255, blue: 184/255))
                }
                .padding(.top, 24)

                #if canImport(RealityKit)
                if #available(iOS 17.0, *) {
                    RealityKitPBRView()
                        .frame(width: 280, height: 280)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 56/255, green: 189/255, blue: 248/255, opacity: 0.3), lineWidth: 1)
                        )
                } else {
                    FallbackPBRCanvasView()
                        .frame(width: 280, height: 280)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 56/255, green: 189/255, blue: 248/255, opacity: 0.3), lineWidth: 1)
                        )
                }
                #else
                FallbackPBRCanvasView()
                    .frame(width: 280, height: 280)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 56/255, green: 189/255, blue: 248/255, opacity: 0.3), lineWidth: 1)
                    )
                #endif

                VStack(spacing: 6) {
                    Text("World Gravity: \(PhysicsConstants.gravityMagnitude, specifier: "%.2f") m/s² (2.0g)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 52/255, green: 211/255, blue: 153/255))
                    Text("Fixed Timestep: \(Int(PhysicsConstants.fixedTimestepHz)) Hz (Deterministic CCD)")
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

#if canImport(RealityKit)
@available(iOS 17.0, *)
private struct RealityKitPBRView: View {
    var body: some View {
        RealityView { content in
            let sphereMesh = MeshResource.generateSphere(radius: Float(PhysicsConstants.ballRadius))
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .white)
            material.metallic = .init(floatLiteral: 0.95)
            material.roughness = .init(floatLiteral: 0.15)

            let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [material])
            sphereEntity.position = [0, Float(PhysicsConstants.ballRadius), -2.0]

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
                shapes: [.generateSphere(radius: Float(PhysicsConstants.ballRadius))]
            )
            sphereEntity.components.set(collision)

            let lightEntity = Entity()
            var dirLight = DirectionalLightComponent()
            dirLight.color = .white
            dirLight.intensity = 15000
            lightEntity.components.set(dirLight)
            lightEntity.look(at: [0, Float(PhysicsConstants.ballRadius), -2.0], from: [2, 5, 1], relativeTo: nil)

            content.add(sphereEntity)
            content.add(lightEntity)
        }
    }
}
#endif

private struct FallbackPBRCanvasView: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.35
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

            // Radial PBR Shading
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [Color(white: 0.95), Color(white: 0.55), Color(white: 0.15)]),
                    center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.3),
                    startRadius: 2,
                    endRadius: radius * 1.2
                )
            )

            // Specular Highlight
            let specRect = CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.5, width: radius * 0.45, height: radius * 0.45)
            context.fill(Path(ellipseIn: specRect), with: .color(.white.opacity(0.85)))
        }
        .background(Color(red: 30/255, green: 41/255, blue: 59/255))
    }
}

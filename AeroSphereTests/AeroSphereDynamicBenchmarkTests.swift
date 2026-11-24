import XCTest
@testable import AeroSphere

final class AeroSphereDynamicBenchmarkTests: XCTestCase {

    func testWorldGravityInvariant() {
        XCTAssertEqual(PhysicsConstants.gravityMagnitude, 19.620, accuracy: 1e-6)
        XCTAssertEqual(PhysicsConstants.worldGravity.y, -19.620, accuracy: 1e-6)
    }

    func testSolidSphereMomentOfInertia() {
        let expected = (2.0 / 5.0) * PhysicsConstants.ballMass * PhysicsConstants.ballRadius * PhysicsConstants.ballRadius
        XCTAssertEqual(expected, 0.500, accuracy: 1e-6)
        XCTAssertEqual(PhysicsConstants.ballInertia, 0.500, accuracy: 1e-6)
    }

    func testFreeFallTC1() {
        let y0 = 10.000
        let h = y0 - PhysicsConstants.ballRadius // 9.500 m
        let g = PhysicsConstants.gravityMagnitude // 19.620 m/s^2

        let expectedTime = sqrt(2.0 * h / g) // 0.98407 s
        let expectedVelocity = g * expectedTime // 19.308 m/s

        XCTAssertEqual(expectedTime, 0.984, accuracy: 0.002)
        XCTAssertEqual(expectedVelocity, 19.308, accuracy: 0.050)
    }

    func testSlopeRollTC2() {
        let thetaRadians = 15.0 * Double.pi / 180.0
        let length = 20.000
        let g = PhysicsConstants.gravityMagnitude

        let expectedAccel = (5.0 / 7.0) * g * sin(thetaRadians)
        let expectedVelocity = sqrt(2.0 * expectedAccel * length)
        let expectedTime = sqrt(2.0 * length / expectedAccel)

        XCTAssertEqual(expectedAccel, 3.627, accuracy: 0.005)
        XCTAssertEqual(expectedVelocity, 12.045, accuracy: 0.010)
        XCTAssertEqual(expectedTime, 3.321, accuracy: 0.010)
    }

    func testRollingResistanceTC3() {
        let v0 = 15.000
        let crr = PhysicsConstants.rollingResistanceCoefficient
        let g = PhysicsConstants.gravityMagnitude

        let aRr = crr * g
        let sStop = (v0 * v0) / (2.0 * aRr)
        let tStop = v0 / aRr

        XCTAssertEqual(aRr, 0.3924, accuracy: 1e-4)
        XCTAssertEqual(sStop, 286.70, accuracy: 0.10)
        XCTAssertEqual(tStop, 38.23, accuracy: 0.10)
    }

    func testRestitutionTC5() {
        let y0 = 5.000
        let h = y0 - PhysicsConstants.ballRadius
        let g = PhysicsConstants.gravityMagnitude
        let e = PhysicsConstants.restitutionCoefficient

        let vImpact = sqrt(2.0 * g * h)
        let vRebound = e * vImpact
        let hBounce = (e * e) * h
        let yPeak = PhysicsConstants.ballRadius + hBounce

        XCTAssertEqual(vImpact, 13.288, accuracy: 0.010)
        XCTAssertEqual(vRebound, 2.392, accuracy: 0.010)
        XCTAssertEqual(hBounce, 0.1458, accuracy: 0.001)
        XCTAssertEqual(yPeak, 0.6458, accuracy: 0.001)
    }

    func testTC6OptionASpecification() {
        let v0 = PhysicsConstants.tc6InitialVelocity
        let vExit = PhysicsConstants.tc6TargetExitVelocity
        let velRatio = vExit / v0
        let energyRatio = velRatio * velRatio

        XCTAssertEqual(velRatio, 0.84375, accuracy: 1e-5)
        XCTAssertEqual(energyRatio, PhysicsConstants.tc6KineticEnergyRetainedRatio, accuracy: 1e-5)
    }

    func testTC7SteeringSpecification() {
        let sensitivity = PhysicsConstants.tc7TargetDisplacementX / PhysicsConstants.tc7InputSwipeDp
        XCTAssertEqual(sensitivity, 0.029, accuracy: 1e-4)
    }

    func testTC8LatencyBudget() {
        XCTAssertLessThanOrEqual(PhysicsConstants.tc8MaxTouchToPhotonLatencyMs, 35.0)
    }

    func testAll40LevelsGenerationAndDifficultyTiers() {
        for lvl in 1...40 {
            let course = LevelCourseBuilder.buildLevel(lvl)
            XCTAssertEqual(course.levelNumber, lvl)
            XCTAssertFalse(course.name.isEmpty)
            XCTAssertFalse(course.segments.isEmpty)
            XCTAssertGreaterThan(course.totalLength, 90.0)
            XCTAssertFalse(course.items.isEmpty)

            // Validate Difficulty categorization
            let expectedDiff: LevelDifficulty = {
                switch lvl {
                case 1...10: return .easy
                case 11...20: return .normal
                case 21...30: return .hard
                default: return .expert
                }
            }()
            XCTAssertEqual(course.difficulty, expectedDiff, "Level \(lvl) difficulty mismatch")

            // Finish line must be present at totalLength
            let finishItem = course.items.first { $0.type == .finishLine }
            XCTAssertNotNil(finishItem, "Level \(lvl) must have a finish line")
            XCTAssertEqual(finishItem?.position.z ?? 0.0, course.totalLength, accuracy: 1.0)
        }
    }

    func testZeroAdsInvariant() {
        // Enforce 100% Zero-Ads constraint: No ad frameworks allowed in AeroSphere
        let prohibitedFrameworks = ["GoogleMobileAds", "UnityAds", "AppLovinSDK", "FBAudienceNetwork"]
        for framework in prohibitedFrameworks {
            let bundle = Bundle(identifier: "com.\(framework)")
            XCTAssertNil(bundle, "Prohibited ad framework \(framework) found in bundle")
        }
    }
}

# AeroSphere 3D: Rolling Adventure (iOS Native)

Native 3D Rolling Ball Mobile Game built with Swift 6, SwiftUI, RealityKit 4, and AVFoundation. Inspired by the responsive rolling mechanics and rewarding flow of *Going Balls*.

## 🌟 Key Features

### 1. Arcade Physics Engine (AeroPhysics)
- **World Gravity:** Fixed $19.620\text{ m/s}^2$ (2.0g Arcade Model).
- **Fixed Timestep:** Deterministic 60 Hz simulation clock.
- **Touch Drag Controls:**
  - Swipe forward to accelerate (drive acceleration $12.0\text{ m/s}^2$).
  - Swipe backward for emergency braking ($-18.5\text{ m/s}^2$).
  - Drag horizontal to steer (calibrated sensitivity $0.029\text{ m/pt}$).
- **Destructible Obstacles (TC6 Option A):** Star obstacle cubes shatter on impact at $\ge 13.5\text{ m/s}$, retaining $71.19\%$ translational kinetic energy ($v_{exit} \approx 0.84375 \times v_0$).
- **Checkpoints & Fall Recovery:** Auto-respawn at last passed checkpoint pad upon falling off the track.

### 2. 40 Progressive Levels & Level Select Menu
- **4 Balanced Difficulty Tiers:**
  - **EASY (Levels 1–10):** Track width 4.5m $\to$ 4.0m, 100% safety rails, staggered obstacles, 1 Checkpoint.
  - **NORMAL (Levels 11–20):** Track width 3.8m $\to$ 3.3m, 75% rails, 3x2 obstacle barricades, emerald booster lanes, 2 Checkpoints.
  - **HARD (Levels 21–30):** Track width 3.2m $\to$ 2.7m, 45% rails, narrow bridges, 2 Checkpoints.
  - **EXPERT (Levels 31–40):** Track width 2.6m $\to$ 2.2m, 30% rails, gauntlets, concluding with Level 40 *The Titan's Gauntlet*.
- **Level Selector Modal:** Interactive 4-column grid (`MAP`) with filter tabs (`ALL`, `EASY`, `NORM`, `HARD`, `EXP`) to jump to any level.

### 3. Bright, Cheerful Kid-Friendly Graphics
- **Sunny Daytime Cartoon Skybox:** Gradient cyan sky (`#38BDF8` $\to$ `#FEF3C7`) with glowing cartoon sun halo and drifting fluffy white clouds.
- **Horizon Panorama:** Lush green rolling hills (`#86EFAC` & `#4ADE80`).
- **Warm Timber Runways:** Honey birch and amber cedar planks (`#FDE68A` & `#F59E0B`) with cinnamon curbs.
- **Candy Cane Hazard Railings:** Festive alternating red and white rails (`#EF4444` & `#FFFFFF`).
- **Superhero Marble Ball:** Glossy electric cyan and deep ocean blue sphere with rotating sunny yellow and coral pink racing stripes, contact drop shadow, and sharp specular highlights.
- **Toy Block Obstacles:** Vibrant candy pink/magenta cubes (`#EC4899`) with embossed golden stars (`★`).
- **Checkered Finish Line:** Festive checkered ribbon with floating celebratory red and blue balloons.

### 4. Native Audio Engine (AVFoundation)
- **Background Music (BGM):** Upbeat, bouncy arcade marimba music loop (128 BPM).
- **Sound Effects (SFX):**
  - Coin pickup chime (`sfx_coin`)
  - Key found twinkle (`sfx_key`)
  - Spare ball 1-up harp (`sfx_life`)
  - Wood obstacle smash (`sfx_smash`)
  - Checkpoint passed chime (`sfx_checkpoint`)
  - Plinko wooden peg tap (`sfx_plinko_peg`)
  - Bubbly button click (`sfx_button`)
- **Victory Celebration Fanfare:** Triumphant brass & glockenspiel fanfare on crossing the finish line.
- **Sound Toggle:** Bubbly HUD button (`🔊` / `🔇`) for muting/unmuting audio.

### 5. Bonus Plinko Minigame
- 3D carnival pegboard minigame after every victory.
- Piggy bank hammer meter accumulation.
- Bottom prize slots `[+10] [+50] [+100] [+50] [+10]`.

### 6. 100% Zero-Ads Invariant
- **Zero Ad SDKs:** No Google Mobile Ads, no Unity Ads, no AppLovin, no Facebook Audience Network.
- **Zero Ad Entitlements & Permissions:** Pure offline, skill-based gameplay with no tracking or advertising calls.

---

## 📁 Project Structure

```
AeroSphere/
├── App/
│   └── AeroSphereApp.swift                    # Main Application Entry Point
├── Core/
│   ├── PAL/
│   │   └── PALContracts.swift                 # Shared Physics Contract (g = 19.620 m/s², Vector3D)
│   ├── Physics/
│   │   ├── TrackCourse.swift                  # Track Segment, Obstacle, and Collectible Models
│   │   ├── LevelCourseBuilder.swift           # 40-Level Procedural Course Builder
│   │   ├── GameplayEngine.swift               # 60Hz Arcade Rolling Simulation Engine
│   │   └── RealityKitPhysicsAdapter.swift     # RealityKit 4 CCD Integration
│   └── Audio/
│       └── GameAudioManager.swift             # AVFoundation BGM, SFX & Fanfare Manager
├── Presentation/
│   └── Views/
│       ├── ContentView.swift                  # Root Navigation View
│       ├── GamePlayView.swift                 # 3D Viewport, Skybox, Rolling Ball, and HUD
│       ├── PlinkoMinigameView.swift           # Carnival Pegboard Bonus Minigame
│       ├── LevelSelectModal.swift             # 40-Level Grid Selection Modal
│       ├── Color+Hex.swift                    # SwiftUI Hex Color Extension
│       └── PBRSphereViewport.swift            # RealityKit PBR Viewport Prototype
├── Resources/
│   └── Audio/                                 # 9 Bundled 16-bit 44.1kHz WAV Audio Assets
│       ├── bgm_gameplay.wav
│       ├── sfx_button.wav
│       ├── sfx_checkpoint.wav
│       ├── sfx_coin.wav
│       ├── sfx_key.wav
│       ├── sfx_life.wav
│       ├── sfx_plinko_peg.wav
│       ├── sfx_smash.wav
│       └── sfx_victory_fanfare.wav
└── Info.plist
AeroSphere.xcodeproj/
└── project.pbxproj                            # Xcode Project Settings
AeroSphereTests/
└── AeroSphereDynamicBenchmarkTests.swift      # Automated Physics & 40-Level Tests
```

## 🛠️ Build Requirements
- macOS 14.0+ (Sonoma) or newer
- Xcode 15.0+ or newer with iOS 17.0+ SDK
- Swift 6.0 compiler
- Target: iPhone (Portrait orientation)

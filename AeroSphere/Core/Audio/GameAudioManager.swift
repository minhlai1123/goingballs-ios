import Foundation
import AVFoundation

/**
 * AeroSphere 3D Native iOS Audio Manager
 * Manages low-latency arcade SFX, looping BGM, and Victory Fanfare via AVFoundation
 * 100% Zero-Ads, fully offline, kid-friendly audio design
 */
public final class GameAudioManager: @unchecked Sendable {

    public static let shared = GameAudioManager()

    private var bgmPlayer: AVAudioPlayer?
    private var victoryPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    public private(set) var isMuted: Bool = false

    private init() {
        configureAudioSession()
        preloadSounds()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func preloadSounds() {
        let soundFiles = [
            "sfx_coin",
            "sfx_key",
            "sfx_life",
            "sfx_smash",
            "sfx_checkpoint",
            "sfx_plinko_peg",
            "sfx_button"
        ]

        for name in soundFiles {
            if let player = createPlayer(for: name) {
                player.prepareToPlay()
                sfxPlayers[name] = player
            }
        }
    }

    private func createPlayer(for resourceName: String) -> AVAudioPlayer? {
        // Try loading from main bundle Resources/Audio or direct Bundle.main
        let url = Bundle.main.url(forResource: resourceName, withExtension: "wav", subdirectory: "Resources/Audio")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "wav")

        guard let soundURL = url else {
            print("Sound file not found: \(resourceName).wav")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            return player
        } catch {
            print("Failed to create player for \(resourceName): \(error)")
            return nil
        }
    }

    private func playSfx(named name: String, volume: Float = 1.0) {
        guard !isMuted else { return }
        if let player = sfxPlayers[name] {
            player.volume = volume
            player.currentTime = 0
            player.play()
        } else if let player = createPlayer(for: name) {
            player.volume = volume
            player.play()
            sfxPlayers[name] = player
        }
    }

    public func playCoin() { playSfx(named: "sfx_coin", volume: 0.85) }
    public func playKey() { playSfx(named: "sfx_key", volume: 1.0) }
    public func playLife() { playSfx(named: "sfx_life", volume: 1.0) }
    public func playSmash() { playSfx(named: "sfx_smash", volume: 1.0) }
    public func playCheckpoint() { playSfx(named: "sfx_checkpoint", volume: 0.9) }
    public func playPlinkoPeg() { playSfx(named: "sfx_plinko_peg", volume: 0.7) }
    public func playButton() { playSfx(named: "sfx_button", volume: 0.6) }

    public func startBgm() {
        guard !isMuted else { return }
        if bgmPlayer == nil {
            bgmPlayer = createPlayer(for: "bgm_gameplay")
            bgmPlayer?.numberOfLoops = -1 // Infinite loop
            bgmPlayer?.volume = 0.50
        }
        if bgmPlayer?.isPlaying == false {
            bgmPlayer?.play()
        }
    }

    public func pauseBgm() {
        bgmPlayer?.pause()
    }

    public func resumeBgm() {
        guard !isMuted else { return }
        bgmPlayer?.play()
    }

    public func stopBgm() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }

    public func playVictoryFanfare() {
        guard !isMuted else { return }
        pauseBgm()

        victoryPlayer?.stop()
        victoryPlayer = createPlayer(for: "sfx_victory_fanfare")
        victoryPlayer?.volume = 0.85
        victoryPlayer?.play()
    }

    public func stopVictoryFanfare() {
        victoryPlayer?.stop()
        victoryPlayer = nil
    }

    @discardableResult
    public func toggleMute() -> Bool {
        isMuted.toggle()
        if isMuted {
            pauseBgm()
            stopVictoryFanfare()
        } else {
            resumeBgm()
        }
        return isMuted
    }
}

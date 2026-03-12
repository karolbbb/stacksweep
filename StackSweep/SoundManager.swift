//
//  SoundManager.swift
//  StackSweep
//

import AVFoundation
import UIKit

enum GameSound {
    case select, move, clear, sweep, gameOver, levelComplete
    case coin, powerUp, bomb, freeze, streak, star, bigCombo, purchase
}

final class SoundManager {

    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let format: AVAudioFormat

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("SoundManager: engine failed to start – \(error)")
        }
        playerNode.play()

        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Public API

    func play(_ sound: GameSound) {
        guard let buffer = makeBuffer(for: sound) else { return }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)

        switch sound {
        case .select:        lightImpact.impactOccurred()
        case .move:          mediumImpact.impactOccurred()
        case .clear:         rigidImpact.impactOccurred()
        case .sweep:         heavyImpact.impactOccurred()
        case .levelComplete: notificationFeedback.notificationOccurred(.success)
        case .gameOver:      notificationFeedback.notificationOccurred(.error)
        case .coin:          lightImpact.impactOccurred(intensity: 0.5)
        case .powerUp:       mediumImpact.impactOccurred()
        case .bomb:          heavyImpact.impactOccurred()
        case .freeze:        mediumImpact.impactOccurred(intensity: 0.6)
        case .streak:        notificationFeedback.notificationOccurred(.success)
        case .star:          lightImpact.impactOccurred()
        case .bigCombo:      rigidImpact.impactOccurred()
        case .purchase:      notificationFeedback.notificationOccurred(.success)
        }
    }

    // MARK: - Buffer Synthesis

    private func makeBuffer(for sound: GameSound) -> AVAudioPCMBuffer? {
        switch sound {
        case .select:        return squareWave(frequency: 400, duration: 0.03, volume: 0.15)
        case .move:          return squareWave(frequency: 200, duration: 0.05, volume: 0.12)
        case .clear:         return sweepTone(startFreq: 200, endFreq: 800, duration: 0.2, volume: 0.18)
        case .sweep:         return sweepTone(startFreq: 800, endFreq: 200, duration: 0.3, volume: 0.2)
        case .gameOver:      return sweepTone(startFreq: 400, endFreq: 100, duration: 0.4, volume: 0.2)
        case .levelComplete: return arpeggio(frequencies: [262, 330, 392, 523], noteDuration: 0.1, volume: 0.18)
        case .coin:          return arpeggio(frequencies: [800, 1200], noteDuration: 0.04, volume: 0.12)
        case .powerUp:       return sweepTone(startFreq: 300, endFreq: 900, duration: 0.15, volume: 0.16)
        case .bomb:          return sweepTone(startFreq: 150, endFreq: 40, duration: 0.35, volume: 0.22)
        case .freeze:        return arpeggio(frequencies: [1000, 1200, 1400], noteDuration: 0.06, volume: 0.1)
        case .streak:        return arpeggio(frequencies: [330, 440, 550, 660], noteDuration: 0.08, volume: 0.15)
        case .star:          return arpeggio(frequencies: [523, 659, 784], noteDuration: 0.07, volume: 0.14)
        case .bigCombo:      return sweepTone(startFreq: 200, endFreq: 1200, duration: 0.25, volume: 0.2)
        case .purchase:      return arpeggio(frequencies: [400, 500, 600, 800], noteDuration: 0.06, volume: 0.15)
        }
    }

    private func squareWave(frequency: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let period = sampleRate / frequency
        for i in 0..<Int(frameCount) {
            let phase = Double(i).truncatingRemainder(dividingBy: period)
            data[i] = (phase < period / 2 ? volume : -volume)
        }
        applyFade(data, frameCount: Int(frameCount))
        return buffer
    }

    private func sweepTone(startFreq: Double, endFreq: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        var phase: Double = 0
        for i in 0..<Int(frameCount) {
            let t = Double(i) / Double(frameCount)
            let freq = startFreq + (endFreq - startFreq) * t
            phase += freq / sampleRate
            let sample = sin(phase * 2 * .pi)
            data[i] = Float(sample) * volume
        }
        applyFade(data, frameCount: Int(frameCount))
        return buffer
    }

    private func arpeggio(frequencies: [Double], noteDuration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let totalDuration = noteDuration * Double(frequencies.count)
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let framesPerNote = Int(sampleRate * noteDuration)
        for (noteIdx, freq) in frequencies.enumerated() {
            let period = sampleRate / freq
            for i in 0..<framesPerNote {
                let globalIdx = noteIdx * framesPerNote + i
                guard globalIdx < Int(frameCount) else { break }
                let phase = Double(i).truncatingRemainder(dividingBy: period)
                let env = 1.0 - (Double(i) / Double(framesPerNote))
                data[globalIdx] = (phase < period / 2 ? volume : -volume) * Float(env)
            }
        }
        return buffer
    }

    private func applyFade(_ data: UnsafeMutablePointer<Float>, frameCount: Int) {
        let fadeFrames = min(200, frameCount / 4)
        for i in 0..<fadeFrames {
            let env = Float(i) / Float(fadeFrames)
            data[i] *= env
            data[frameCount - 1 - i] *= env
        }
    }
}

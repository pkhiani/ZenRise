import SwiftUI
import AVFoundation
import AudioToolbox

class SoundManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    func playSound(_ sound: ClockThemeSettings.AlarmSound) {
        print("🔊 SoundManager.playSound called for: \(sound.filename)")
        stopSound()  // Stop any playing sound first
        
        // Try to find the sound file with .mp3 extension
        guard let path = Bundle.main.path(forResource: sound.filename, ofType: "mp3") else {
            print("❌ Could not find sound file: \(sound.filename).mp3")
            return
        }
        
        print("✅ Found sound file at: \(path)")
        let url = URL(fileURLWithPath: path)
        
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured")
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.8  // Fixed volume level
            audioPlayer?.numberOfLoops = 0  // Play once
            audioPlayer?.prepareToPlay()
            print("✅ Audio player prepared")
            
            if audioPlayer?.play() == true {
                print("✅ Playing sound: \(sound.filename)")
            } else {
                print("❌ Failed to play sound: \(sound.filename)")
            }
        } catch {
            print("❌ Could not create audio player for \(sound.filename): \(error.localizedDescription)")
            // Fallback to system sound
            print("🔊 Playing fallback system sound")
            AudioServicesPlaySystemSound(1005) // Default notification sound
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
} 
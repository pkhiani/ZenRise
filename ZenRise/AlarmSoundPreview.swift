import SwiftUI
import AVFoundation

class SoundManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    func playSound(_ sound: ClockThemeSettings.AlarmSound, volume: Double) {
        stopSound()  // Stop any playing sound first
        
        guard let path = Bundle.main.path(forResource: sound.filename, ofType: "mp3") else {
            print("Could not find sound file: \(sound.filename)")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = Float(volume)
            audioPlayer?.play()
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
} 
import SwiftUI
import AVFoundation

public class ClockThemeSettings: ObservableObject {
    @Published public var currentHandColor: Color = .blue
    @Published public var targetHandColor: Color = .green
    @Published public var showArcs: Bool = true
    @Published public var clockStyle: ClockStyle = .modern
    @Published public var clockSize: ClockSize = .medium
    @Published public var selectedSound: AlarmSound = .default
    @Published public var volume: Double = 0.8
    
    public init() {}
    
    public enum ClockStyle: String, CaseIterable {
        case modern = "Modern"
        case classic = "Classic"
        case minimal = "Minimal"
    }
    
    public enum ClockSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        public var dimension: CGFloat {
            switch self {
            case .small: return 220
            case .medium: return 280
            case .large: return 340
            }
        }
    }
    
    public enum AlarmSound: String, CaseIterable {
        case `default` = "Default"
        case gentle = "Gentle"
        case nature = "Nature"
        case energetic = "Energetic"
        case classic = "Classic"
        
        var filename: String {
            switch self {
            case .default: return "default_alarm"
            case .gentle: return "gentle_chime"
            case .nature: return "morning_birds"
            case .energetic: return "upbeat_alarm"
            case .classic: return "classic_bell"
            }
        }
    }
} 
import SwiftUI
import AVFoundation

public class ClockThemeSettings: ObservableObject, Codable {
    @Published public var currentHandColor: Color = .mint {
        didSet {
            saveSettings()
        }
    }
    @Published public var targetHandColor: Color = .green {
        didSet {
            saveSettings()
        }
    }
    @Published public var showArcs: Bool = true {
        didSet {
            saveSettings()
        }
    }
    @Published public var clockStyle: ClockStyle = .modern {
        didSet {
            saveSettings()
        }
    }
    @Published public var clockSize: ClockSize = .medium {
        didSet {
            saveSettings()
        }
    }
    @Published public var selectedSound: AlarmSound = .default {
        didSet {
            saveSettings()
        }
    }
    
    // Weak reference to avoid retain cycles
    weak var settingsManager: UserSettingsManager?
    
    public init() {}
    
    private func saveSettings() {
        print("🎨 Saving theme settings - Current: \(currentHandColor), Target: \(targetHandColor)")
        settingsManager?.saveSettingsNow()
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case currentHandColor, targetHandColor, showArcs, clockStyle, clockSize, selectedSound
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentHandColor = try container.decode(Color.self, forKey: .currentHandColor)
        targetHandColor = try container.decode(Color.self, forKey: .targetHandColor)
        showArcs = try container.decode(Bool.self, forKey: .showArcs)
        clockStyle = try container.decode(ClockStyle.self, forKey: .clockStyle)
        clockSize = try container.decode(ClockSize.self, forKey: .clockSize)
        selectedSound = try container.decode(AlarmSound.self, forKey: .selectedSound)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentHandColor, forKey: .currentHandColor)
        try container.encode(targetHandColor, forKey: .targetHandColor)
        try container.encode(showArcs, forKey: .showArcs)
        try container.encode(clockStyle, forKey: .clockStyle)
        try container.encode(clockSize, forKey: .clockSize)
        try container.encode(selectedSound, forKey: .selectedSound)
    }
    
    public enum ClockStyle: String, CaseIterable, Codable {
        case modern = "Modern"
        case classic = "Classic"
        case minimal = "Minimal"
    }
    
    public enum ClockSize: String, CaseIterable, Codable {
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
    
    public enum AlarmSound: String, CaseIterable, Codable {
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

// MARK: - Color Codable Extension
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as RGB values first
        if let rgbData = try? container.decode([String: Double].self) {
            let red = rgbData["red"] ?? 0.0
            let green = rgbData["green"] ?? 0.0
            let blue = rgbData["blue"] ?? 0.0
            let alpha = rgbData["alpha"] ?? 1.0
            
            self = Color(red: red, green: green, blue: blue, opacity: alpha)
        } else {
            // Fallback to color name for backward compatibility
            let colorName = try container.decode(String.self)
            switch colorName {
            case "blue": self = .blue
            case "green": self = .green
            case "red": self = .red
            case "orange": self = .orange
            case "yellow": self = .yellow
            case "purple": self = .purple
            case "pink": self = .pink
            case "gray": self = .gray
            case "black": self = .black
            case "white": self = .white
            case "cyan": self = .cyan
            case "mint": self = .mint
            case "indigo": self = .indigo
            case "teal": self = .teal
            case "brown": self = .brown
            default: self = .mint // Default to mint instead of blue
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        // Convert to RGB values and store them directly
        let resolvedColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgbData = [
            "red": Double(red),
            "green": Double(green),
            "blue": Double(blue),
            "alpha": Double(alpha)
        ]
        
        try container.encode(rgbData)
    }
} 
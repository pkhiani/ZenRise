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
    
    // Codable properties for persistence
    private var codableCurrentHandColor: CodableColor {
        get { CodableColor(currentHandColor) }
        set { currentHandColor = newValue.color }
    }
    
    private var codableTargetHandColor: CodableColor {
        get { CodableColor(targetHandColor) }
        set { targetHandColor = newValue.color }
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
        settingsManager?.saveSettingsNow()
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case currentHandColor = "codableCurrentHandColor", targetHandColor = "codableTargetHandColor", showArcs, clockStyle, clockSize, selectedSound
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        codableCurrentHandColor = try container.decode(CodableColor.self, forKey: .currentHandColor)
        codableTargetHandColor = try container.decode(CodableColor.self, forKey: .targetHandColor)
        showArcs = try container.decode(Bool.self, forKey: .showArcs)
        clockStyle = try container.decode(ClockStyle.self, forKey: .clockStyle)
        clockSize = try container.decode(ClockSize.self, forKey: .clockSize)
        selectedSound = try container.decode(AlarmSound.self, forKey: .selectedSound)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(codableCurrentHandColor, forKey: .currentHandColor)
        try container.encode(codableTargetHandColor, forKey: .targetHandColor)
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

// MARK: - CodableColor Wrapper
struct CodableColor: Codable {
    let color: Color
    
    init(_ color: Color) {
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as RGB values first
        if let rgbData = try? container.decode([String: Double].self) {
            let red = rgbData["red"] ?? 0.0
            let green = rgbData["green"] ?? 0.0
            let blue = rgbData["blue"] ?? 0.0
            let alpha = rgbData["alpha"] ?? 1.0
            
            self.color = Color(red: red, green: green, blue: blue, opacity: alpha)
        } else {
            // Fallback to color name for backward compatibility
            let colorName = try container.decode(String.self)
            switch colorName {
            case "blue": self.color = .blue
            case "green": self.color = .green
            case "red": self.color = .red
            case "orange": self.color = .orange
            case "yellow": self.color = .yellow
            case "purple": self.color = .purple
            case "pink": self.color = .pink
            case "gray": self.color = .gray
            case "black": self.color = .black
            case "white": self.color = .white
            case "cyan": self.color = .cyan
            case "mint": self.color = .mint
            case "indigo": self.color = .indigo
            case "teal": self.color = .teal
            case "brown": self.color = .brown
            default: self.color = .mint // Default to mint instead of blue
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        // Convert to RGB values and store them directly
        let resolvedColor = UIColor(color)
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
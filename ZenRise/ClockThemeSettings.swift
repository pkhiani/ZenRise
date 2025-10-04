import SwiftUI
import AVFoundation

public class ClockThemeSettings: ObservableObject, Codable {
    @Published public var currentHandColor: Color = .mint
    @Published public var targetHandColor: Color = .green
    @Published public var showArcs: Bool = true
    @Published public var clockStyle: ClockStyle = .modern
    @Published public var clockSize: ClockSize = .medium
    @Published public var selectedSound: AlarmSound = .default
    
    public init() {}
    
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
        default: self = .blue // Default fallback
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        let colorName: String
        if self == .blue { colorName = "blue" }
        else if self == .green { colorName = "green" }
        else if self == .red { colorName = "red" }
        else if self == .orange { colorName = "orange" }
        else if self == .yellow { colorName = "yellow" }
        else if self == .purple { colorName = "purple" }
        else if self == .pink { colorName = "pink" }
        else if self == .gray { colorName = "gray" }
        else if self == .black { colorName = "black" }
        else if self == .white { colorName = "white" }
        else if self == .cyan { colorName = "cyan" }
        else if self == .mint { colorName = "mint" }
        else if self == .indigo { colorName = "indigo" }
        else if self == .teal { colorName = "teal" }
        else if self == .brown { colorName = "brown" }
        else { colorName = "blue" } // Default fallback
        
        try container.encode(colorName)
    }
} 
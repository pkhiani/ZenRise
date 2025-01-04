import SwiftUI

public struct ClockDialView: View {
    let currentTime: Date
    let targetTime: Date
    @ObservedObject var themeSettings: ClockThemeSettings
    
    public init(currentTime: Date, targetTime: Date, themeSettings: ClockThemeSettings) {
        self.currentTime = currentTime
        self.targetTime = targetTime
        self.themeSettings = themeSettings
    }
    
    private func angleForTime(_ date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        // Convert time to angle (360 degrees / 12 hours = 30 degrees per hour)
        let hourAngle = Double(hour % 12) * 30.0 + Double(minute) * 0.5
        return hourAngle
    }
    
    private var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    public var body: some View {
        ZStack {
            // Clock face background
            Circle()
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 4)
            
            // Hour marks
            if themeSettings.clockStyle != .minimal {
                ForEach(0..<12) { hour in
                    VStack {
                        Rectangle()
                            .fill(hour % 3 == 0 ? Color.primary : Color.gray.opacity(0.3))
                            .frame(width: hour % 3 == 0 ? 3 : 2, 
                                   height: themeSettings.clockStyle == .modern ? (hour % 3 == 0 ? 20 : 10) : 15)
                        
                        if hour % 3 == 0 && themeSettings.clockStyle == .modern {
                            Text("\(hour == 0 ? 12 : hour)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .offset(y: -4)
                        }
                    }
                    .offset(y: -themeSettings.clockSize.dimension/2.8)
                    .rotationEffect(.degrees(Double(hour) * 30))
                }
            }
            
            if themeSettings.showArcs {
                // Target time arc
                Circle()
                    .trim(from: 0, to: angleForTime(targetTime) / 360)
                    .stroke(themeSettings.targetHandColor.opacity(0.2), lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                
                // Current time arc
                Circle()
                    .trim(from: 0, to: angleForTime(currentTime) / 360)
                    .stroke(themeSettings.currentHandColor.opacity(0.2), lineWidth: 30)
                    .rotationEffect(.degrees(-90))
            }
            
            // Target time hand
            HandView(
                time: targetTime,
                color: themeSettings.targetHandColor,
                width: 4,
                label: timeFormatter.string(from: targetTime),
                style: themeSettings.clockStyle
            )
            
            // Current time hand
            HandView(
                time: currentTime,
                color: themeSettings.currentHandColor,
                width: 4,
                label: timeFormatter.string(from: currentTime),
                style: themeSettings.clockStyle
            )
            
            // Center decoration
            Circle()
                .fill(Color.primary)
                .frame(width: 15, height: 15)
            
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 8, height: 8)
        }
        .frame(width: themeSettings.clockSize.dimension, height: themeSettings.clockSize.dimension)
    }
}

struct HandView: View {
    let time: Date
    let color: Color
    let width: CGFloat
    let label: String
    let style: ClockThemeSettings.ClockStyle
    
    private func angleForTime(_ date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return Double(hour % 12) * 30.0 + Double(minute) * 0.5
    }
    
    var body: some View {
        ZStack {
            // Hand
            Rectangle()
                .fill(color)
                .frame(width: width, height: style == .minimal ? 75 : 95)
                .offset(y: style == .minimal ? -37.5 : -47.5)
            
            if style != .minimal {
                // Time label background
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .offset(y: -75)
                
                // Time label
                Text(label)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
                    .offset(y: -75)
            }
        }
        .rotationEffect(.degrees(angleForTime(time)))
    }
}

#Preview {
    ClockDialView(
        currentTime: Date(),
        targetTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        themeSettings: ClockThemeSettings()
    )
    .padding()
    .background(Color(.systemGroupedBackground))
} 
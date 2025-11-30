import SwiftUI
import WidgetKit

/// Circular lockscreen widget view
struct CircularLockscreenWidgetView: View {
    let entry: ZenRiseWidgetEntry
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Progress ring
            if entry.isAlarmEnabled && entry.daysRemaining > 0 {
                Circle()
                    .trim(from: 0, to: min(1.0, 1.0 - (Double(entry.daysRemaining) / 30.0)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            
            // Content
            VStack(spacing: 2) {
                if entry.isAlarmEnabled {
                    Text("\(entry.daysRemaining)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("days")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "alarm")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
    }
}

/// Inline lockscreen widget view
struct InlineLockscreenWidgetView: View {
    let entry: ZenRiseWidgetEntry
    
    var body: some View {
        if entry.isAlarmEnabled {
            HStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 12))
                Text("\(entry.daysRemaining) days left")
                    .font(.system(size: 14, weight: .medium))
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "alarm")
                    .font(.system(size: 12))
                Text("Enable alarm to start")
                    .font(.system(size: 14, weight: .medium))
            }
        }
    }
}

/// Small home screen widget view
struct SmallHomeScreenWidgetView: View {
    let entry: ZenRiseWidgetEntry
    
    var body: some View {
        VStack(spacing: 4) {
            // Main content
            if entry.isAlarmEnabled {
                Spacer(minLength: 0)
                
                VStack(spacing: 2) {
                    Text("\(entry.daysRemaining)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text("days remaining")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
                
                // Times - more compact layout
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("CURRENT")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(entry.currentWakeUpTime.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("TARGET")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(entry.targetWakeUpTime.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 2)
            } else {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "alarm")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.green.opacity(0.6))
                    
                    Text("Enable alarm\nto start")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
        .padding(10)
    }
}

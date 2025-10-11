import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var alarmManager: UnifiedAlarmManager
    @State private var refreshTrigger = false
    let wakeUpSchedule: WakeUpSchedule
    
    private var nextWakeUpTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeUpSchedule.timeUntilTarget.nextWakeUp)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section with App Icon
                    VStack(spacing: 20) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.green.opacity(0.8),
                                            Color.mint.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("ZenRise")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Transform your wake-up routine")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Active Alarm Status or Ready to Start (moved here)
                        if settingsManager.settings.isAlarmEnabled {
                            AlarmStatusCard(
                                nextWakeUpTime: nextWakeUpTimeString,
                                daysRemaining: wakeUpSchedule.timeUntilTarget.days,
                                startDate: settingsManager.settings.startDate,
                                wakeUpSchedule: wakeUpSchedule
                            )
                        } else {
                            EnableAlarmCard()
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // Clock Section
                    VStack(spacing: 24) {
                        ClockDialView(
                            currentTime: settingsManager.settings.currentWakeUpTime,
                            targetTime: settingsManager.settings.targetWakeUpTime,
                            themeSettings: settingsManager.settings.themeSettings
                        )
                        
                        // Time Display Cards
                        HStack(spacing: 16) {
                            TimeCard(
                                title: "Current",
                                time: settingsManager.settings.currentWakeUpTime,
                                color: settingsManager.settings.themeSettings.currentHandColor
                            )
                            
                            TimeCard(
                                title: "Target",
                                time: settingsManager.settings.targetWakeUpTime,
                                color: settingsManager.settings.themeSettings.targetHandColor
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .wakeTimeUpdated)) { _ in
            refreshTrigger.toggle()
        }
    }
}

// MARK: - Supporting Views

struct TimeCard: View {
    let title: String
    let time: Date
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: title == "Current" ? "clock.fill" : "target")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }
}

struct AlarmStatusCard: View {
    let nextWakeUpTime: String
    let daysRemaining: Int
    let startDate: Date?
    let wakeUpSchedule: WakeUpSchedule
    @EnvironmentObject var alarmManager: UnifiedAlarmManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Status Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.mint.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alarm Active")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Your journey is in progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 0)
            }
            
            // Next Alarm Info
            VStack(spacing: 8) {
                Text("Next alarm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(nextWakeUpTime)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Progress Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(daysRemaining) days")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("until target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Manual Action Buttons
                HStack(spacing: 12) {
                    // Snooze Button
                    Button(action: {
                        print("🔔 Manual snooze button pressed")
                        alarmManager.recordSnooze()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.caption)
                            Text("Snooze")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                    
                    // Completed Button
                    Button(action: {
                        print("✅ Manual completed button pressed")
                        Task {
                            await handleManualAlarmCompletion()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Completed")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private func handleManualAlarmCompletion() async {
        print("✅ Manual alarm completion triggered")
        
        // Call the alarm manager to handle completion
        if #available(iOS 26.0, *) {
            // For AlarmKit, we need to manually trigger the completion logic
            await alarmManager.alarmKitManager.handleManualAlarmCompletion()
        }
        
        print("✅ Manual alarm completion processed")
    }
}

struct EnableAlarmCard: View {
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.2),
                                Color.mint.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "alarm")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Ready to start?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Enable your alarm in settings to begin your wake-up journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Call to action
            NavigationLink(destination: SettingsView()) {
                HStack(spacing: 8) {
                    Text("Go to Settings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "gear")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    HomeView(wakeUpSchedule: WakeUpSchedule(
        currentWakeUpTime: Date(),
        targetWakeUpTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    ))
    .environmentObject(UserSettingsManager())
    .environmentObject(NotificationManager())
} 
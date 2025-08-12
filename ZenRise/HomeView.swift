import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var notificationManager: NotificationManager
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
                    // Header Section
                    VStack(spacing: 16) {
                        Text("ZenRise")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Transform your wake-up routine")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                    
                    // Status Section
                    if settingsManager.settings.isAlarmEnabled {
                        AlarmStatusCard(
                            nextWakeUpTime: nextWakeUpTimeString,
                            daysRemaining: wakeUpSchedule.timeUntilTarget.days,
                            startDate: settingsManager.settings.startDate
                        )
                    } else {
                        EnableAlarmCard()
                    }
                    
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
    }
}

// MARK: - Supporting Views

struct TimeCard: View {
    let title: String
    let time: Date
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(time.formatted(date: .omitted, time: .shortened))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct AlarmStatusCard: View {
    let nextWakeUpTime: String
    let daysRemaining: Int
    let startDate: Date?
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Header
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Alarm Active")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
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
                
                NavigationLink {
                    if let startDate = startDate {
                        ProgressView(
                            wakeUpSchedule: WakeUpSchedule(
                                currentWakeUpTime: Date(),
                                targetWakeUpTime: Date()
                            ),
                            startDate: startDate
                        )
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("View Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .disabled(startDate == nil)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

struct EnableAlarmCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Ready to start?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Enable your alarm in settings to begin your wake-up journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
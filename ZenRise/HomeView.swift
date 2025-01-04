import SwiftUI

struct HomeView: View {
    let currentWakeUpTime: Date
    let targetWakeUpTime: Date
    let isAlarmEnabled: Bool
    let nextWakeUpTimeString: String
    let timeUntilTarget: (days: Int, nextWakeUp: Date)
    let startDate: Date?
    @ObservedObject var themeSettings: ClockThemeSettings
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("ZenRise")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ClockDialView(
                    currentTime: currentWakeUpTime,
                    targetTime: targetWakeUpTime,
                    themeSettings: themeSettings
                )
                .padding(.vertical)
                
                VStack(alignment: .leading, spacing: 20) {
                    if isAlarmEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next alarm: \(nextWakeUpTimeString)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("\(timeUntilTarget.days) days until target wake-up time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        NavigationLink {
                            if let startDate = startDate {
                                ProgressView(
                                    currentWakeUpTime: currentWakeUpTime,
                                    targetWakeUpTime: targetWakeUpTime,
                                    startDate: startDate,
                                    totalDays: timeUntilTarget.days
                                )
                            }
                        } label: {
                            HStack {
                                Text("View Progress")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        .disabled(startDate == nil)
                    } else {
                        Text("Enable alarm in settings to start your wake-up journey")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }
} 
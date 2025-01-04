import SwiftUI

struct ProgressView: View {
    let currentWakeUpTime: Date
    let targetWakeUpTime: Date
    let startDate: Date
    let totalDays: Int
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var daysCompleted: Int {
        let days = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(days, totalDays)
    }
    
    private var progressPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return Double(daysCompleted) / Double(totalDays)
    }
    
    private func wakeUpTimeForDay(dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentWakeUpTime)
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetWakeUpTime)
        
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        let minutesAdjustment = 15 * dayOffset
        
        var adjustedComponents = DateComponents()
        let adjustedMinutes = (currentMinutes - minutesAdjustment + 24 * 60) % (24 * 60)
        
        adjustedComponents.hour = adjustedMinutes / 60
        adjustedComponents.minute = adjustedMinutes % 60
        
        return calendar.date(from: adjustedComponents) ?? currentWakeUpTime
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Overview
                VStack(spacing: 16) {
                    Text("Progress Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ProgressBar(progress: progressPercentage)
                        .frame(height: 20)
                        .padding(.horizontal)
                    
                    Text("\(daysCompleted) of \(totalDays) days completed")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
                
                // Daily Schedule
                VStack(alignment: .leading, spacing: 16) {
                    Text("Wake-up Schedule")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(0..<totalDays, id: \.self) { day in
                        DayProgressRow(
                            day: day + 1,
                            wakeUpTime: wakeUpTimeForDay(dayOffset: day),
                            isCompleted: day < daysCompleted
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress")
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                Rectangle()
                    .fill(Color.blue)
                    .cornerRadius(10)
                    .frame(width: geometry.size.width * progress)
                    .animation(.spring(), value: progress)
            }
        }
    }
}

struct DayProgressRow: View {
    let day: Int
    let wakeUpTime: Date
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Text("Day \(day)")
                .font(.headline)
            
            Spacer()
            
            Text(wakeUpTime.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .opacity(isCompleted ? 0.8 : 1)
    }
} 
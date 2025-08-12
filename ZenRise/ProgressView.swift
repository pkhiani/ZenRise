import SwiftUI

struct ProgressView: View {
    let wakeUpSchedule: WakeUpSchedule
    let startDate: Date
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var daysCompleted: Int {
        let days = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(days, wakeUpSchedule.timeUntilTarget.days)
    }
    
    private var progressPercentage: Double {
        guard wakeUpSchedule.timeUntilTarget.days > 0 else { return 0 }
        return Double(daysCompleted) / Double(wakeUpSchedule.timeUntilTarget.days)
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
                    
                    Text("\(daysCompleted) of \(wakeUpSchedule.timeUntilTarget.days) days completed")
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
                    
                    ForEach(0..<wakeUpSchedule.timeUntilTarget.days, id: \.self) { day in
                        DayProgressRow(
                            day: day + 1,
                            wakeUpTime: wakeUpSchedule.wakeUpTimeForDay(day),
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

#Preview {
    NavigationStack {
        ProgressView(
            wakeUpSchedule: WakeUpSchedule(
                currentWakeUpTime: Date(),
                targetWakeUpTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            ),
            startDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        )
    }
} 
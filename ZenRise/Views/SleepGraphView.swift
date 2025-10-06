//
//  SleepGraphView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI
import Charts

struct SleepGraphView: View {
    let sleepData: [SleepData]
    
    private var filteredData: [SleepData] {
        // Show last 14 days of daily data
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return sleepData.filter { $0.date >= cutoffDate }.sorted { $0.date < $1.date }
    }
    
    private var chartData: [SleepChartData] {
        filteredData.map { data in
            SleepChartData(
                date: data.date,
                actualWakeTime: data.actualWakeTime,
                targetWakeTime: data.targetWakeTime,
                isSuccessful: data.isSuccessful,
                snoozeCount: data.snoozeCount
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Sleep Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Chart
            if chartData.isEmpty {
                EmptyStateView()
            } else {
                SimpleSleepChart(data: chartData)
                    .frame(height: 300)
                    .padding(.bottom, 8)
            }
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .mint, label: "Target Time", isDashed: true)
                LegendItem(color: .green, label: "On Time", isDashed: false)
                LegendItem(color: .orange, label: "Late", isDashed: false)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct SleepChartData: Identifiable {
    let id = UUID()
    let date: Date
    let actualWakeTime: Date
    let targetWakeTime: Date
    let isSuccessful: Bool
    let snoozeCount: Int
}

struct LegendItem: View {
    let color: Color
    let label: String
    let isDashed: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if isDashed {
                Rectangle()
                    .fill(color)
                    .frame(width: 20, height: 2)
                    .overlay(
                        Rectangle()
                            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            
            Text(label)
        }
    }
}

struct SimpleSleepChart: View {
    let data: [SleepChartData]
    
    private var minHour: Double {
        guard !data.isEmpty else { return 6.0 }
        let allTimes = data.flatMap { [normalizeTime($0.actualWakeTime), normalizeTime($0.targetWakeTime)] }
        let minTime = allTimes.min() ?? Date()
        let calculatedMin = timeToHour(minTime)
        // Ensure minimum is at least 5:30 AM and maximum 9:00 AM for reasonable wake-up range
        return max(calculatedMin - 0.5, 4.0) // 5:30 AM
    }
    
    private var maxHour: Double {
        guard !data.isEmpty else { return 8.0 }
        let allTimes = data.flatMap { [normalizeTime($0.actualWakeTime), normalizeTime($0.targetWakeTime)] }
        let maxTime = allTimes.max() ?? Date()
        let calculatedMax = timeToHour(maxTime)
        // Ensure maximum is at most 9:00 AM for reasonable wake-up range
        return min(calculatedMax + 0.5, 11.0) // 9:00 AM
    }
    
    // Normalize time to today's date for consistent Y-axis positioning
    private func normalizeTime(_ time: Date) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var normalizedComponents = DateComponents()
        normalizedComponents.year = todayComponents.year
        normalizedComponents.month = todayComponents.month
        normalizedComponents.day = todayComponents.day
        normalizedComponents.hour = timeComponents.hour
        normalizedComponents.minute = timeComponents.minute
        
        return calendar.date(from: normalizedComponents) ?? time
    }
    
    private var hourRange: Double { 
        // Use a fixed range for consistent wake-up time display (4:00 AM to 11:00 AM = 7 hours)
        return 7.0
    }
    
    private func timeToHour(_ time: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return Double(totalMinutes) / 60.0
    }
    
    private func yPosition(for time: Date) -> CGFloat {
        let normalizedTime = normalizeTime(time)
        let hour = timeToHour(normalizedTime)
        // Use fixed range from 4:00 AM (4.0) to 11:00 AM (11.0)
        let minRange = 4.0
        let maxRange = 11.0
        let normalizedHour = (hour - minRange) / (maxRange - minRange)
        return CGFloat(1.0 - normalizedHour) * 180 + 40 // Reduced padding
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func generateGridHours() -> [Double] {
        guard !data.isEmpty else { return [4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0] }
        
        // Create a reasonable range for wake-up times (4:00 AM to 11:00 AM)
        let minRange = 4.0  // 4:00 AM
        let maxRange = 11.0  // 11:00 AM
        
        var hours: [Double] = []
        var currentHour = minRange
        
        while currentHour <= maxRange {
            hours.append(currentHour)
            currentHour += 1.0 // 1-hour intervals for better spacing
        }
        
        return hours
    }
    
    private func formatHour(_ hour: Double) -> String {
        let hourInt = Int(hour)
        let minute = hour.truncatingRemainder(dividingBy: 1.0) * 60
        let minuteInt = Int(minute)
        
        if minuteInt == 0 {
            return "\(hourInt):00"
        } else {
            return "\(hourInt):\(String(format: "%02d", minuteInt))"
        }
    }
    
    var body: some View {
        ZStack {
            // Background grid
            VStack(spacing: 0) {
                let gridHours = generateGridHours()
                ForEach(gridHours, id: \.self) { hour in
                    HStack(spacing: 6) {
                        Text(formatHour(hour))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                        
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 1)
                    }
                    .frame(height: 30)
                }
            }
            
            // Chart content
            GeometryReader { geometry in
                ZStack {
                    // Target time line
                    Path { path in
                        guard !data.isEmpty else { return }
                        
                        let firstX = geometry.size.width * 0.15
                        let lastX = geometry.size.width * 0.85
                        let targetY = yPosition(for: normalizeTime(data.first!.targetWakeTime))
                        
                        path.move(to: CGPoint(x: firstX, y: targetY))
                        path.addLine(to: CGPoint(x: lastX, y: targetY))
                    }
                    .stroke(Color.mint.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Data points with connecting lines
                    ForEach(data.indices, id: \.self) { index in
                        let point = data[index]
                        let x = geometry.size.width * 0.15 + (geometry.size.width * 0.7) * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let y = yPosition(for: normalizeTime(point.actualWakeTime))
                        
                        // Draw connecting line to previous point
                        if index > 0 {
                            let prevPoint = data[index - 1]
                            let prevX = geometry.size.width * 0.15 + (geometry.size.width * 0.7) * CGFloat(index - 1) / CGFloat(max(data.count - 1, 1))
                            let prevY = yPosition(for: normalizeTime(prevPoint.actualWakeTime))
                            
                            Path { path in
                                path.move(to: CGPoint(x: prevX, y: prevY))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            .stroke(Color(.systemGray4), lineWidth: 1)
                        }
                        
                        // Data point
                        Circle()
                            .fill(point.isSuccessful ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .position(x: x, y: y)
                        
                        // Date label at bottom of chart
                        Text(formatDate(point.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .position(x: x, y: geometry.size.height - 20)
                    }
                }
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Data Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start using ZenRise to see your sleep progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
}

#Preview {
    let sampleData = [
        SleepData(
            date: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
            actualWakeTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 15)) ?? Date(),
            targetWakeTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date(),
            snoozeCount: 2,
            isSuccessful: false,
            alarmEnabled: true
        ),
        SleepData(
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            actualWakeTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 25)) ?? Date(),
            targetWakeTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date(),
            snoozeCount: 0,
            isSuccessful: true,
            alarmEnabled: true
        ),
        SleepData(
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
            actualWakeTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 20)) ?? Date(),
            targetWakeTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date(),
            snoozeCount: 1,
            isSuccessful: true,
            alarmEnabled: true
        )
    ]
    
    SleepGraphView(sleepData: sampleData)
        .padding()
}

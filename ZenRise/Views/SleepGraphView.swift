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
        VStack(spacing: 20) {
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
                        .frame(height: 350)
                        .padding(.bottom, 20)
                }
            
            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .mint, label: "Target Time", isDashed: true)
                LegendItem(color: .green, label: "On Time", isDashed: false)
                LegendItem(color: .orange, label: "Late", isDashed: false)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
        let allTimes = data.flatMap { [$0.actualWakeTime, $0.targetWakeTime] }
        let minTime = allTimes.min() ?? Date()
        return timeToHour(minTime)
    }
    
    private var maxHour: Double {
        guard !data.isEmpty else { return 8.0 }
        let allTimes = data.flatMap { [$0.actualWakeTime, $0.targetWakeTime] }
        let maxTime = allTimes.max() ?? Date()
        return timeToHour(maxTime)
    }
    
    private var hourRange: Double { 
        let range = maxHour - minHour
        return max(range, 1.0) // Ensure minimum range of 1 hour
    }
    
    private func timeToHour(_ time: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return Double(totalMinutes) / 60.0
    }
    
    private func yPosition(for time: Date) -> CGFloat {
        let hour = timeToHour(time)
        let normalizedHour = (hour - minHour) / hourRange
        return CGFloat(1.0 - normalizedHour) * 180 + 50 // 50px padding to avoid overlap
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func generateGridHours() -> [Double] {
        guard !data.isEmpty else { return [6.0, 7.0, 8.0] }
        
        // Add some padding to the range
        let paddedMin = floor(minHour) - 0.5
        let paddedMax = ceil(maxHour) + 0.5
        
        var hours: [Double] = []
        var currentHour = paddedMin
        
        while currentHour <= paddedMax {
            hours.append(currentHour)
            currentHour += 0.5 // 30-minute intervals
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
                    HStack(spacing: 8) {
                        Text(formatHour(hour))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .trailing)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 1)
                    }
                    .frame(height: 40)
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
                        let targetY = yPosition(for: data.first!.targetWakeTime)
                        
                        path.move(to: CGPoint(x: firstX, y: targetY))
                        path.addLine(to: CGPoint(x: lastX, y: targetY))
                    }
                    .stroke(Color.mint.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Data points with connecting lines
                    ForEach(data.indices, id: \.self) { index in
                        let point = data[index]
                        let x = geometry.size.width * 0.15 + (geometry.size.width * 0.7) * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let y = yPosition(for: point.actualWakeTime)
                        
                        // Draw connecting line to previous point
                        if index > 0 {
                            let prevPoint = data[index - 1]
                            let prevX = geometry.size.width * 0.15 + (geometry.size.width * 0.7) * CGFloat(index - 1) / CGFloat(max(data.count - 1, 1))
                            let prevY = yPosition(for: prevPoint.actualWakeTime)
                            
                            Path { path in
                                path.move(to: CGPoint(x: prevX, y: prevY))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
                            .position(x: x, y: geometry.size.height - 40)
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

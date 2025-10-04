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
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    private var filteredData: [SleepData] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
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
            // Header with period selector
            HStack {
                Text("Sleep Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            // Chart
            if chartData.isEmpty {
                EmptyStateView()
            } else {
                SimpleSleepChart(data: chartData)
                    .frame(height: 200)
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
    
    private var minHour: Double { 5.0 }
    private var maxHour: Double { 9.0 }
    private var hourRange: Double { maxHour - minHour }
    
    private func yPosition(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let hour = Double(totalMinutes) / 60.0
        
        let normalizedHour = (hour - minHour) / hourRange
        return CGFloat(1.0 - normalizedHour) * 160 + 20 // 20px padding
    }
    
    var body: some View {
        ZStack {
            // Background grid
            VStack(spacing: 0) {
                ForEach(5...9, id: \.self) { hour in
                    HStack {
                        Text("\(hour):00")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                        
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
                        
                        let firstX = geometry.size.width * 0.1
                        let lastX = geometry.size.width * 0.9
                        let targetY = yPosition(for: data.first!.targetWakeTime)
                        
                        path.move(to: CGPoint(x: firstX, y: targetY))
                        path.addLine(to: CGPoint(x: lastX, y: targetY))
                    }
                    .stroke(Color.mint.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Data points
                    ForEach(data.indices, id: \.self) { index in
                        let point = data[index]
                        let x = geometry.size.width * 0.1 + (geometry.size.width * 0.8) * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let y = yPosition(for: point.actualWakeTime)
                        
                        Circle()
                            .fill(point.isSuccessful ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
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

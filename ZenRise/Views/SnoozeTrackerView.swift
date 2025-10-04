//
//  SnoozeTrackerView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI
import Charts

// MARK: - Supporting Data Structures
struct WeeklySnoozeData: Identifiable {
    let id = UUID()
    let weekStart: Date
    let weekEnd: Date
    let totalSnoozes: Int
    let averageSnoozes: Double
    let maxSnoozes: Int
    let daysWithData: Int
}

// MARK: - Supporting Views
struct SnoozeStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct DailySnoozeRow: View {
    let data: SleepData
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: data.date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: data.date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(dateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(0..<max(5, data.snoozeCount + 1), id: \.self) { index in
                    Circle()
                        .fill(index < data.snoozeCount ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text("\(data.snoozeCount)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct WeeklySnoozeRow: View {
    let data: WeeklySnoozeData
    
    private var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: data.weekStart)
        let end = formatter.string(from: data.weekEnd)
        return "\(start) - \(end)"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekRange)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(data.daysWithData) days tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(data.totalSnoozes)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("snoozes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WeeklySnoozeBar: View {
    let weekData: WeeklySnoozeData
    let maxSnoozes: Int
    
    private var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekData.weekStart)
        let end = formatter.string(from: weekData.weekEnd)
        return "\(start) - \(end)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(weekRange)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange)
                    .frame(width: maxSnoozes > 0 ? CGFloat(weekData.totalSnoozes) / CGFloat(maxSnoozes) * 200 : 0, height: 20)
            }
            .frame(width: 200)
            
            Text("\(weekData.totalSnoozes)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct EmptySnoozeState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Snooze Data")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start tracking your wake-up habits to see snooze patterns")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Main View
struct SnoozeTrackerView: View {
    @EnvironmentObject var sleepTracker: SleepBehaviorTracker
    @State private var refreshTrigger = UUID()
    
    private var last7DaysData: [SleepData] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sleepTracker.sleepData.filter { $0.date >= sevenDaysAgo }.sorted { $0.date > $1.date }
    }
    
    private var weeklySnoozeData: [WeeklySnoozeData] {
        let calendar = Calendar.current
        var weeklyData: [WeeklySnoozeData] = []
        
        for i in 0..<4 { // Last 4 weeks
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: Date()) ?? Date()
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            
            let weekSleepData = sleepTracker.sleepData.filter { data in
                data.date >= weekStart && data.date <= weekEnd
            }
            
            let totalSnoozes = weekSleepData.reduce(0) { $0 + $1.snoozeCount }
            let averageSnoozes = weekSleepData.isEmpty ? 0.0 : Double(totalSnoozes) / Double(weekSleepData.count)
            let maxSnoozes = weekSleepData.map { $0.snoozeCount }.max() ?? 0
            
            weeklyData.append(WeeklySnoozeData(
                weekStart: weekStart,
                weekEnd: weekEnd,
                totalSnoozes: totalSnoozes,
                averageSnoozes: averageSnoozes,
                maxSnoozes: maxSnoozes,
                daysWithData: weekSleepData.count
            ))
        }
        
        return Array(weeklyData.reversed())
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Snooze Tracking")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Daily view only
            DailySnoozeView(data: last7DaysData)
                .id(refreshTrigger) // Force refresh when trigger changes
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onChange(of: sleepTracker.sleepData) { oldValue, newValue in
            refreshTrigger = UUID()
        }
    }
}

struct DailySnoozeView: View {
    let data: [SleepData]
    
    private var totalSnoozes: Int {
        data.reduce(0) { $0 + $1.snoozeCount }
    }
    
    private var averageSnoozes: Double {
        guard !data.isEmpty else { return 0 }
        return Double(totalSnoozes) / Double(data.count)
    }
    
    private var maxSnoozes: Int {
        data.map { $0.snoozeCount }.max() ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Summary stats
            HStack(spacing: 20) {
                SnoozeStatCard(
                    title: "Total",
                    value: "\(totalSnoozes)",
                    subtitle: "snoozes",
                    color: .orange
                )
                
                SnoozeStatCard(
                    title: "Average",
                    value: String(format: "%.1f", averageSnoozes),
                    subtitle: "per day",
                    color: .blue
                )
                
                SnoozeStatCard(
                    title: "Max",
                    value: "\(maxSnoozes)",
                    subtitle: "snoozes",
                    color: .red
                )
            }
            
            // Daily breakdown
            if data.isEmpty {
                EmptySnoozeState()
            } else {
                VStack(spacing: 8) {
                    ForEach(data.prefix(7), id: \.date) { dayData in
                        DailySnoozeRow(data: dayData)
                    }
                }
            }
        }
    }
}

struct WeeklySnoozeView: View {
    let data: [WeeklySnoozeData]
    
    var body: some View {
        VStack(spacing: 16) {
            // Weekly chart
            if data.isEmpty {
                EmptySnoozeState()
            } else {
                VStack(spacing: 8) {
                    ForEach(data.prefix(4), id: \.weekStart) { weekData in
                        WeeklySnoozeBar(weekData: weekData, maxSnoozes: data.map { $0.totalSnoozes }.max() ?? 1)
                    }
                }
                .frame(height: 150)
            }
            
            // Weekly list
            if !data.isEmpty {
                VStack(spacing: 8) {
                    ForEach(data.prefix(3), id: \.weekStart) { weekData in
                        WeeklySnoozeRow(data: weekData)
                    }
                }
            }
        }
    }
}

#Preview {
    SnoozeTrackerView()
        .environmentObject(SleepBehaviorTracker())
        .padding()
}
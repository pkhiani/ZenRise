//
//  SleepBehavior.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import Foundation

struct SleepData: Codable, Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let actualWakeTime: Date
    let targetWakeTime: Date
    let snoozeCount: Int
    let isSuccessful: Bool // Woke up at or before target time
    let alarmEnabled: Bool
    
    var timeDifference: TimeInterval {
        actualWakeTime.timeIntervalSince(targetWakeTime)
    }
    
    var isEarlyOrOnTime: Bool {
        actualWakeTime <= targetWakeTime
    }
    
    var successPercentage: Double {
        isEarlyOrOnTime ? 1.0 : max(0.0, 1.0 - (timeDifference / 3600.0)) // Decrease by hour if late
    }
}

struct SnoozePattern: Codable {
    let date: Date
    let snoozeCount: Int
    let totalSnoozeTime: TimeInterval // Total time spent snoozing in seconds
    
    var snoozeTimeInMinutes: Int {
        Int(totalSnoozeTime / 60)
    }
}

struct WeeklySummary: Codable {
    let weekStartDate: Date
    let weekEndDate: Date
    let totalDays: Int
    let successfulDays: Int
    let totalSnoozes: Int
    let averageSnoozeTime: TimeInterval
    let streakDays: Int
    
    var successRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(successfulDays) / Double(totalDays)
    }
    
    var averageSnoozeTimeInMinutes: Int {
        Int(averageSnoozeTime / 60)
    }
}

class SleepBehaviorTracker: ObservableObject {
    @Published var sleepData: [SleepData] = []
    @Published var snoozePatterns: [SnoozePattern] = []
    @Published var weeklySummaries: [WeeklySummary] = []
    
    private let userDefaults = UserDefaults.standard
    private let sleepDataKey = "SleepData"
    private let snoozePatternsKey = "SnoozePatterns"
    private let weeklySummariesKey = "WeeklySummaries"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Management
    
    func addSleepData(_ data: SleepData) {
        sleepData.append(data)
        saveData()
        updateWeeklySummaries()
    }
    
    func addSnoozePattern(_ pattern: SnoozePattern) {
        if let index = snoozePatterns.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: pattern.date) }) {
            snoozePatterns[index] = pattern
        } else {
            snoozePatterns.append(pattern)
        }
        saveData()
    }
    
    private func updateWeeklySummaries() {
        let calendar = Calendar.current
        let groupedData = Dictionary(grouping: sleepData) { sleepData in
            calendar.dateInterval(of: .weekOfYear, for: sleepData.date)?.start ?? sleepData.date
        }
        
        weeklySummaries = groupedData.map { weekStart, data in
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let successfulDays = data.filter { $0.isSuccessful }.count
            let totalSnoozes = data.reduce(0) { $0 + $1.snoozeCount }
            let totalSnoozeTime = data.reduce(0.0) { $0 + TimeInterval($1.snoozeCount * 300) } // 5 min per snooze
            let averageSnoozeTime = data.isEmpty ? 0 : totalSnoozeTime / Double(data.count)
            
            return WeeklySummary(
                weekStartDate: weekStart,
                weekEndDate: weekEnd,
                totalDays: data.count,
                successfulDays: successfulDays,
                totalSnoozes: totalSnoozes,
                averageSnoozeTime: averageSnoozeTime,
                streakDays: calculateCurrentStreak()
            )
        }.sorted { $0.weekStartDate > $1.weekStartDate }
    }
    
    func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let sortedData = sleepData.sorted { $0.date > $1.date }
        var streak = 0
        
        for data in sortedData {
            if data.isSuccessful {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    func getLast7DaysData() -> [SleepData] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sleepData.filter { $0.date >= sevenDaysAgo }.sorted { $0.date > $1.date }
    }
    
    func getLast30DaysData() -> [SleepData] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return sleepData.filter { $0.date >= thirtyDaysAgo }.sorted { $0.date > $1.date }
    }
    
    func getAverageWakeTime() -> Date {
        guard !sleepData.isEmpty else { return Date() }
        let totalSeconds = sleepData.reduce(0) { total, data in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: data.actualWakeTime)
            return total + (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60
        }
        let averageSeconds = totalSeconds / sleepData.count
        let averageHour = averageSeconds / 3600
        let averageMinute = (averageSeconds % 3600) / 60
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = averageHour
        components.minute = averageMinute
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(sleepData) {
            userDefaults.set(encoded, forKey: sleepDataKey)
        }
        if let encoded = try? JSONEncoder().encode(snoozePatterns) {
            userDefaults.set(encoded, forKey: snoozePatternsKey)
        }
        if let encoded = try? JSONEncoder().encode(weeklySummaries) {
            userDefaults.set(encoded, forKey: weeklySummariesKey)
        }
    }
    
    private func loadData() {
        if let data = userDefaults.data(forKey: sleepDataKey),
           let decoded = try? JSONDecoder().decode([SleepData].self, from: data) {
            sleepData = decoded
        }
        if let data = userDefaults.data(forKey: snoozePatternsKey),
           let decoded = try? JSONDecoder().decode([SnoozePattern].self, from: data) {
            snoozePatterns = decoded
        }
        if let data = userDefaults.data(forKey: weeklySummariesKey),
           let decoded = try? JSONDecoder().decode([WeeklySummary].self, from: data) {
            weeklySummaries = decoded
        }
        updateWeeklySummaries()
    }
    
    // MARK: - Sample Data for Development
    
    func generateSampleData() {
        let calendar = Calendar.current
        var sampleData: [SleepData] = []
        
        for i in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let targetTime = calendar.date(from: DateComponents(hour: 6, minute: 30)) ?? Date()
            
            // Simulate some variation in wake times
            let variation = Int.random(in: -15...30) // -15 to +30 minutes
            let actualTime = calendar.date(byAdding: .minute, value: variation, to: targetTime) ?? targetTime
            
            let snoozeCount = Int.random(in: 0...3)
            let isSuccessful = actualTime <= targetTime
            
            let data = SleepData(
                date: date,
                actualWakeTime: actualTime,
                targetWakeTime: targetTime,
                snoozeCount: snoozeCount,
                isSuccessful: isSuccessful,
                alarmEnabled: true
            )
            
            sampleData.append(data)
        }
        
        sleepData = sampleData
        saveData()
        updateWeeklySummaries()
    }
    
    func clearAllData() {
        sleepData.removeAll()
        snoozePatterns.removeAll()
        weeklySummaries.removeAll()
        saveData()
    }
}

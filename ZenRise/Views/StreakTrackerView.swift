//
//  StreakTrackerView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct StreakTrackerView: View {
    let sleepData: [SleepData]
    @EnvironmentObject var settingsManager: UserSettingsManager
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var showCelebration = false
    
    private var streakData: StreakData {
        calculateStreakData()
    }
    
    private var userGoal: Int {
        // Calculate goal based on user's target wake time vs current wake time
        let calendar = Calendar.current
        let currentTime = settingsManager.settings.currentWakeUpTime
        let targetTime = settingsManager.settings.targetWakeUpTime
        
        let currentMinutes = calendar.component(.hour, from: currentTime) * 60 + calendar.component(.minute, from: currentTime)
        let targetMinutes = calendar.component(.hour, from: targetTime) * 60 + calendar.component(.minute, from: targetTime)
        
        let differenceMinutes = currentMinutes - targetMinutes
        
        // Goal is based on how many days it would take to reach target at 15 minutes per day
        let daysNeeded = max(1, Int(ceil(Double(differenceMinutes) / 15.0)))
        return min(daysNeeded, 30) // Cap at 30 days
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Success Streak")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Main streak display
            ZStack {
                // Background circle with progress
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 12
                    )
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(Double(currentStreak) / Double(userGoal), 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: currentStreak)
                
                // Streak number
                VStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .scaleEffect(showCelebration ? 1.2 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCelebration)
                    
                    Text("days")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            
            // Streak stats
            HStack(spacing: 20) {
                StreakStatCard(
                    title: "Current",
                    value: "\(currentStreak)",
                    subtitle: "days",
                    color: .green,
                    isHighlighted: currentStreak > 0
                )
                
                StreakStatCard(
                    title: "Best",
                    value: "\(bestStreak)",
                    subtitle: "days",
                    color: .blue,
                    isHighlighted: false
                )
                
                StreakStatCard(
                    title: "Goal",
                    value: "\(userGoal)",
                    subtitle: "days",
                    color: .orange,
                    isHighlighted: false
                )
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to \(userGoal)-day goal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(currentStreak)/\(userGoal)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(Double(currentStreak) / Double(userGoal), 1.0), height: 8)
                            .animation(.easeInOut(duration: 0.8), value: currentStreak)
                    }
                }
                .frame(height: 8)
            }
            
            // Motivational message
            MotivationalMessage(
                currentStreak: currentStreak,
                bestStreak: bestStreak
            )
            
            // Recent streak history
            if !streakData.recentDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Days")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(streakData.recentDays.prefix(7), id: \.date) { day in
                            StreakDayRow(day: day)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            updateStreakData()
        }
        .onChange(of: sleepData) { _ in
            updateStreakData()
        }
    }
    
    private func updateStreakData() {
        let newStreakData = calculateStreakData()
        currentStreak = newStreakData.currentStreak
        bestStreak = newStreakData.bestStreak
        
        // Show celebration for new streaks
        if currentStreak > 0 && currentStreak % 5 == 0 {
            showCelebration = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showCelebration = false
            }
        }
    }
    
    private func calculateStreakData() -> StreakData {
        let sortedData = sleepData.sorted { $0.date > $1.date }
        
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0
        var recentDays: [StreakDay] = []
        
        // Calculate current streak
        for data in sortedData {
            if data.isSuccessful {
                currentStreak += 1
            } else {
                break
            }
        }
        
        // Calculate best streak
        for data in sortedData.reversed() {
            if data.isSuccessful {
                tempStreak += 1
                bestStreak = max(bestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }
        
        // Get recent days data
        let last7Days = sortedData.prefix(7)
        recentDays = last7Days.map { data in
            StreakDay(
                date: data.date,
                isSuccessful: data.isSuccessful,
                wakeTime: data.actualWakeTime,
                targetTime: data.targetWakeTime
            )
        }
        
        return StreakData(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            recentDays: recentDays
        )
    }
}

struct StreakData {
    let currentStreak: Int
    let bestStreak: Int
    let recentDays: [StreakDay]
}

struct StreakDay: Identifiable {
    let id = UUID()
    let date: Date
    let isSuccessful: Bool
    let wakeTime: Date
    let targetTime: Date
}

struct StreakStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title3)
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
                .fill(isHighlighted ? color.opacity(0.15) : color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHighlighted ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct MotivationalMessage: View {
    let currentStreak: Int
    let bestStreak: Int
    
    private var message: String {
        switch currentStreak {
        case 0:
            return "Start your journey to better mornings!"
        case 1...2:
            return "Great start! Keep it going! 🌅"
        case 3...6:
            return "You're building a great habit! 💪"
        case 7...13:
            return "One week strong! Amazing progress! 🎉"
        case 14...29:
            return "You're crushing it! Halfway to your goal! 🚀"
        case 30...:
            return "30-day champion! You've mastered your mornings! 🏆"
        default:
            return "Every day is a new opportunity!"
        }
    }
    
    private var messageColor: Color {
        switch currentStreak {
        case 0:
            return .secondary
        case 1...6:
            return .blue
        case 7...13:
            return .green
        case 14...29:
            return .orange
        case 30...:
            return .green
        default:
            return .secondary
        }
    }
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(messageColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(messageColor.opacity(0.1))
            )
    }
}

struct StreakDayRow: View {
    let day: StreakDay
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: day.date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: day.date)
    }
    
    private var timeDifference: String {
        // Calculate the difference in minutes between actual and target wake times
        let calendar = Calendar.current
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: day.wakeTime)
        let targetComponents = calendar.dateComponents([.hour, .minute], from: day.targetTime)
        
        let wakeMinutes = (wakeComponents.hour ?? 0) * 60 + (wakeComponents.minute ?? 0)
        let targetMinutes = (targetComponents.hour ?? 0) * 60 + (targetComponents.minute ?? 0)
        
        let differenceMinutes = wakeMinutes - targetMinutes
        
        if differenceMinutes <= 0 {
            return "On time"
        } else {
            return "+\(differenceMinutes)m"
        }
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
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(day.wakeTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(timeDifference)
                    .font(.caption)
                    .foregroundColor(day.isSuccessful ? .green : .red)
            }
            
            // Success indicator
            Image(systemName: day.isSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(day.isSuccessful ? .green : .red)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGroupedBackground))
        )
    }
}

#Preview {
    let sampleData = [
        SleepData(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            actualWakeTime: Date(),
            targetWakeTime: Date(),
            snoozeCount: 0,
            isSuccessful: true,
            alarmEnabled: true
        ),
        SleepData(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            actualWakeTime: Date(),
            targetWakeTime: Date(),
            snoozeCount: 1,
            isSuccessful: true,
            alarmEnabled: true
        )
    ]
    
    StreakTrackerView(sleepData: sampleData)
        .padding()
}

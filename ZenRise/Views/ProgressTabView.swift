//
//  ProgressTabView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject var sleepTracker: SleepBehaviorTracker
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var quizManager: SleepReadinessQuizManager
    @Binding var showQuizFromNotification: Bool
    @State private var selectedTab: ProgressTab = .overview
    @State private var showQuiz = false
    
    enum ProgressTab: String, CaseIterable {
        case overview = "Overview"
        case readiness = "Readiness"
        case sleep = "Sleep Graph"
        case snooze = "Snooze"
        case streak = "Streak"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .readiness: return "moon.zzz.fill"
            case .sleep: return "chart.line.uptrend.xyaxis"
            case .snooze: return "bell.fill"
            case .streak: return "flame.fill"
            }
        }
    }
    
    private var wakeUpSchedule: WakeUpSchedule {
        WakeUpSchedule(
            currentWakeUpTime: settingsManager.settings.currentWakeUpTime,
            targetWakeUpTime: settingsManager.settings.targetWakeUpTime
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector with improved styling
                VStack(spacing: 0) {
                    HStack {
                        Text("Progress")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Tab buttons in a contained, rounded container
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ProgressTab.allCases, id: \.self) { tab in
                                ProgressTabButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTab = tab
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                        ProgressOverviewView(
                            sleepTracker: sleepTracker,
                            wakeUpSchedule: wakeUpSchedule
                        )
                        .environmentObject(quizManager)
                        case .readiness:
                            SleepReadinessTrackerView(quizManager: quizManager, showQuiz: $showQuiz)
                        case .sleep:
                            SleepGraphView(sleepData: sleepTracker.sleepData)
                        case .snooze:
                            SnoozeTrackerView()
                        case .streak:
                            StreakTrackerView(sleepData: sleepTracker.sleepData)
                                .environmentObject(settingsManager)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(.systemGroupedBackground),
                            Color(.systemGroupedBackground).opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showQuiz) {
            SleepReadinessQuizView(quizManager: quizManager)
        }
        .onChange(of: showQuizFromNotification) { _, shouldShow in
            if shouldShow {
                selectedTab = .readiness
                showQuiz = true
                showQuizFromNotification = false
            }
        }
    }
}

struct ProgressTabButton: View {
    let tab: ProgressTabView.ProgressTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? 
                          LinearGradient(colors: [Color.green, Color.mint], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: isSelected ? .green.opacity(0.3) : Color.primary.opacity(0.1), radius: isSelected ? 4 : 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ProgressOverviewView: View {
    @ObservedObject var sleepTracker: SleepBehaviorTracker
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var quizManager: SleepReadinessQuizManager
    let wakeUpSchedule: WakeUpSchedule
    
    private var currentStreak: Int {
        sleepTracker.calculateCurrentStreak()
    }
    
    private var totalSnoozes: Int {
        sleepTracker.sleepData.reduce(0) { $0 + $1.snoozeCount }
    }
    
    private var successRate: Double {
        let totalDays = sleepTracker.sleepData.count
        guard totalDays > 0 else { return 0 }
        let successfulDays = sleepTracker.sleepData.filter { $0.isSuccessful }.count
        return Double(successfulDays) / Double(totalDays)
    }
    
    private var sleepReadinessAverage: Double {
        quizManager.getAverageScore()
    }
    
    private var sleepReadinessCategory: SleepReadinessScore.ScoreCategory {
        switch sleepReadinessAverage {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        case 0.2..<0.4: return .poor
        default: return .veryPoor
        }
    }
    
    private var sleepReadinessColor: Color {
        switch sleepReadinessCategory.color {
        case "green": return .green
        case "mint": return .mint
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Quick stats grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                OverviewStatCard(
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange,
                    isHighlighted: currentStreak > 0
                )
                
                OverviewStatCard(
                    title: "Success Rate",
                    value: "\(Int(successRate * 100))%",
                    subtitle: "on time",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    isHighlighted: successRate >= 0.8
                )
                
                OverviewStatCard(
                    title: "Total Snoozes",
                    value: "\(totalSnoozes)",
                    subtitle: "this month",
                    icon: "bell.fill",
                    color: .blue,
                    isHighlighted: false
                )
                
                OverviewStatCard(
                    title: "Sleep Readiness",
                    value: "\(Int(sleepReadinessAverage * 100))",
                    subtitle: sleepReadinessCategory.rawValue,
                    icon: "moon.zzz.fill",
                    color: sleepReadinessColor,
                    isHighlighted: sleepReadinessAverage >= 0.6
                )
            }
            
            // Progress summary
            VStack(spacing: 16) {
                Text("Journey Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let startDate = settingsManager.settings.startDate {
                    ProgressSummaryCard(
                        wakeUpSchedule: wakeUpSchedule,
                        startDate: startDate,
                        sleepData: sleepTracker.sleepData
                    )
                } else {
                    Text("Start your alarm to begin tracking progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            
            // Recent activity
            if !sleepTracker.sleepData.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(sleepTracker.getLast7DaysData().prefix(5), id: \.date) { data in
                            RecentActivityRow(data: data)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 2)
                )
            }
        }
    }
}

struct OverviewStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted ? color.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isHighlighted ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct ProgressSummaryCard: View {
    let wakeUpSchedule: WakeUpSchedule
    let startDate: Date
    let sleepData: [SleepData]
    
    private var daysCompleted: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(days, wakeUpSchedule.timeUntilTarget.days)
    }
    
    private var progressPercentage: Double {
        guard wakeUpSchedule.timeUntilTarget.days > 0 else { return 0 }
        return Double(daysCompleted) / Double(wakeUpSchedule.timeUntilTarget.days)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Days to Target")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(daysCompleted)/\(wakeUpSchedule.timeUntilTarget.days)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercentage, height: 12)
                            .animation(.easeInOut(duration: 0.8), value: progressPercentage)
                    }
                }
                .frame(height: 12)
            }
            
            // Target info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(wakeUpSchedule.timeUntilTarget.nextWakeUp.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Final Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(wakeUpSchedule.targetWakeUpTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct RecentActivityRow: View {
    let data: SleepData
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: data.date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
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
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(data.actualWakeTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    if data.snoozeCount > 0 {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("\(data.snoozeCount)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Circle()
                        .fill(data.isSuccessful ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                }
            }
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
    ProgressTabView(showQuizFromNotification: .constant(false))
        .environmentObject(UserSettingsManager())
        .environmentObject(SleepBehaviorTracker())
        .environmentObject(SleepReadinessQuizManager())
}

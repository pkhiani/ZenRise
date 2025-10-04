//
//  OnboardingSetupView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct OnboardingSetupView: View {
    @Binding var currentStep: OnboardingStep
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var currentSetupStep: SetupStep = .currentTime
    @State private var currentWakeTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var targetWakeTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date()
    @State private var selectedSound = ClockThemeSettings.AlarmSound.gentle
    @State private var isLoading = false
    @State private var showCompletion = false
    
    private var wakeUpSchedule: WakeUpSchedule {
        WakeUpSchedule(currentWakeUpTime: currentWakeTime, targetWakeUpTime: targetWakeTime)
    }
    
    var body: some View {
        Group {
            if showCompletion {
                OnboardingCompletionView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                VStack(spacing: 0) {
                    // Progress Indicator
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach(SetupStep.allCases, id: \.self) { step in
                                Circle()
                                    .fill(currentSetupStep.rawValue >= step.rawValue ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Text("Setup Progress: \(currentSetupStep.rawValue + 1) of \(SetupStep.allCases.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Setup Content
                    Group {
                        switch currentSetupStep {
                        case .currentTime:
                            CurrentTimeSetupStep(
                                currentWakeTime: $currentWakeTime,
                                onNext: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentSetupStep = .targetTime
                                    }
                                }
                            )
                        case .targetTime:
                            TargetTimeSetupStep(
                                currentWakeTime: currentWakeTime,
                                targetWakeTime: $targetWakeTime,
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentSetupStep = .currentTime
                                    }
                                },
                                onNext: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentSetupStep = .sound
                                    }
                                }
                            )
                        case .sound:
                            SoundSetupStep(
                                selectedSound: $selectedSound,
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentSetupStep = .targetTime
                                    }
                                },
                                onNext: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentSetupStep = .confirmation
                                    }
                                }
                            )
                        case .confirmation:
                            ConfirmationSetupStep(
                                currentWakeTime: currentWakeTime,
                                targetWakeTime: targetWakeTime,
                                selectedSound: selectedSound,
                                wakeUpSchedule: wakeUpSchedule,
                                isLoading: $isLoading,
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentSetupStep = .sound
                                    }
                                },
                                onComplete: {
                                    await completeSetup()
                                }
                            )
                        }
                    }
                    
                    Spacer()
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemGroupedBackground).opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
    
    private func completeSetup() async {
        isLoading = true
        
        print("🔔 Starting alarm setup...")
        print("🔔 Current wake time: \(currentWakeTime)")
        print("🔔 Target wake time: \(targetWakeTime)")
        
        // Update user settings
        settingsManager.settings.currentWakeUpTime = currentWakeTime
        settingsManager.settings.targetWakeUpTime = targetWakeTime
        settingsManager.settings.themeSettings.selectedSound = selectedSound
        settingsManager.settings.startDate = Date()
        settingsManager.settings.isSubscribed = true // User completed subscription flow
        settingsManager.settings.isAlarmEnabled = true // Enable alarm after onboarding
        
        let nextWakeUp = wakeUpSchedule.timeUntilTarget.nextWakeUp
        print("🔔 Calculated next wake up time: \(nextWakeUp)")
        
        // Schedule the alarm
        print("🔔 Scheduling alarm for: \(nextWakeUp)")
        await notificationManager.scheduleAlarm(
            for: nextWakeUp,
            sound: selectedSound
        )
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            isLoading = false
            showCompletion = true
        }
    }
}

enum SetupStep: Int, CaseIterable {
    case currentTime = 0
    case targetTime = 1
    case sound = 2
    case confirmation = 3
}

struct CurrentTimeSetupStep: View {
    @Binding var currentWakeTime: Date
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What time do you currently wake up?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("This helps us create your personalized wake-up plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Time Picker
            DatePicker(
                "Wake Time",
                selection: $currentWakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .padding(.horizontal, 32)
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
        }
    }
}

struct TargetTimeSetupStep: View {
    let currentWakeTime: Date
    @Binding var targetWakeTime: Date
    let onBack: () -> Void
    let onNext: () -> Void
    
    private var timeDifference: String {
        let difference = targetWakeTime.timeIntervalSince(currentWakeTime)
        let hours = Int(difference / 3600)
        let minutes = Int((difference.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours == 0 {
            return "\(minutes) minutes earlier"
        } else if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") earlier"
        } else {
            return "\(hours)h \(minutes)m earlier"
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("What's your target wake time?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("We'll gradually shift your wake time by 15 minutes each day")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Time Picker
            DatePicker(
                "Target Wake Time",
                selection: $targetWakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .padding(.horizontal, 32)
            
            // Time Difference Info
            if targetWakeTime < currentWakeTime {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.green)
                    
                    Text("Goal: Wake up \(timeDifference)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(targetWakeTime >= currentWakeTime)
            }
            .padding(.horizontal, 32)
        }
    }
}

struct SoundSetupStep: View {
    @Binding var selectedSound: ClockThemeSettings.AlarmSound
    let onBack: () -> Void
    let onNext: () -> Void
    @StateObject private var soundManager = SoundManager()
    
    private let sounds: [(ClockThemeSettings.AlarmSound, String, String)] = [
        (.gentle, "Gentle Chime", "bell.fill"),
        (.nature, "Morning Birds", "bird.fill"),
        (.classic, "Classic Bell", "bell.circle.fill"),
        (.energetic, "Upbeat Alarm", "music.note")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Choose your wake-up sound")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Select a gentle sound to start your day peacefully")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Sound Options
            VStack(spacing: 12) {
                ForEach(sounds, id: \.0.rawValue) { sound in
                    OnboardingSoundOptionCard(
                        sound: sound,
                        isSelected: selectedSound == sound.0,
                        onTap: {
                            selectedSound = sound.0
                            soundManager.playSound(sound.0)
                        }
                    )
                }
            }
            .padding(.horizontal, 32)
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

struct OnboardingSoundOptionCard: View {
    let sound: (ClockThemeSettings.AlarmSound, String, String)
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Sound Icon
                Image(systemName: sound.2)
                    .font(.title2)
                    .foregroundColor(.green)
                    .frame(width: 32, height: 32)
                
                Text(sound.1)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConfirmationSetupStep: View {
    let currentWakeTime: Date
    let targetWakeTime: Date
    let selectedSound: ClockThemeSettings.AlarmSound
    let wakeUpSchedule: WakeUpSchedule
    @Binding var isLoading: Bool
    let onBack: () -> Void
    let onComplete: () async -> Void
    
    private var soundName: String {
        switch selectedSound {
        case .gentle: return "Gentle Chime"
        case .nature: return "Morning Birds"
        case .classic: return "Classic Bell"
        case .energetic: return "Upbeat Alarm"
        case .default: return "Default Alarm"
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Ready to start your journey?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Here's your personalized wake-up plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Setup Summary
            VStack(spacing: 16) {
                SetupSummaryRow(
                    icon: "clock",
                    title: "Current wake time",
                    value: currentWakeTime.formatted(date: .omitted, time: .shortened)
                )
                
                SetupSummaryRow(
                    icon: "target",
                    title: "Target wake time",
                    value: targetWakeTime.formatted(date: .omitted, time: .shortened)
                )
                
                SetupSummaryRow(
                    icon: "waveform",
                    title: "Wake-up sound",
                    value: soundName
                )
                
                SetupSummaryRow(
                    icon: "calendar",
                    title: "Journey duration",
                    value: "\(wakeUpSchedule.timeUntilTarget.days) days"
                )
            }
            .padding(.horizontal, 32)
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button(action: {
                    Task {
                        await onComplete()
                    }
                }) {
                    HStack {
                        if isLoading {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Start My Journey")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 32)
        }
    }
}

struct SetupSummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    OnboardingSetupView(
        currentStep: .constant(.setup),
        hasCompletedOnboarding: .constant(false)
    )
    .environmentObject(UserSettingsManager())
    .environmentObject(NotificationManager())
}

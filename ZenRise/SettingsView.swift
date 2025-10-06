import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var alarmManager: UnifiedAlarmManager
    @EnvironmentObject var sleepTracker: SleepBehaviorTracker
    @EnvironmentObject var quizManager: SleepReadinessQuizManager
    @StateObject private var soundManager = SoundManager()
    @State private var showingResetAlert = false
    @State private var selectedSound: ClockThemeSettings.AlarmSound = .default
    
    // Initialize selectedSound from settings
    private func updateSelectedSound() {
        selectedSound = settingsManager.settings.themeSettings.selectedSound
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 16) {
                    // App Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.8),
                                        Color.mint.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "gear")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.white)
                    }
                    
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Customize your wake-up experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Wake-up Times Section
                SettingsSectionCard(
                    title: "Wake-up Times",
                    icon: "clock.fill",
                    color: .blue
                ) {
                    VStack(spacing: 20) {
                        TimePickerCard(
                            title: "Current Wake-up Time",
                            time: $settingsManager.settings.currentWakeUpTime,
                            color: settingsManager.settings.themeSettings.currentHandColor
                        )
                        
                        TimePickerCard(
                            title: "Target Wake-up Time",
                            time: $settingsManager.settings.targetWakeUpTime,
                            color: settingsManager.settings.themeSettings.targetHandColor
                        )
                    }
                }
            
                
                // Alarm Settings Section
                SettingsSectionCard(
                    title: "Alarm Settings",
                    icon: "alarm.fill",
                    color: .green
                ) {
                    VStack(spacing: 20) {
                        // Enable Alarm Toggle
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "alarm.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Alarm")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Start your wake-up journey")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $settingsManager.settings.isAlarmEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                        }
                        
                        Divider()
                        
                        // Sound Selection (always visible)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Wake-up Sound")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 12) {
                                ForEach(ClockThemeSettings.AlarmSound.allCases, id: \.self) { sound in
                                        SoundOptionCard(
                                            sound: sound,
                                            isSelected: selectedSound == sound,
                                            onTap: {
                                                print("🔊 Tapping sound: \(sound.rawValue)")
                                                print("🔊 Current selected: \(selectedSound.rawValue)")
                                                
                                                // Update local state for immediate UI update
                                                selectedSound = sound
                                                print("🔊 Updated local state: \(selectedSound.rawValue)")
                                                
                                                // Update settings
                                                settingsManager.settings.themeSettings.selectedSound = sound
                                                print("🔊 Updated settings: \(settingsManager.settings.themeSettings.selectedSound.rawValue)")
                                                
                                                // Play sound
                                                print("🔊 Playing sound...")
                                                soundManager.playSound(sound)
                                            }
                                        )
                                }
                            }
                        }
                    }
                }
            
                
                // Clock Style Section
                SettingsSectionCard(
                    title: "Clock Style",
                    icon: "clock.arrow.circlepath",
                    color: .orange
                ) {
                    VStack(spacing: 20) {
                        // Clock Style Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Clock Style")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Picker("Style", selection: $settingsManager.settings.themeSettings.clockStyle) {
                                ForEach(ClockThemeSettings.ClockStyle.allCases, id: \.self) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        Divider()
                        
                        // Clock Size Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Clock Size")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Picker("Size", selection: $settingsManager.settings.themeSettings.clockSize) {
                                ForEach(ClockThemeSettings.ClockSize.allCases, id: \.self) { size in
                                    Text(size.rawValue).tag(size)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        Divider()
                        
                        // Show Arcs Toggle
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "arc")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Time Arcs")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Display progress arcs on clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $settingsManager.settings.themeSettings.showArcs)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                        }
                        
                        Divider()
                        
                        // Color Pickers
                        VStack(spacing: 16) {
                            ColorPickerCard(
                                title: "Current Time Color",
                                color: $settingsManager.settings.themeSettings.currentHandColor,
                                icon: "clock.fill"
                            )
                            
                            ColorPickerCard(
                                title: "Target Time Color",
                                color: $settingsManager.settings.themeSettings.targetHandColor,
                                icon: "target"
                            )
                        }
                    }
                }
                
                // Data Management Section
                SettingsSectionCard(
                    title: "Data Management",
                    icon: "trash.fill",
                    color: .red
                ) {
                    VStack(spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Sleep Data")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Clear all progress and start fresh")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Reset") {
                                showingResetAlert = true
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red)
                            )
                        }
                    }
                }
                
                // Test Alarm Section (Development Only)
                SettingsSectionCard(
                    title: "Test Alarm",
                    icon: "bell.badge.fill",
                    color: .orange
                ) {
                    VStack(spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Test Alarm")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Schedule countdown alarm for 10 seconds from now")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Test") {
                                Task {
                                    await alarmManager.scheduleImmediateTestAlarm()
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange)
                            )
                        }
                    }
                }
                
                // Test Quiz Notification Section (Development Only)
                SettingsSectionCard(
                    title: "Test Quiz Notification",
                    icon: "moon.zzz.fill",
                    color: .green
                ) {
                    VStack(spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Test Quiz Notification")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Send sleep readiness quiz notification now")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Test") {
                                Task {
                                    await alarmManager.scheduleTestQuizNotification()
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green)
                            )
                        }
                    }
                }
                
                // About Section
                SettingsSectionCard(
                    title: "About",
                    icon: "info.circle.fill",
                    color: .mint
                ) {
                    VStack(spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.green.opacity(0.8),
                                                Color.mint.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ZenRise")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Version 1.0")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Transform your wake-up routine")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
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
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateSelectedSound()
        }
        .onDisappear {
            soundManager.stopSound()
        }
        .alert("Reset Sleep Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                sleepTracker.clearAllData()
                quizManager.clearAllData()
            }
        } message: {
            Text("This will permanently delete all your sleep progress data, including wake-up times, snooze patterns, streaks, and sleep readiness assessments. This action cannot be undone.")
        }
    }
}

// MARK: - Supporting Views

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }
}

struct TimePickerCard: View {
    let title: String
    @Binding var time: Date
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle())
                .frame(height: 44)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }
}

struct SoundOptionCard: View {
    let sound: ClockThemeSettings.AlarmSound
    let isSelected: Bool
    let onTap: () -> Void
    
    private var soundIcon: String {
        switch sound {
        case .gentle: return "bell.fill"
        case .nature: return "bird.fill"
        case .classic: return "bell.circle.fill"
        case .energetic: return "music.note"
        case .default: return "speaker.wave.2.fill"
        }
    }
    
    var body: some View {
        Button(action: {
            print("SoundOptionCard tapped: \(sound.rawValue), isSelected: \(isSelected)")
            onTap()
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green.opacity(0.15) : Color(.systemGray6))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: soundIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .green : .gray)
                }
                
                Text(sound.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                } else {
                    // Add invisible spacer to maintain consistent layout
                    Spacer()
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: isSelected ? 2 : 0)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ColorPickerCard: View {
    let title: String
    @Binding var color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            ColorPicker("", selection: $color)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGroupedBackground))
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(UserSettingsManager())
            .environmentObject(UnifiedAlarmManager())
            .environmentObject(SleepBehaviorTracker())
            .environmentObject(SleepReadinessQuizManager())
    }
} 
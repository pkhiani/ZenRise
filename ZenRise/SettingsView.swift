import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var soundManager = SoundManager()
    
    var body: some View {
        List {
            Section("Wake-up Times") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Wake-up Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("Current Wake-up Time",
                             selection: $settingsManager.settings.currentWakeUpTime,
                             displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Wake-up Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("Target Wake-up Time",
                             selection: $settingsManager.settings.targetWakeUpTime,
                             displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            
            Section("Alarm Settings") {
                Toggle("Enable Alarm", isOn: $settingsManager.settings.isAlarmEnabled)
                
                if settingsManager.settings.isAlarmEnabled {
                    Picker("Sound", selection: $settingsManager.settings.themeSettings.selectedSound) {
                        ForEach(ClockThemeSettings.AlarmSound.allCases, id: \.self) { sound in
                            HStack {
                                Text(sound.rawValue)
                                Spacer()
                                Button {
                                    soundManager.playSound(sound, volume: settingsManager.settings.themeSettings.volume)
                                } label: {
                                    Image(systemName: "play.circle")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .tag(sound)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "speaker.fill")
                            Slider(value: $settingsManager.settings.themeSettings.volume, in: 0...1)
                            Image(systemName: "speaker.wave.3.fill")
                        }
                        Text("Volume")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section("Clock Style") {
                Picker("Style", selection: $settingsManager.settings.themeSettings.clockStyle) {
                    ForEach(ClockThemeSettings.ClockStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                
                Picker("Size", selection: $settingsManager.settings.themeSettings.clockSize) {
                    ForEach(ClockThemeSettings.ClockSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                
                Toggle("Show Time Arcs", isOn: $settingsManager.settings.themeSettings.showArcs)
                
                ColorPicker("Current Time Color", selection: $settingsManager.settings.themeSettings.currentHandColor)
                ColorPicker("Target Time Color", selection: $settingsManager.settings.themeSettings.targetHandColor)
            }
            
            Section("About") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ZenRise")
                        .font(.headline)
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .onChange(of: settingsManager.settings.themeSettings.selectedSound) { _ in
            soundManager.stopSound()
        }
        .onDisappear {
            soundManager.stopSound()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(UserSettingsManager())
            .environmentObject(NotificationManager())
    }
} 
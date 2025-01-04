import SwiftUI

struct SettingsView: View {
    @Binding var currentWakeUpTime: Date
    @Binding var targetWakeUpTime: Date
    @Binding var isAlarmEnabled: Bool
    @ObservedObject var themeSettings: ClockThemeSettings
    @StateObject private var soundManager = SoundManager()
    
    var body: some View {
        List {
            Section("Wake-up Times") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Wake-up Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("Current Wake-up Time",
                             selection: $currentWakeUpTime,
                             displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Wake-up Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("Target Wake-up Time",
                             selection: $targetWakeUpTime,
                             displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            
            Section("Alarm Settings") {
                Toggle("Enable Alarm", isOn: $isAlarmEnabled)
                
                if isAlarmEnabled {
                    Picker("Sound", selection: $themeSettings.selectedSound) {
                        ForEach(ClockThemeSettings.AlarmSound.allCases, id: \.self) { sound in
                            HStack {
                                Text(sound.rawValue)
                                Spacer()
                                Button {
                                    soundManager.playSound(sound, volume: themeSettings.volume)
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
                            Slider(value: $themeSettings.volume, in: 0...1)
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
                Picker("Style", selection: $themeSettings.clockStyle) {
                    ForEach(ClockThemeSettings.ClockStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                
                Picker("Size", selection: $themeSettings.clockSize) {
                    ForEach(ClockThemeSettings.ClockSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                
                Toggle("Show Time Arcs", isOn: $themeSettings.showArcs)
                
                ColorPicker("Current Time Color", selection: $themeSettings.currentHandColor)
                ColorPicker("Target Time Color", selection: $themeSettings.targetHandColor)
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
        .onChange(of: themeSettings.selectedSound) { _ in
            soundManager.stopSound()
        }
        .onDisappear {
            soundManager.stopSound()
        }
    }
} 
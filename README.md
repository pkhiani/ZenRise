# ZenRise - Sleep Schedule Adjustment App

A SwiftUI-based iOS app designed to help users gradually adjust their wake-up time by 15 minutes per day until they reach their desired wake-up time.

## Features

### Core Functionality
- **Progressive Wake-up Adjustment**: Automatically calculates a 15-minute daily adjustment schedule
- **Visual Clock Interface**: Beautiful, customizable clock dial showing current and target wake-up times
- **Alarm Management**: Customizable alarm sounds with volume control
- **Progress Tracking**: Visual progress tracking with daily schedule view
- **Data Persistence**: All settings and progress are automatically saved

### Customization Options
- **Clock Styles**: Modern, Classic, and Minimal designs
- **Clock Sizes**: Small, Medium, and Large options
- **Color Themes**: Customizable colors for current and target time hands
- **Alarm Sounds**: Multiple built-in alarm sounds with preview functionality
- **Visual Elements**: Toggle for time arcs display

## Architecture

### Project Structure
```
ZenRise/
├── Models/
│   ├── UserSettings.swift          # User preferences and data model
│   └── WakeUpSchedule.swift        # Wake-up schedule calculations
├── Managers/
│   └── NotificationManager.swift   # Notification and alarm management
├── Config/
│   └── AppConfig.swift            # App constants and configuration
├── Views/
│   ├── ContentView.swift          # Main tab view
│   ├── HomeView.swift             # Home screen with clock
│   ├── SettingsView.swift         # Settings and customization
│   ├── ProgressView.swift         # Progress tracking
│   ├── ClockDialView.swift        # Custom clock component
│   └── AlarmSoundPreview.swift    # Sound preview component
└── ZenRiseApp.swift               # App entry point
```

### Key Design Patterns
- **MVVM Architecture**: Clean separation of concerns
- **Environment Objects**: Shared state management across views
- **ObservableObject**: Reactive UI updates
- **Async/Await**: Modern concurrency for notifications
- **Codable**: Automatic data persistence

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Installation
1. Clone the repository
2. Open `ZenRise.xcodeproj` in Xcode
3. Select your development team in project settings
4. Build and run the project

### Required Capabilities
- **Push Notifications**: For alarm functionality
- **Background Modes**: For reliable alarm delivery

### Sound Files
Add the following MP3 files to your project's "Sounds" folder:
- `default_alarm.mp3`
- `gentle_chime.mp3`
- `morning_birds.mp3`
- `upbeat_alarm.mp3`
- `classic_bell.mp3`

## Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions focused and single-purpose

### Error Handling
- Use proper error handling with `do-catch` blocks
- Log errors using `os.log` framework
- Provide user-friendly error messages
- Handle edge cases gracefully

### Testing
- Write unit tests for business logic
- Test notification functionality
- Verify data persistence
- Test UI interactions

### Performance
- Use lazy loading for large lists
- Optimize image and sound file sizes
- Minimize memory usage
- Profile app performance regularly

## Production Checklist

### Before Release
- [ ] Test on multiple iOS devices and versions
- [ ] Verify notification permissions work correctly
- [ ] Test alarm functionality thoroughly
- [ ] Check data persistence across app launches
- [ ] Review app store guidelines compliance
- [ ] Test accessibility features
- [ ] Verify localization if applicable
- [ ] Check memory usage and performance
- [ ] Test background/foreground transitions

### App Store Preparation
- [ ] Create app store screenshots
- [ ] Write compelling app description
- [ ] Prepare privacy policy
- [ ] Set up app store connect
- [ ] Configure app signing and provisioning
- [ ] Test TestFlight distribution

## Future Enhancements

### Planned Features
- **Widgets**: Home screen widgets for quick access
- **Health Integration**: Apple HealthKit integration
- **Analytics**: Sleep pattern analysis
- **Social Features**: Share progress with friends
- **Custom Sounds**: User-uploaded alarm sounds
- **Dark Mode**: Enhanced dark mode support

### Technical Improvements
- **Core Data**: More robust data persistence
- **Cloud Sync**: iCloud synchronization
- **Push Notifications**: Remote alarm management
- **Accessibility**: Enhanced VoiceOver support
- **Localization**: Multi-language support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@zenrise.app or create an issue in the repository.

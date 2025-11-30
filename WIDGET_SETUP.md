# ZenRise Widget Setup Guide

This guide will walk you through setting up the lockscreen widget for ZenRise in Xcode.

## Prerequisites

All widget code files have been created in the `ZenRiseWidget` folder. You now need to configure Xcode to recognize and build the widget extension.

## Step 1: Create Widget Extension Target

1. **Open Xcode** and open the `ZenRise.xcodeproj` file
2. **Add Widget Extension Target**:
   - Click on the project in the navigator (top-level "ZenRise")
   - At the bottom of the targets list, click the **"+"** button
   - Search for **"Widget Extension"**
   - Click **"Next"**
   
3. **Configure the Widget Extension**:
   - **Product Name**: `ZenRiseWidget`
   - **Include Configuration Intent**: ❌ **Uncheck this** (we don't need configuration)
   - Click **"Finish"**
   - When asked "Activate 'ZenRiseWidget' scheme?", click **"Activate"**

4. **Delete Auto-Generated Files**:
   - Xcode will create some default files in a new `ZenRiseWidget` folder
   - Delete the auto-generated Swift file (usually named `ZenRiseWidget.swift` or similar)
   - Keep the `Assets.xcassets` and `Info.plist` that Xcode created

5. **Add Our Widget Files to Target**:
   - In the Project Navigator, locate the `ZenRiseWidget` folder
   - Select all the Swift files we created:
     - `ZenRiseWidget.swift`
     - `WidgetProvider.swift`
     - `WidgetViews.swift`
     - `WidgetData.swift`
   - In the File Inspector (right panel), under **"Target Membership"**, check ✅ **ZenRiseWidget**

## Step 2: Add Shared Files to Both Targets

The `WidgetData.swift` file in the main app's `Models` folder needs to be accessible to both the app and the widget:

1. **Select** `ZenRise/Models/WidgetData.swift` in the Project Navigator
2. **In the File Inspector** (right panel), under **"Target Membership"**:
   - Check ✅ **ZenRise** (main app)
   - Check ✅ **ZenRiseWidget** (widget extension)

## Step 3: Enable App Groups

App Groups allow the main app and widget to share data through UserDefaults.

### For Main App Target:

1. **Select the ZenRise project** in the navigator
2. **Select the "ZenRise" target** (main app)
3. **Go to "Signing & Capabilities" tab**
4. **Click "+ Capability"** button
5. **Search for and add "App Groups"**
6. **Click the "+" button** under App Groups
7. **Enter**: `group.com.zenrise.shared` (or use your own identifier if you prefer)
8. **Click "OK"**

### For Widget Extension Target:

1. **Select the "ZenRiseWidget" target** (widget extension)
2. **Go to "Signing & Capabilities" tab**
3. **Click "+ Capability"** button
4. **Search for and add "App Groups"**
5. **Click the "+" button** under App Groups
6. **Enter the SAME identifier**: `group.com.zenrise.shared`
7. **Click "OK"**

> [!IMPORTANT]
> Both targets MUST use the exact same App Group identifier for data sharing to work!

## Step 4: Update App Group Identifier (If Needed)

If you used a different App Group identifier than `group.com.zenrise.shared`, you need to update it in the code:

1. **Open** `ZenRise/Models/WidgetData.swift`
2. **Find** the line: `static let appGroupIdentifier = "group.com.zenrise.shared"`
3. **Replace** with your identifier

4. **Open** `ZenRise/Models/UserSettings.swift`
5. **Find** the line: `private let appGroupIdentifier = "group.com.zenrise.shared"`
6. **Replace** with your identifier

## Step 5: Build and Run

1. **Select the "ZenRise" scheme** (not ZenRiseWidget) from the scheme selector
2. **Build and run** the app on a device or simulator (⌘R)
3. **Enable the alarm** in the app's Settings tab
4. **The widget data should now be saved** to the shared App Group

## Step 6: Add Widget to Lock Screen

### On iPhone (iOS 16+):

1. **Lock your iPhone**
2. **Long press on the lock screen**
3. **Tap "Customize"**
4. **Tap on the lock screen** you want to edit
5. **Tap on the widget area** (below the time)
6. **Search for "ZenRise"**
7. **Choose a widget style**:
   - **Circular**: Shows days remaining in a circular progress ring
   - **Inline**: Shows "X days left" text
8. **Tap "Done"**

### On Home Screen:

1. **Long press on the home screen**
2. **Tap the "+" button** in the top-left corner
3. **Search for "ZenRise"**
4. **Select the Small widget**
5. **Tap "Add Widget"**

## Troubleshooting

### Widget Shows No Data

- **Check App Groups**: Ensure both targets have the same App Group identifier enabled
- **Check Target Membership**: Ensure `WidgetData.swift` is added to both targets
- **Rebuild**: Clean build folder (⇧⌘K) and rebuild

### Widget Not Appearing

- **Check Scheme**: Make sure you're running the main "ZenRise" scheme, not "ZenRiseWidget"
- **Restart Device**: Sometimes iOS needs a restart to recognize new widgets
- **Check iOS Version**: Lockscreen widgets require iOS 16+

### Build Errors

- **Missing Imports**: Ensure all widget files are added to the ZenRiseWidget target
- **Duplicate Symbols**: Make sure you deleted the auto-generated widget files from Step 1

## Widget Features

### Circular Lockscreen Widget
- Shows days remaining as a number
- Progress ring fills as you get closer to target
- Green gradient theme matching the app

### Inline Lockscreen Widget
- Shows "X days left" with sun icon
- Compact text format for lock screen

### Small Home Screen Widget
- Shows days remaining prominently
- Displays current and target wake-up times
- Shows "Enable alarm to start" when alarm is off

## Next Steps

Once the widget is working:
- The widget will automatically update when you change wake-up times in the app
- The widget will update when you enable/disable the alarm
- The widget refreshes every hour to stay current

Enjoy your ZenRise widget! 🌅

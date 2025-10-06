# RevenueCat Integration Setup Guide

This guide will help you set up RevenueCat for weekly subscription management in ZenRise.

## Prerequisites

1. **RevenueCat Account**: Sign up at [revenuecat.com](https://revenuecat.com)
2. **Apple Developer Account**: For App Store Connect configuration
3. **Xcode Project**: Your ZenRise project

## Step 1: RevenueCat Dashboard Setup

### 1.1 Create a New Project
1. Log into your RevenueCat dashboard
2. Create a new project for ZenRise
3. Note down your **Public API Key**

### 1.2 Configure Products
1. Go to **Products** section
2. Add a new product with ID: `com.zenrise.weekly`
3. Set the product type to **Subscription**
4. Configure the subscription details:
   - Duration: 1 week
   - Price: $1.99 (or your preferred price)
   - Trial period: 2 days (optional)

### 1.3 Create Entitlements
1. Go to **Entitlements** section
2. Create a new entitlement called `premium`
3. Associate the weekly product with this entitlement

## Step 2: App Store Connect Setup

### 2.1 Create Subscription Group
1. Log into App Store Connect
2. Go to **My Apps** → **Your App** → **Features** → **In-App Purchases**
3. Create a new **Auto-Renewable Subscription** group
4. Add the weekly subscription product:
   - Product ID: `com.zenrise.weekly`
   - Duration: 1 Week
   - Price: $1.99

### 2.2 Configure Subscription Details
- Reference Name: "ZenRise Weekly"
- Product ID: `com.zenrise.weekly`
- Subscription Duration: 1 Week
- Price: $1.99
- Free Trial: 2 days (optional)

## Step 3: Xcode Project Configuration

### 3.1 Add RevenueCat SDK
1. Open your Xcode project
2. Go to **File** → **Add Package Dependencies**
3. Add the RevenueCat SDK:
   ```
   https://github.com/RevenueCat/purchases-ios
   ```
4. Select **Up to Next Major Version** and choose the latest version

### 3.2 Update Configuration
1. Open `ZenRise/Config/AppConfig.swift`
2. Replace the placeholder values:
   ```swift
   struct RevenueCat {
       static let apiKey = "YOUR_ACTUAL_REVENUECAT_API_KEY"
       static let premiumEntitlement = "premium"
       static let weeklyProductId = "com.zenrise.weekly"
   }
   ```

### 3.3 Update Info.plist
Add the following to your `Info.plist`:
```xml
<key>NSUserActivityTypes</key>
<array>
    <string>com.zenrise.weekly</string>
</array>
```

## Step 4: Testing

### 4.1 Sandbox Testing
1. Create a sandbox user in App Store Connect
2. Sign out of your Apple ID on the device
3. Sign in with the sandbox user
4. Test the subscription flow

### 4.2 Test Scenarios
- [ ] Purchase weekly subscription
- [ ] Restore purchases
- [ ] Cancel subscription
- [ ] Subscription expiration handling

## Step 5: Production Deployment

### 5.1 Final Configuration
1. Ensure all product IDs match between RevenueCat and App Store Connect
2. Test thoroughly in sandbox environment
3. Update API key to production key if different

### 5.2 App Store Review
1. Submit your app for review
2. Include subscription details in app description
3. Ensure subscription terms are clearly displayed

## Troubleshooting

### Common Issues

1. **"Product not available" error**
   - Check product ID matches exactly
   - Ensure product is approved in App Store Connect
   - Verify sandbox user is set up correctly

2. **RevenueCat not receiving events**
   - Check API key is correct
   - Verify webhook configuration
   - Check network connectivity

3. **Subscription not activating**
   - Check entitlement configuration
   - Verify customer info is being updated
   - Check for typos in entitlement name

### Debug Tips

1. Enable debug logging in RevenueCat:
   ```swift
   Purchases.logLevel = .debug
   ```

2. Check RevenueCat dashboard for customer events

3. Use Xcode console to monitor subscription status

## Support

- RevenueCat Documentation: [docs.revenuecat.com](https://docs.revenuecat.com)
- RevenueCat Support: [support.revenuecat.com](https://support.revenuecat.com)
- Apple In-App Purchase Documentation: [developer.apple.com](https://developer.apple.com/in-app-purchase/)

## Files Modified

The following files have been created/modified for RevenueCat integration:

- `ZenRise/Managers/RevenueCatManager.swift` - Main RevenueCat integration
- `ZenRise/Views/SubscriptionManagementView.swift` - Subscription management UI
- `ZenRise/Onboarding/OnboardingSubscriptionView.swift` - Updated subscription flow
- `ZenRise/SettingsView.swift` - Added subscription management
- `ZenRise/Config/AppConfig.swift` - Added RevenueCat configuration
- `ZenRise/ZenRiseApp.swift` - Added RevenueCat manager to environment

## Next Steps

1. Replace placeholder API key with your actual RevenueCat API key
2. Update product IDs to match your App Store Connect configuration
3. Test the integration thoroughly in sandbox environment
4. Deploy to production when ready

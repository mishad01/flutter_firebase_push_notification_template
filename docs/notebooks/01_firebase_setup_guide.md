# 🚀 Firebase Setup with Flutter

> **Journey Step 1:** Setting up Firebase Cloud Messaging (FCM) in your Flutter application

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Firebase Console Setup](#firebase-console-setup)
3. [Flutter Project Configuration](#flutter-project-configuration)
4. [Platform-Specific Setup](#platform-specific-setup)
5. [Verification](#verification)

---

## Prerequisites

Before starting, ensure you have:

- ✅ Flutter SDK installed (2.8.0 or higher)
- ✅ Active Firebase account
- ✅ Xcode (for iOS development)
- ✅ Android Studio (for Android development)
- ✅ CocoaPods installed (for iOS)

---

## 🔥 Firebase Console Setup

### Step 1: Create Firebase Project

1. Navigate to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter your project name
4. Enable/disable Google Analytics (optional but recommended)
5. Click **"Create project"**

### Step 2: Add Apps to Firebase

#### For Android:

1. Click the **Android icon** in Firebase Console
2. Enter your package name:
   ```
   Find it in: android/app/build.gradle
   applicationId "com.example.yourapp"
   ```
3. Enter app nickname (optional)
4. Enter SHA-1 certificate (optional for FCM, required for other features):
   ```bash
   # Debug certificate
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release certificate
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your_alias
   ```
5. Download `google-services.json`
6. Click **"Next"** through the remaining steps

#### For iOS:

1. Click the **iOS icon** in Firebase Console
2. Enter your bundle ID:
   ```
   Find it in: ios/Runner.xcodeproj/project.pbxproj
   PRODUCT_BUNDLE_IDENTIFIER
   ```
3. Enter app nickname (optional)
4. Download `GoogleService-Info.plist`
5. Click **"Next"** through the remaining steps

---

## 🎯 Flutter Project Configuration

### Step 1: Install FlutterFire CLI

```bash
# Activate FlutterFire CLI
dart pub global activate flutterfire_cli

# Verify installation
flutterfire --version
```

### Step 2: Configure Firebase

```bash
# Run from your Flutter project root
flutterfire configure

# This will:
# ✅ Select your Firebase project
# ✅ Choose platforms (iOS, Android, Web, macOS)
# ✅ Auto-generate firebase_options.dart
```

**Output:** Creates `lib/firebase_options.dart` with platform-specific configuration

### Step 3: Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  
dev_dependencies:
  flutter_lints: ^3.0.0
```

Then run:

```bash
flutter pub get
```

---

## 📱 Platform-Specific Setup

### Android Setup

#### 1. Place google-services.json

```
android/
  app/
    google-services.json  ← Place here
```

#### 2. Update android/build.gradle

```gradle
buildscript {
  dependencies {
    // Add this line
    classpath 'com.google.gms:google-services:4.4.0'
  }
}
```

#### 3. Update android/app/build.gradle

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// Add at the bottom
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Minimum for FCM
        targetSdkVersion 34
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

#### 4. Update AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- ... existing code ... -->
        
        <!-- Default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
            
        <!-- Default notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
            
        <!-- Default notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

---

### iOS Setup

#### 1. Place GoogleService-Info.plist

Using Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on `Runner` folder
3. Select **"Add Files to Runner"**
4. Select `GoogleService-Info.plist`
5. ✅ Check **"Copy items if needed"**
6. ✅ Check **"Runner" target**
7. Click **"Add"**

#### 2. Enable Push Notifications Capability

In Xcode:
1. Select `Runner` project
2. Select `Runner` target
3. Go to **"Signing & Capabilities"**
4. Click **"+ Capability"**
5. Add **"Push Notifications"**
6. Add **"Background Modes"**
   - ✅ Check "Remote notifications"
   - ✅ Check "Background fetch" (optional)

#### 3. Upload APNs Key to Firebase

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click **"+"** to create a new key
3. Name it (e.g., "FCM Push Key")
4. Check **"Apple Push Notifications service (APNs)"**
5. Click **"Continue"** → **"Register"**
6. Download the `.p8` file (⚠️ can only download once!)
7. Note the **Key ID**

Upload to Firebase:
1. Firebase Console → Project Settings
2. Go to **"Cloud Messaging"** tab
3. Under **"Apple app configuration"**
4. Upload APNs Authentication Key
5. Enter Key ID and Team ID

#### 4. Update Info.plist (Optional)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <!-- ... existing keys ... -->
    
    <!-- Notification permission description (optional) -->
    <key>NSUserNotificationUsageDescription</key>
    <string>This app needs notifications to keep you updated</string>
</dict>
</plist>
```

---

## ✅ Verification

### Step 1: Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

### Step 2: Test Firebase Connection

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> testFirebaseSetup() async {
  try {
    // Request permission
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    print('Permission status: ${settings.authorizationStatus}');
    
    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    
    if (token != null) {
      print('✅ Firebase setup successful!');
    } else {
      print('❌ Failed to get FCM token');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### Step 3: Send Test Notification

1. Go to Firebase Console → Cloud Messaging
2. Click **"Send your first message"**
3. Enter notification title and text
4. Click **"Send test message"**
5. Paste your FCM token
6. Click **"Test"**

---

## 🐛 Common Issues & Solutions

### Issue 1: "FirebaseApp not initialized"

**Solution:**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Issue 2: Android - google-services.json not found

**Check:**
- File is in `android/app/` (not `android/`)
- Gradle sync completed: `flutter clean && flutter pub get`

### Issue 3: iOS - No APNs token

**Solutions:**
- Test on real device (simulator doesn't support push)
- Verify APNs certificate uploaded to Firebase
- Check Bundle ID matches Firebase configuration

### Issue 4: Permission denied on Android 13+

**Solution:**
```xml
<!-- Add to AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Issue 5: FCM token is null

**Checklist:**
- ✅ Firebase initialized before getting token
- ✅ google-services.json / GoogleService-Info.plist in correct location
- ✅ Internet permission granted
- ✅ App has notification permission (iOS/Android 13+)

---

## 📚 Next Steps

- ✅ Firebase setup complete!
- 📍 Next: [Understanding Notification States](./02_notification_states_and_permissions.md)
- 📍 Then: [Implementation Guide](./03_implementation_guide.md)

---

## 🔗 Official Documentation

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Apple Developer - Push Notifications](https://developer.apple.com/notifications/)

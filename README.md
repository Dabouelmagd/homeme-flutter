# HomeMe Flutter App

تطبيق HomeMe للموبايل — WebView wrapper لـ homemeapp.net

## المتطلبات
- Flutter 3.10+
- Android Studio أو Xcode
- حساب Google Play Console (Android)
- حساب Apple Developer (iOS)

## تثبيت وتشغيل

```bash
# Install dependencies
flutter pub get

# Generate icons & splash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

# Run on device
flutter run

# Build Android APK (testing)
flutter build apk --release

# Build Android App Bundle (Google Play)
flutter build appbundle --release

# Build iOS (requires Mac + Xcode)
flutter build ios --release
```

## ملفات مهمة

| الملف | الوصف |
|-------|-------|
| `lib/main.dart` | الكود الرئيسي |
| `android/app/build.gradle` | إعدادات Android |
| `ios/Runner/Info.plist` | إعدادات iOS |
| `pubspec.yaml` | dependencies |

## App ID
- Android: `net.homemeapp.app`
- iOS: `net.homemeapp.app`

## الـ URL
- Production: `https://homemeapp.net`

## نشر على Google Play
1. `flutter build appbundle --release`
2. وقّع الـ AAB بـ keystore
3. ارفع على Google Play Console

## نشر على App Store
1. افتح Xcode → `ios/Runner.xcworkspace`
2. Archive → Distribute App
3. ارفع على App Store Connect

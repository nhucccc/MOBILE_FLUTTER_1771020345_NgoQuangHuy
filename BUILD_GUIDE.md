# Hướng dẫn Build APK

## Yêu cầu
- Flutter SDK 3.x
- Android SDK
- Java JDK 17+

## Các bước build APK

### 1. Chuẩn bị môi trường
```bash
# Kiểm tra Flutter
flutter doctor

# Cài đặt dependencies
cd pcm_flutter_345
flutter pub get
```

### 2. Build APK Debug (để test)
```bash
flutter build apk --debug
```

### 3. Build APK Release (để nộp bài)
```bash
flutter build apk --release
```

### 4. Vị trí file APK
```
pcm_flutter_345/build/app/outputs/flutter-apk/
├── app-debug.apk      # Debug version
└── app-release.apk    # Release version
```

## Cài đặt APK trên thiết bị

### Android Device
1. Enable "Unknown sources" trong Settings
2. Copy APK file vào thiết bị
3. Tap vào file APK để cài đặt

### Android Emulator
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Lưu ý quan trọng

### API Configuration
- **Emulator**: App sẽ tự động dùng `10.0.2.2:58377`
- **Real Device**: Cần thay đổi IP trong `lib/services/api_service.dart`

### Để test trên thiết bị thật
1. Tìm IP của máy tính (ipconfig/ifconfig)
2. Sửa API URL trong code:
```dart
// Thay localhost bằng IP máy tính
return 'http://192.168.1.100:58377/api';
```
3. Build lại APK

### Troubleshooting
- **Build failed**: Chạy `flutter clean` rồi build lại
- **APK không cài được**: Kiểm tra Android version compatibility
- **API không connect**: Kiểm tra firewall và IP address

## File APK đính kèm
Nếu build thành công, đính kèm file `app-release.apk` khi nộp bài.
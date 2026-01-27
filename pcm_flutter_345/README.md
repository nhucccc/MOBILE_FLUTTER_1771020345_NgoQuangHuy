# PCM Flutter App - Frontend

Ứng dụng Flutter cho hệ thống quản lý sân pickleball.

## Cài đặt và chạy

### 1. Cài đặt dependencies
```bash
flutter pub get
```

### 2. Chạy ứng dụng
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

### 3. Build APK
```bash
flutter build apk --release
```

## Cấu hình API
- Web: `http://localhost:58377/api`
- Android: `http://10.0.2.2:58377/api`
- iOS: `http://localhost:58377/api`

## Tài khoản test
- Admin: admin@pickleball345.com / Admin@123
- User: huy@example.com / Password123!

## Cấu trúc project
```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
├── providers/                # State management
├── screens/                  # UI screens
├── services/                 # API & external services
├── widgets/                  # Reusable widgets
└── theme/                    # App theme & styling
```
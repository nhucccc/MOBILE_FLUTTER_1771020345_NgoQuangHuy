# MOBILE_FLUTTER_1771020345_NgoQuangHuy

## Mô tả dự án
Ứng dụng quản lý sân pickleball với Flutter (Frontend) và ASP.NET Core Web API (Backend).

## Cấu trúc project
```
├── pcm_flutter_345/          # Flutter Mobile App
├── pickleball_api_345/       # ASP.NET Core Web API Backend
└── README.md                 # Hướng dẫn này
```

## Yêu cầu hệ thống
- **Backend**: .NET 8.0 SDK, SQL Server LocalDB
- **Frontend**: Flutter SDK 3.x, Dart 3.x
- **IDE**: Visual Studio Code, Android Studio (tùy chọn)

## Hướng dẫn chạy Backend (ASP.NET Core Web API)

### 1. Cài đặt dependencies
```bash
cd pickleball_api_345
dotnet restore
```

### 2. Tạo database và migration
```bash
# Tạo migration (nếu chưa có)
dotnet ef migrations add InitialCreate

# Cập nhật database
dotnet ef database update
```

### 3. Chạy API server
```bash
dotnet run
```

**API sẽ chạy tại:**
- HTTP: `http://localhost:58377`
- HTTPS: `https://localhost:58376`

### 4. Tạo dữ liệu mẫu (tùy chọn)
```bash
# Gọi API để tạo user và data mẫu
POST http://localhost:58377/api/test/seed-data
```

## Hướng dẫn chạy Frontend (Flutter)

### 1. Cài đặt dependencies
```bash
cd pcm_flutter_345
flutter pub get
```

### 2. Chạy ứng dụng

#### Trên Chrome (Web)
```bash
flutter run -d chrome
```

#### Trên Android Emulator
```bash
flutter run -d android
```

#### Trên iOS Simulator (macOS only)
```bash
flutter run -d ios
```

## Cấu hình API Base URL

### Web (Chrome)
- API URL: `http://localhost:58377/api`

### Android Emulator
- API URL: `http://10.0.2.2:58377/api`

### iOS Simulator
- API URL: `http://localhost:58377/api`

**Lưu ý**: API URL được tự động cấu hình trong `lib/services/api_service.dart`

## Tài khoản test

### Admin
- Email: `admin@pickleball345.com`
- Password: `Admin@123`

### User thường
- Email: `huy@example.com`
- Password: `Password123!`

## Chức năng chính

### User
- ✅ Đăng ký/Đăng nhập
- ✅ Xem và đặt sân
- ✅ Quản lý ví tiền (nạp tiền, xem lịch sử)
- ✅ Xem lịch sử đặt sân
- ✅ Quản lý thông tin cá nhân
- ✅ Đổi mật khẩu

### Admin
- ✅ Dashboard quản trị
- ✅ Duyệt yêu cầu nạp tiền
- ✅ Quản lý thành viên
- ✅ Quản lý sân
- ✅ Xem báo cáo

### Tính năng nâng cao
- ✅ Real-time notifications (SignalR)
- ✅ Biometric authentication
- ✅ Recurring booking (đặt sân định kỳ)
- ✅ Tournament management
- ✅ Tier system (Bronze/Silver/Gold/Diamond)

## Build APK cho Android

```bash
cd pcm_flutter_345
flutter build apk --release
```

APK file sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

### Backend không chạy được
1. Kiểm tra .NET SDK: `dotnet --version`
2. Kiểm tra SQL Server LocalDB
3. Chạy migration: `dotnet ef database update`

### Flutter không build được
1. Kiểm tra Flutter SDK: `flutter doctor`
2. Clean project: `flutter clean && flutter pub get`
3. Restart IDE/Editor

### API connection error
1. Đảm bảo backend đang chạy
2. Kiểm tra firewall/antivirus
3. Thử URL khác: `http://127.0.0.1:58377` thay vì `localhost`

## Liên hệ
- MSSV: 1771020345
- Tên: Ngọ Quang Huy
- Email: huy@example.com

---
**Lưu ý**: Đảm bảo chạy Backend trước khi chạy Frontend để tránh lỗi connection.

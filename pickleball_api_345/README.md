# Pickleball API - Backend

ASP.NET Core Web API cho hệ thống quản lý sân pickleball.

## Cài đặt và chạy

### 1. Cài đặt dependencies
```bash
dotnet restore
```

### 2. Tạo database
```bash
# Tạo migration
dotnet ef migrations add InitialCreate

# Cập nhật database
dotnet ef database update
```

### 3. Chạy API
```bash
dotnet run
```

API sẽ chạy tại:
- HTTP: http://localhost:58377
- HTTPS: https://localhost:58376

### 4. Tạo dữ liệu mẫu
```bash
POST http://localhost:58377/api/test/seed-data
```

## API Endpoints

### Authentication
- POST `/api/auth/login` - Đăng nhập
- POST `/api/auth/register` - Đăng ký

### Booking
- GET `/api/booking/courts` - Danh sách sân
- POST `/api/booking` - Đặt sân
- GET `/api/booking/my-bookings` - Lịch sử đặt sân

### Wallet
- GET `/api/wallet/balance` - Số dư ví
- POST `/api/wallet/deposit` - Nạp tiền

### Admin
- GET `/api/admin/dashboard-stats` - Thống kê
- GET `/api/admin/pending-deposits` - Duyệt nạp tiền

## Cấu trúc project
```
├── Controllers/              # API Controllers
├── Services/                 # Business logic
├── Models/                   # Entity models
├── DTOs/                     # Data transfer objects
├── Data/                     # Database context
└── Migrations/               # EF migrations
```

## Database
- SQL Server LocalDB
- Entity Framework Core
- Code-First approach
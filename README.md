# 🩺 Sổ Tay Y Tế (Personal Medical Record & Health Journal)

Ứng dụng di động quản lý sổ tay y tế, theo dõi lịch sử khám chữa bệnh, lưu trữ toa thuốc điện tử và cung cấp thẻ y tế cấp cứu khẩn cấp cho người dùng cá nhân và gia đình.

Dự án được xây dựng bằng **Flutter & Dart**, tuân thủ nghiêm ngặt theo mô hình **Clean Architecture** (Domain, Data, Presentation, Core), hỗ trợ lưu trữ dữ liệu ngoại tuyến (Offline-First) an toàn và sẵn sàng mở rộng đồng bộ hóa Cloud.

---

## 🌟 Tính Năng Nổi Bật

- ⏱ **Dòng thời gian y tế (Medical Timeline)**: Ghi lại toàn bộ lịch sử các đợt khám tổng quát, tiêm chủng, phẫu thuật, ghi nhận triệu chứng theo trình tự thời gian.
- 💊 **Quản lý đơn thuốc & liệu trình (Prescriptions & Medicines)**: Lưu chi tiết tên thuốc, liều lượng, tần suất uống, hướng dẫn sử dụng và ghi chú của bác sĩ.
- 🚨 **Thẻ y tế cấp cứu khẩn cấp (Emergency Medical Card)**: Hiển thị nhanh các thông tin sinh tồn thiết yếu như nhóm máu, dị ứng thuốc, bệnh nền mạn tính và số liên hệ khẩn cấp ngay trên màn hình khóa hoặc truy cập nhanh.
- 📄 **Xuất báo cáo y khoa (Export Health Report)**: Xuất toàn bộ hồ sơ hoặc chi tiết đợt khám ra định dạng tài liệu y khoa PDF chuẩn để chia sẻ với bác sĩ.
- ☁️ **Đồng bộ hóa đám mây & Bản Pro (Sync & Pro Features)**: Hỗ trợ người dùng ẩn danh (Anonymous) nâng cấp liên kết tài khoản chính thức, sao lưu dữ liệu lên đám mây bảo mật.
- 🔒 **Bảo mật & Hoạt động Offline (Offline-First & Security)**: Dữ liệu được mã hóa và lưu trữ an toàn trong SQLite nội bộ thiết bị mà không bắt buộc có kết nối Internet liên tục.

---

## 🏛 Kiến Trúc Dự Án (Clean Architecture)

Dự án được phân tách thành 4 tầng rõ ràng nhằm đảm bảo tính độc lập, dễ kiểm thử (Testability), dễ bảo trì và dễ mở rộng:

```text
lib/
│
├── core/                                 # Tiện ích, cấu hình và dịch vụ dùng chung
│   ├── constants/                        # Hằng số toàn ứng dụng, API endpoints, key lưu trữ
│   ├── database/                         # SQLite Helper, bảng dữ liệu, migration
│   ├── di/                               # Dependency Injection (get_it)
│   ├── errors/                           # Định nghĩa Failure, Exception
│   ├── network/                          # HTTP client (Dio), Network Info (kết nối mạng)
│   ├── security/                         # Mã hóa dữ liệu local, secure storage
│   ├── theme/                            # Bảng màu chuẩn y tế, Typography, Dark/Light Theme
│   └── utils/                            # DateFormatter (dd/MM/yyyy), InputValidators
│
├── data/                                 # DATA LAYER: Nguồn dữ liệu & triển khai Repository
│   ├── datasources/
│   │   ├── local/                        # Truy vấn dữ liệu SQLite, SharedPreferences
│   │   │   ├── medical_local_datasource.dart
│   │   │   └── app_preferences_datasource.dart
│   │   └── remote/                       # Giao tiếp API Cloud Sync, Auth, In-app purchase
│   │       ├── auth_remote_datasource.dart
│   │       ├── medical_sync_remote_datasource.dart
│   │       └── subscription_remote_datasource.dart
│   ├── models/                           # DTOs (Data Transfer Objects) có fromJson, toJson, toEntity
│   │   ├── medical_event_model.dart
│   │   ├── prescription_model.dart
│   │   └── user_model.dart
│   └── repositories/                     # Triển khai các Repository interface từ Domain
│       ├── auth_repository_impl.dart
│       ├── medical_record_repository_impl.dart
│       └── sync_repository_impl.dart
│
├── domain/                               # DOMAIN LAYER: Logic nghiệp vụ thuần Dart
│   ├── entities/                         # Các thực thể nghiệp vụ (Immutable)
│   │   ├── medical_event.dart
│   │   ├── prescription.dart
│   │   ├── medicine.dart
│   │   └── user_profile.dart
│   ├── repositories/                     # Contracts / Interfaces định nghĩa hành vi
│   │   ├── auth_repository.dart
│   │   ├── medical_record_repository.dart
│   │   └── sync_repository.dart
│   └── usecases/                         # Các ca sử dụng nghiệp vụ cụ thể
│       ├── medical/
│       │   ├── get_medical_timeline_usecase.dart
│       │   ├── save_medical_event_usecase.dart
│       │   └── export_health_pdf_usecase.dart
│       ├── auth/
│       │   ├── link_anonymous_account_usecase.dart
│       │   └── check_pro_status_usecase.dart
│       └── sync/
│           └── sync_local_to_cloud_usecase.dart
│
├── presentation/                         # PRESENTATION LAYER: Giao diện và Quản lý State
│   ├── common_widgets/                   # Widget tái sử dụng (CustomButton, CustomTextField, LoadingDialog)
│   ├── routes/                           # Cấu hình điều hướng màn hình tập trung
│   └── features/                         # Chia theo từng màn hình / tính năng
│       ├── timeline/                     # Màn hình dòng thời gian sổ y tế
│       │   ├── view/                     # UI Screen & Widgets con
│       │   └── viewmodel/                # Quản lý State & ViewModel
│       ├── add_record/                   # Màn hình thêm đợt khám & danh sách thuốc
│       ├── record_detail/                # Xem chi tiết đợt khám & xuất PDF
│       ├── emergency_card/               # Thẻ thông tin cấp cứu y tế
│       └── paywall/                      # Gói Pro & Đăng ký tài khoản
│
└── main.dart                             # Entry point: Khởi tạo DI, cấu hình Theme & Route
```

---

## 🛠 Công Nghệ & Thư Viện

- **Framework**: [Flutter](https://flutter.dev/) (SDK `>=3.13.4 <4.0.0`)
- **Ngôn ngữ**: [Dart](https://dart.dev/) 3.x
- **Kiến trúc**: Clean Architecture (Presentation - Domain - Data - Core)
- **Dependency Injection**: [`get_it`](https://pub.dev/packages/get_it)
- **Cơ sở dữ liệu Local**: [`sqflite`](https://pub.dev/packages/sqflite), [`path`](https://pub.dev/packages/path)
- **Lưu trữ cấu hình**: [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- **Xử lý ngày tháng & tiền tệ**: [`intl`](https://pub.dev/packages/intl)
- **Tạo định danh duy nhất**: [`uuid`](https://pub.dev/packages/uuid)
- **UI Design**: Material 3 Design với tông màu y tế chuẩn (Primary Teal `#007A78`).

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Yêu cầu môi trường
- Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản `>= 3.13.0`).
- Đã cấu hình máy ảo Android Emulator hoặc iOS Simulator / thiết bị thật.

### 2. Cài đặt các gói phụ thuộc (Dependencies)
```bash
git clone https://github.com/ThanhhDaoo/So_Tay_Y_Te.git
cd So_Tay_Y_Te
flutter pub get
```

### 3. Kiểm tra chất lượng mã nguồn & Kiểm thử
```bash
# Phân tích tĩnh mã nguồn (linter)
flutter analyze

# Chạy bộ kiểm thử tự động
flutter test
```

### 4. Khởi chạy ứng dụng
```bash
# Chạy trên thiết bị mặc định
flutter run

# Chạy trên Chrome hoặc macOS Desktop (nếu có cấu hình)
flutter run -d chrome
flutter run -d macos
```

---

## 📌 Lộ Trình Phát Triển (Roadmap)

- [x] Thiết lập cấu trúc thư mục chuẩn Clean Architecture.
- [x] Tạo toàn bộ các Model, Entity, UseCase, Repository contracts.
- [x] Xây dựng UI cơ bản: Dòng thời gian, Thêm đợt khám, Chi tiết đơn thuốc, Thẻ cấp cứu, Paywall.
- [x] Tích hợp SQLite Database với 4 bảng chính: `medical_events`, `prescriptions`, `medicines`, `user_profile`.
- [ ] Tích hợp tính năng nhắc nhở uống thuốc tự động qua Local Notification.
- [ ] Chụp ảnh toa thuốc và áp dụng OCR (nhận dạng ký tự quang học) để tự động điền danh sách thuốc.
- [ ] Kết nối API Cloud Sync và cơ chế giải quyết xung đột dữ liệu (Conflict Resolution).
- [ ] Tích hợp thanh toán In-App Purchase (IAP) hoặc RevenueCat cho gói Pro.

---

## 👨‍💻 Tác Giả & Bản Quyền

- Tác giả: **ThanhhDaoo**
- Repository: [https://github.com/ThanhhDaoo/So_Tay_Y_Te](https://github.com/ThanhhDaoo/So_Tay_Y_Te)
- Giấy phép: [MIT License](LICENSE) (hoặc theo quy định phát triển nội bộ).

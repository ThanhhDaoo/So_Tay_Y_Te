import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/view/security_settings_screen.dart';

void main() {
  testWidgets('SecuritySettingsScreen renders all security & biometric sections', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SecuritySettingsScreen(showBottomNav: false),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Master Shield Header Card
    expect(find.text('TRUNG TÂM AN TOÀN DỮ LIỆU'), findsOneWidget);
    expect(find.text('Bảo vệ Tối đa'), findsOneWidget);
    expect(find.text('ĐÃ XÁC THỰC'), findsOneWidget);
    expect(find.text('Khóa máy phần cứng (Enclave)'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    // Verify Category 1: App lock & Biometrics
    expect(find.text('Khóa Ứng Dụng & Sinh Trắc Học'), findsOneWidget);
    expect(find.text('Khóa bằng Face ID / Vân tay'), findsOneWidget);
    expect(find.text('Mã PIN bảo mật 6 chữ số'), findsOneWidget);
    expect(find.text('Tự động khóa ứng dụng'), findsOneWidget);
    expect(find.text('TỨC THÌ'), findsOneWidget);
    expect(find.text('SAU 1 PHÚT'), findsOneWidget);

    // Verify Category 2: Encryption & Privacy
    expect(find.text('Mã Hóa & Quyền Riêng Tư'), findsOneWidget);
    expect(find.text('Cơ sở dữ liệu trên thiết bị'), findsOneWidget);
    expect(find.text('SQLCipher 256-bit'), findsOneWidget);
    expect(find.text('Chế độ định danh vô danh (Guest UUID)'), findsOneWidget);
    expect(find.text('f81d4fae-7dec-11d0-a765'), findsOneWidget);
    expect(find.text('Ẩn xem trước trong Đa nhiệm'), findsOneWidget);

    // Verify Category 3: Backup & Restore
    expect(find.text('Sao Lưu & Khôi Phục Dữ Liệu'), findsOneWidget);
    expect(find.text('FREE & PRO'), findsOneWidget);
    expect(find.text('Tệp gói tin mã hóa độc lập'), findsOneWidget);
    expect(find.text('Xuất Tệp Dự Phòng (.sotayyte)'), findsOneWidget);
    expect(find.text('Khôi phục từ tệp có sẵn'), findsOneWidget);

    // Verify Danger Zone
    expect(find.text('Vùng Thao Tác Nguy Hiểm'), findsOneWidget);
    expect(find.text('Xóa Toàn Bộ Dữ Liệu Trên Thiết Bị'), findsOneWidget);

    // Test Interaction: Switch timeout option to 'SAU 1 PHÚT'
    final timeoutOption = find.text('SAU 1 PHÚT');
    await tester.ensureVisible(timeoutOption);
    await tester.pumpAndSettle();
    await tester.tap(timeoutOption);
    await tester.pumpAndSettle();

    // Test Interaction: Copy UUID
    final uuidFinder = find.text('f81d4fae-7dec-11d0-a765');
    await tester.ensureVisible(uuidFinder);
    await tester.pumpAndSettle();
    await tester.tap(uuidFinder);
    await tester.pumpAndSettle();

    // Test Interaction: Tap Export Backup
    final exportBtn = find.text('Xuất Tệp Dự Phòng (.sotayyte)');
    await tester.ensureVisible(exportBtn);
    await tester.pumpAndSettle();
    await tester.tap(exportBtn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify notification snackbar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('thành công'), findsOneWidget);
  });
}

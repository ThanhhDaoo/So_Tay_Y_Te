import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/presentation/features/vital_reports/view/vital_reports_screen.dart';

void main() {
  testWidgets('VitalReportsScreen renders all core clinical report sections', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: VitalReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('Báo Cáo Sinh Hiệu'), findsOneWidget);
    expect(find.text('Báo Cáo Sinh Hiệu Lâm Sàng'), findsOneWidget);
    expect(find.text('WHO Clinical Grade'), findsOneWidget);
    expect(find.text('Chuẩn A4'), findsOneWidget);

    // Verify Metric tabs
    expect(find.text('Huyết áp'), findsOneWidget);
    expect(find.text('Đường huyết'), findsOneWidget);
    expect(find.text('Nhịp tim'), findsOneWidget);
    expect(find.text('BMI & Cân'), findsOneWidget);

    // Verify Latest Measure
    expect(find.text('118/78'), findsAtLeastNWidgets(1));
    expect(find.text('Tối ưu (WHO)'), findsOneWidget);
    expect(find.text('96%'), findsOneWidget);

    // Verify A4 Preview Section
    expect(find.text('Xuất Bệnh Án A4 Chuẩn Y Tế'), findsOneWidget);
    expect(find.text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM'), findsOneWidget);
    expect(find.text('HỆ THỐNG MEDVAULT EHR'), findsOneWidget);
    expect(find.textContaining('PENICILLIN'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Xuất PDF Bệnh Án (A4 chuẩn y khoa)'), findsOneWidget);
    expect(find.text('In AirPrint'), findsOneWidget);
    expect(find.text('Gửi Bác Sĩ'), findsOneWidget);

    // Switch metric tab to 'Đường huyết'
    await tester.tap(find.text('Đường huyết'));
    await tester.pumpAndSettle();

    // Switch timeframe to 'Tháng'
    await tester.tap(find.text('Tháng'));
    await tester.pumpAndSettle();

    // Scroll to action button and tap export PDF
    final exportBtn = find.text('Xuất PDF Bệnh Án (A4 chuẩn y khoa)');
    await tester.ensureVisible(exportBtn);
    await tester.pumpAndSettle();
    await tester.tap(exportBtn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify notification snackbar
    expect(find.textContaining('thành công'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/presentation/features/record_detail/view/record_detail_screen.dart';

void main() {
  testWidgets('RecordDetailScreen renders hospital, diagnosis and clinical vitals', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: RecordDetailScreen(recordId: 'REC-2024-0418'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chi Tiết Bệnh Án'), findsOneWidget);
    expect(find.text('Bệnh viện Đa khoa Quốc tế Vinmec Central Park'), findsOneWidget);
    expect(find.text('BS. Trần Văn Hùng'), findsOneWidget);
    expect(find.text('Toa Thuốc Điều Trị Ngoại Trú (14 Ngày)'), findsOneWidget);
  });
}

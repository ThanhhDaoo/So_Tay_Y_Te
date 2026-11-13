import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/presentation/features/add_record/view/add_record_screen.dart';

void main() {
  testWidgets('AddRecordScreen renders form inputs and specialty chips', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AddRecordScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thêm Đợt Khám Mới'), findsOneWidget);
    expect(find.text('Thông Tin Cơ Sở Khám'), findsOneWidget);
    expect(find.text('Chuyên Khoa'), findsOneWidget);
    expect(find.text('Lưu Đợt Khám Vào Sổ Y Tế'), findsOneWidget);
  });
}

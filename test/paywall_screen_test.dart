import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/presentation/features/paywall/view/paywall_screen.dart';

void main() {
  testWidgets('PaywallScreen renders correctly without overflow on narrow width',
      (tester) async {
    // Test on a narrow iPhone SE screen (375 x 667)
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PaywallScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 TÍNH NĂNG MỞ KHÓA'), findsOneWidget);
    expect(find.text('Gói Vault Pro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}


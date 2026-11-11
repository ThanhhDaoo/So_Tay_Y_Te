import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SoTayYTeApp());
    expect(find.byType(SoTayYTeApp), findsOneWidget);
  });
}

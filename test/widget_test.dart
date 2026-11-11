import 'package:flutter_test/flutter_test.dart';
import 'package:dentel_connect/main.dart';

void main() {
  testWidgets('DentalConnect app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const DentalConnectApp());
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}

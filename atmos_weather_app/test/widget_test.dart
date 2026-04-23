import 'package:flutter_test/flutter_test.dart';

import 'package:atmos_weather_app/main.dart';

void main() {
  testWidgets('Atmos splash renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AtmosApp());

    expect(find.text('ATMOS'), findsOneWidget);

    // Let delayed navigation timer complete so the test ends cleanly.
    await tester.pump(const Duration(seconds: 3));
  });
}

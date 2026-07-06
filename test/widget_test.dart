import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_kebun_tomat/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // initialRoute '/landing' karena belum ada sesi
    await tester.pumpWidget(const MyApp(initialRoute: '/landing'));
  });
}

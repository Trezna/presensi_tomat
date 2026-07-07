import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:presensi_kebun_tomat/main.dart';

void main() {
  testWidgets('App smoke test — LandingScreen tampil saat start',
      (WidgetTester tester) async {
    // Build app dan trigger frame pertama.
    await tester.pumpWidget(const MyApp());

    // Tunggu semua async tasks (termasuk cek sesi di LandingScreen) selesai.
    await tester.pumpAndSettle();

    // Verifikasi elemen kunci di LandingScreen muncul.
    // Teks "Presensi" berasal dari teks "Presensi\nKebun Tomat".
    expect(find.textContaining('Presensi'), findsWidgets);
    expect(find.text('Masuk'), findsOneWidget);
  });
}

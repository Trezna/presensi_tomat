import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/admin_navigation_screen.dart';
import 'screens/presensi_screen.dart';
import 'screens/detail_presensi_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Tahan splash native sampai frame pertama selesai dirender.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Inisialisasi locale Indonesia untuk DateFormat dan TableCalendar
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
  // Lepas splash setelah frame pertama (LandingScreen) selesai dirender.
  // Cek sesi dan redirect dilakukan di dalam LandingScreen itu sendiri.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color accentTomato = Color(0xFFD32F2F);
    const Color surfaceColor = Color(0xFFF1F8E9);

    final ColorScheme customColorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: accentTomato,
      surface: surfaceColor,
      brightness: Brightness.light,
    );

    final TextTheme poppinsTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    );

    return MaterialApp(
      title: 'Presensi Kebun Tomat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: customColorScheme,
        useMaterial3: true,
        textTheme: poppinsTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: primaryGreen),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey,
        ),
      ),
      // LandingScreen sebagai titik masuk tunggal — dia sendiri yang
      // mengecek sesi dan meneruskan ke halaman yang tepat.
      home: const LandingScreen(),
      routes: {
        '/main': (context) => const MainNavigationScreen(),
        '/admin': (context) => const AdminNavigationScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/presensi': (context) => const PresensiScreen(),
        '/detail_presensi': (context) => const DetailPresensiScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/admin_navigation_screen.dart';
import 'screens/presensi_screen.dart';
import 'screens/detail_presensi_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi locale Indonesia untuk DateFormat dan TableCalendar
  await initializeDateFormatting('id_ID', null);

  final sesi = await AuthService().getSesi();
  String initialRoute;
  if (sesi == null) {
    initialRoute = '/landing';
  } else if (sesi.role == 'admin') {
    initialRoute = '/admin';
  } else {
    initialRoute = '/';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

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

    final TextTheme poppinsTextTheme =
        GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

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
          style: FilledButton.styleFrom(
            backgroundColor: primaryGreen,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey,
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/admin': (context) => const AdminNavigationScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/presensi': (context) => const PresensiScreen(),
        '/detail_presensi': (context) => const DetailPresensiScreen(),
      },
    );
  }
}

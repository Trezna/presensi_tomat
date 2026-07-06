import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), primaryGreen, Color(0xFF388E3C)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Icon / Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_florist,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // Nama App
                Text(
                  'Presensi\nKebun Tomat',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sistem Smart Farming Monitoring',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withAlpha(200),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(flex: 3),
                // Tombol Masuk
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Masuk',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'v1.0.0 (UAS)',
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

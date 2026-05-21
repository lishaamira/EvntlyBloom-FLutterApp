import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/guest_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'admin/admin_main_screen.dart';

// ─────────────────────────────────────────────
//  EvntlyBloom — main.dart
//  Place this file at: lib/main.dart
// ─────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const EvntlyBloomApp());
}

class EvntlyBloomApp extends StatelessWidget {
  const EvntlyBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'EvntlyBloom',
      debugShowCheckedModeBanner: false,

      // ── EvntlyBloom theme ──────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8FBA72),
          primary:   const Color(0xFF1B4332),
          secondary: const Color(0xFFD4A574),
          surface:   const Color(0xFFE8E3D8),
        ),
        scaffoldBackgroundColor: const Color(0xFFE8E3D8),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B4332),
          foregroundColor: Colors.white,
          elevation:       0,
          centerTitle:     true,
          titleTextStyle:  TextStyle(
            fontFamily:  'Georgia',
            fontSize:    18,
            fontWeight:  FontWeight.bold,
            color:       Colors.white,
          ),
        ),

        // Elevated buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBFA882),
            foregroundColor: const Color(0xFF3B3228),
            minimumSize:     const Size(double.infinity, 52),
            elevation:       0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled:    true,
          fillColor: const Color(0xFFDDD5C5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                  color: Color(0xFF8B7355), width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                  color: Color(0xFF8B7355), width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                  color: Color(0xFF5C6B4A), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                  color: Colors.red, width: 1)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                  color: Colors.red, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
          hintStyle: const TextStyle(
              color: Color(0xFFADA99F), fontSize: 14),
        ),

        // Text styles
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontFamily:  'Georgia', fontSize: 32,
              fontWeight:  FontWeight.bold,
              color:       Color(0xFF5C6B4A)),
          headlineMedium: TextStyle(
              fontFamily:  'Georgia', fontSize: 24,
              fontWeight:  FontWeight.bold,
              color:       Color(0xFF5C6B4A)),
          titleLarge: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600,
              color:    Color(0xFF2C2C2A)),
          titleMedium: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color:    Color(0xFF2C2C2A)),
          bodyLarge:  TextStyle(
              fontSize: 15, color: Color(0xFF2C2C2A)),
          bodyMedium: TextStyle(
              fontSize: 13, color: Color(0xFF5F5E5A)),
        ),
      ),

      // ── Start at splash ────────────────────
      initialRoute: '/splash',

      // ── All app routes ─────────────────────
      routes: {
        '/splash':     (_) => const SplashScreen(),
        '/guest-home': (_) => const GuestHomeScreen(),
        '/login':      (_) => const LoginScreen(),
        '/register':   (_) => const RegisterScreen(),
        '/admin':      (_) => const AdminMainScreen(),
      },
    );
  }
}
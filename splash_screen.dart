import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'guest_home_screen.dart';
import 'main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
//  EvntlyBloom — Splash Screen
//  Place this file at: lib/screens/splash_screen.dart
// ─────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _taglineCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset>  _textSlide;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  Brightness.dark,
      systemNavigationBarColor: Color(0xFFE8E3D8),
    ));

    _logoCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _taglineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _taglineCtrl.forward();

    // AFTER
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final nextScreen = user != null ? const MainScreen() : const GuestHomeScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3D8),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(scale: _logoScale.value, child: child),
                    ),
                    child: const _LogoBadge(),
                  ),
                  const SizedBox(height: 38),
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _textOpacity.value,
                      child: SlideTransition(position: _textSlide, child: child),
                    ),
                    child: const Text(
                      'EvntlyBloom',
                      style: TextStyle(
                        fontFamily: 'Georgia', fontSize: 38,
                        fontWeight: FontWeight.bold, color: Color(0xFF5C6B4A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 36, left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _taglineCtrl,
                builder: (_, child) => Opacity(opacity: _taglineOpacity.value, child: child),
                child: const Text(
                  'Space ready for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF9A8F80), letterSpacing: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Logo image widget — big version for splash
// ─────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/evntlybloom_logo.png',
      width:  300,
      height: 300,
      fit:    BoxFit.contain,
      // Fallback if image not found
      errorBuilder: (_, __, ___) => Container(
        width: 250, height: 250,
        decoration: const BoxDecoration(
          color: Color(0xFF8FBA72),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('EvntlyBloom',
              style: TextStyle(
                fontFamily: 'Georgia', fontSize: 14,
                fontWeight: FontWeight.bold, color: Colors.white,
              )),
        ),
      ),
    );
  }
}
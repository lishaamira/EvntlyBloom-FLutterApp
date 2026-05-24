import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import '../admin/admin_main_screen.dart';

//login_screen//

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFF993C1D)
            : const Color(0xFF5C6B4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ── Sign in with Firebase Auth ───────
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // ── Check user doc in 'users' collection ──
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      // ── Check if account is disabled ─────
      if (userDoc.exists) {
        final status = userDoc.data()?['status'] ?? 'Active';
        if (status == 'Disabled') {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showSnackBar(
              'Your account has been disabled. Please contact support.',
            );
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // ── Check role from 'users collection' (admin check) ──
      final adminDoc = await FirebaseFirestore.instance
          .collection('users collection')
          .doc(cred.user!.uid)
          .get();

      final role = adminDoc.data()?['role'] ??
          userDoc.data()?['role'] ?? 'user';

      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed. Please try again.';
      if (e.code == 'user-not-found')     msg = 'No account found with this email.';
      if (e.code == 'wrong-password')     msg = 'Incorrect password.';
      if (e.code == 'invalid-email')      msg = 'Invalid email address.';
      if (e.code == 'invalid-credential') msg = 'Invalid email or password.';
      if (mounted) _showSnackBar(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3D8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              child: Column(
                children: [

                  // ── Top decorative header ────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5C6B4A),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(36)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/evntlybloom_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('EB',
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize:   18,
                                      fontWeight: FontWeight.bold,
                                      color:      Colors.white,
                                    )),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Welcome back',
                            style: TextStyle(
                              fontSize:   14,
                              color:      Colors.white70,
                              fontWeight: FontWeight.w400,
                            )),
                        const SizedBox(height: 4),
                        const Text('EvntlyBloom',
                            style: TextStyle(
                              fontFamily:    'Georgia',
                              fontSize:      34,
                              fontWeight:    FontWeight.bold,
                              color:         Colors.white,
                              letterSpacing: -0.5,
                            )),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue booking your perfect venue.',
                          style: TextStyle(
                            fontSize: 13,
                            color:    Colors.white60,
                            height:   1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Form ─────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const _FieldLabel(text: 'Email Address'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller:   _emailCtrl,
                            hint:         'you@email.com',
                            prefixIcon:   Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter your email';
                              if (!val.contains('@'))
                                return 'Please enter a valid email';
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          const _FieldLabel(text: 'Password'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller:  _passwordCtrl,
                            hint:        'Enter your password',
                            prefixIcon:  Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF8B7355),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter your password';
                              if (val.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width:  double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C6B4A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                                  : const Text('Log In',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize:   17,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(child: Divider(
                                  color: const Color(0xFFBFB8AA)
                                      .withOpacity(0.6))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B7355))),
                              ),
                              Expanded(child: Divider(
                                  color: const Color(0xFFBFB8AA)
                                      .withOpacity(0.6))),
                            ],
                          ),

                          const SizedBox(height: 24),

                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: const Color(0xFF5C6B4A),
                                    width: 1.5),
                              ),
                              child: const Text(
                                "Don't have an account? Register",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.w600,
                                  color:      Color(0xFF5C6B4A),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w700,
          color:      Color(0xFF3B3228),
        ));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final IconData                   prefixIcon;
  final bool                       obscureText;
  final TextInputType?             keyboardType;
  final Widget?                    suffixIcon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText  = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      validator:    validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF3B3228)),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  const TextStyle(color: Color(0xFFADA99F), fontSize: 14),
        filled:     true,
        fillColor:  const Color(0xFFDDD5C5),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF8B7355), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: Color(0xFFBFB8AA), width: 0.8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: Color(0xFF5C6B4A), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}
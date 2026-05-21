import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

//register_screen//

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey         = GlobalKey<FormState>();
  final _usernameCtrl    = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading              = false;

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
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
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

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ── Check if email belongs to a disabled account ──
      final disabledCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('email',  isEqualTo: _emailCtrl.text.trim())
          .where('status', isEqualTo: 'Disabled')
          .get();

      if (disabledCheck.docs.isNotEmpty) {
        if (mounted) {
          _showSnackBar(
            'This account has been disabled. Please contact support.',
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // ── Create Firebase Auth account ─────
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // ── Save to Firestore ─────────────────
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid':       cred.user!.uid,
        'username':  _usernameCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'role':      'user',
        'status':    'Active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed.';
      if (e.code == 'email-already-in-use')
        msg = 'This email is already registered.';
      if (e.code == 'weak-password') msg = 'Password is too weak.';
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

                  // ── Top header ───────────────
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Create Account',
                            style: TextStyle(
                              fontFamily:    'Georgia',
                              fontSize:      30,
                              fontWeight:    FontWeight.bold,
                              color:         Colors.white,
                              letterSpacing: -0.5,
                            )),
                        const SizedBox(height: 6),
                        const Text(
                          'Join EvntlyBloom and start booking your perfect venue today.',
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
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const _FieldLabel(text: 'Username'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _usernameCtrl,
                            hint:       'Choose a username',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter a username';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          const _FieldLabel(text: 'Phone Number'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller:   _phoneCtrl,
                            hint:         'e.g. 0123456789',
                            prefixIcon:   Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter your phone number';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

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

                          const SizedBox(height: 16),

                          const _FieldLabel(text: 'Create Password'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller:  _passwordCtrl,
                            hint:        'At least 6 characters',
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
                                return 'Please create a password';
                              if (val.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          const _FieldLabel(text: 'Confirm Password'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller:  _confirmPassCtrl,
                            hint:        'Re-enter your password',
                            prefixIcon:  Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF8B7355),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                      () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please confirm your password';
                              if (val != _passwordCtrl.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width:  double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onRegister,
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
                                  : const Text('Create Account',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize:   17,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                          ),

                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: () => Navigator.pop(context),
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
                                'Already have an account? Log In',
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
        hintStyle:  const TextStyle(
            color: Color(0xFFADA99F), fontSize: 14),
        filled:     true,
        fillColor:  const Color(0xFFDDD5C5),
        prefixIcon: Icon(prefixIcon,
            color: const Color(0xFF8B7355), size: 20),
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
            borderSide: const BorderSide(
                color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}
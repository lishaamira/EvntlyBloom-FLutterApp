import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guest_home_screen.dart';

// ─────────────────────────────────────────────
//  EvntlyBloom — User Profile Screen
// ─────────────────────────────────────────────

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _totalBookings    = 0;
  int _completedEvents  = 0;
  int _upcomingEvents   = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Load user profile
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      // Load bookings count
      final bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get();

      int completed = 0;
      int upcoming  = 0;
      for (final b in bookings.docs) {
        final data    = b.data();
        final dateStr = data['date'] ?? '';
        final parts   = dateStr.split('/');
        DateTime? dt;
        if (parts.length == 3) {
          dt = DateTime.tryParse(
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
        }
        final today = DateTime.now();
        if (dt != null && dt.isAfter(today.subtract(const Duration(days: 1)))) {
          upcoming++;
        } else {
          completed++;
        }
      }

      if (mounted) {
        setState(() {
          _userData       = data;
          _totalBookings  = bookings.docs.length;
          _completedEvents = completed;
          _upcomingEvents  = upcoming;
          _isLoading      = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Edit Profile dialog ───────────────────
  void _showEditProfileDialog() {
    final nameCtrl  = TextEditingController(
        text: _userData?['username'] ?? '');
    final phoneCtrl = TextEditingController(
        text: _userData?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFE8E3D8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF2C2416),
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(label: 'Full Name',     ctrl: nameCtrl),
            const SizedBox(height: 12),
            _DialogField(label: 'Phone Number',  ctrl: phoneCtrl,
                keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF8B7355)))),
          ElevatedButton(
              onPressed: () async {
                final uid = _auth.currentUser?.uid;
                if (uid == null) return;
                try {
                  await _firestore.collection('users').doc(uid).update({
                    'username': nameCtrl.text.trim(),
                    'phone':    phoneCtrl.text.trim(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _loadUserData();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile updated!'),
                            backgroundColor: Color(0xFF5C6B4A)));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'),
                            backgroundColor: const Color(0xFF993C1D)));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6B4A),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Save')),
        ],
      ),
    );
  }

  // ── Change Password dialog ────────────────
  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew     = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: const Color(0xFFE8E3D8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password',
              style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF2C2416),
              )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                label:       'Current Password',
                ctrl:        currentCtrl,
                obscureText: obscureCurrent,
                suffixIcon: IconButton(
                  icon: Icon(obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      size: 18, color: const Color(0xFF8B7355)),
                  onPressed: () =>
                      ss(() => obscureCurrent = !obscureCurrent),
                ),
              ),
              const SizedBox(height: 12),
              _DialogField(
                label:       'New Password',
                ctrl:        newCtrl,
                obscureText: obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      size: 18, color: const Color(0xFF8B7355)),
                  onPressed: () =>
                      ss(() => obscureNew = !obscureNew),
                ),
              ),
              const SizedBox(height: 12),
              _DialogField(
                label:       'Confirm New Password',
                ctrl:        confirmCtrl,
                obscureText: obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      size: 18, color: const Color(0xFF8B7355)),
                  onPressed: () =>
                      ss(() => obscureConfirm = !obscureConfirm),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF8B7355)))),
            ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text != confirmCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Passwords do not match.'),
                            backgroundColor: Color(0xFF993C1D)));
                    return;
                  }
                  if (newCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Password must be at least 6 characters.'),
                            backgroundColor: Color(0xFF993C1D)));
                    return;
                  }
                  try {
                    final user = _auth.currentUser!;
                    final cred = EmailAuthProvider.credential(
                      email:    user.email!,
                      password: currentCtrl.text,
                    );
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(newCtrl.text);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Password changed!'),
                              backgroundColor: Color(0xFF5C6B4A)));
                    }
                  } on FirebaseAuthException catch (e) {
                    String msg = 'Failed to change password.';
                    if (e.code == 'wrong-password')
                      msg = 'Current password is incorrect.';
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg),
                              backgroundColor:
                              const Color(0xFF993C1D)));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6B4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Change')),
          ],
        ),
      ),
    );
  }

  // ── Log out ───────────────────────────────
  void _logOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GuestHomeScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF5C6B4A)));
    }

    final username = _userData?['username'] ?? 'User';
    final email    = _userData?['email']    ?? '';
    final phone    = _userData?['phone']    ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [

          // ── Green header banner ────────────
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width:  double.infinity,
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [
                      Color(0xFF5C6B4A),
                      Color(0xFF7A8F65),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20, right: -20,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color:  Colors.white.withOpacity(0.06),
                          shape:  BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10, right: 40,
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color:  Colors.white.withOpacity(0.06),
                          shape:  BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10, left: 20,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color:  Colors.white.withOpacity(0.04),
                          shape:  BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -50,
                child: Container(
                  width:  100,
                  height: 100,
                  decoration: BoxDecoration(
                    color:  const Color(0xFFE8E3D8),
                    shape:  BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset:     const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size:  58,
                    color: Color(0xFF5C6B4A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 62),

          // ── Name + email ───────────────────
          Text(username,
              style: const TextStyle(
                fontFamily:  'Georgia',
                fontSize:    22,
                fontWeight:  FontWeight.w700,
                color:       Color(0xFF2C2416),
              )),
          const SizedBox(height: 4),
          Text(email,
              style: const TextStyle(
                fontSize: 13,
                color:    Color(0xFF8B7355),
              )),

          const SizedBox(height: 28),

          // ── Stats row ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon:  Icons.calendar_month_rounded,
                    value: '$_totalBookings',
                    label: 'Total\nBookings',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon:  Icons.check_circle_outline_rounded,
                    value: '$_completedEvents',
                    label: 'Completed\nEvents',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon:  Icons.upcoming_outlined,
                    value: '$_upcomingEvents',
                    label: 'Upcoming\nEvent',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text('Account Info',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF8B7355),
                      letterSpacing: 0.5,
                    )),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color:        const Color(0xFFDDD5C5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFBFB8AA), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _InfoTile(
                        icon:    Icons.person_outline_rounded,
                        label:   'Full Name',
                        value:   username,
                        isFirst: true,
                      ),
                      const Divider(height: 1,
                          color: Color(0xFFCCC5B8),
                          indent: 16, endIndent: 16),
                      _InfoTile(
                        icon:  Icons.phone_outlined,
                        label: 'Phone Number',
                        value: phone,
                      ),
                      const Divider(height: 1,
                          color: Color(0xFFCCC5B8),
                          indent: 16, endIndent: 16),
                      _InfoTile(
                        icon:   Icons.email_outlined,
                        label:  'E-mail',
                        value:  email,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Account',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF8B7355),
                      letterSpacing: 0.5,
                    )),

                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color:        const Color(0xFFDDD5C5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFBFB8AA), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _ActionTile(
                        icon:    Icons.edit_outlined,
                        label:   'Edit Profile',
                        isFirst: true,
                        onTap:   _showEditProfileDialog,
                      ),
                      const Divider(height: 1,
                          color: Color(0xFFCCC5B8),
                          indent: 16, endIndent: 16),
                      _ActionTile(
                        icon:  Icons.lock_outline_rounded,
                        label: 'Change Password',
                        onTap: _showChangePasswordDialog,
                      ),
                      const Divider(height: 1,
                          color: Color(0xFFCCC5B8),
                          indent: 16, endIndent: 16),
                      _ActionTile(
                        icon:      Icons.logout_rounded,
                        label:     'Log Out',
                        isLast:    true,
                        textColor: const Color(0xFF993C1D),
                        iconColor: const Color(0xFF993C1D),
                        onTap:     _logOut,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                const Center(
                  child: Text('EvntlyBloom v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color:    Color(0xFFADA99F),
                      )),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color:        const Color(0xFFDDD5C5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFB8AA), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF5C6B4A), size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.w800,
                color:      Color(0xFF2C2416),
              )),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color:    Color(0xFF8B7355),
                height:   1.3,
              )),
        ],
      ),
    );
  }
}

// ─── Info tile ────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final bool     isFirst;
  final bool     isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast  = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        const Color(0xFF5C6B4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: const Color(0xFF5C6B4A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 11,
                      color:    Color(0xFF8B7355),
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w500,
                      color:      Color(0xFF2C2416),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action tile ──────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  final bool         isFirst;
  final bool         isLast;
  final Color?       textColor;
  final Color?       iconColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFirst   = false,
    this.isLast    = false,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top:    isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast  ? const Radius.circular(16) : Radius.zero,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF5C6B4A))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: iconColor ?? const Color(0xFF5C6B4A),
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? const Color(0xFF2C2416),
                  )),
            ),
            Icon(Icons.chevron_right,
                color: (textColor ?? const Color(0xFF8B7355))
                    .withOpacity(0.5),
                size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Dialog Field ─────────────────────────────
class _DialogField extends StatelessWidget {
  final String                label;
  final TextEditingController ctrl;
  final bool                  obscureText;
  final TextInputType?        keyboardType;
  final Widget?               suffixIcon;

  const _DialogField({
    required this.label,
    required this.ctrl,
    this.obscureText  = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      Color(0xFF3B3228),
            )),
        const SizedBox(height: 6),
        TextField(
          controller:   ctrl,
          obscureText:  obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF3B3228)),
          decoration: InputDecoration(
            filled:      true,
            fillColor:   const Color(0xFFEDE8E0),
            suffixIcon:  suffixIcon,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFCCC5B8), width: 0.8)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFCCC5B8), width: 0.8)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF5C6B4A), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
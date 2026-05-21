import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard_screen.dart';
import 'admin_venues_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_users_screen.dart';
import '../screens/guest_home_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final int initialIndex;
  const AdminMainScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainScreen> createState() => AdminMainScreenState();
}

class AdminMainScreenState extends State<AdminMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setIndex(int i) => setState(() => _currentIndex = i);

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFE8E3D8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF2C2416))),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(fontSize: 13, color: Color(0xFF5C5040))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8B7355))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF993C1D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GuestHomeScreen()),
              (route) => false,
        );
      }
    }
  }

  static const _labels       = ['Dashboard', 'Venues', 'Bookings', 'Users'];
  static const _icons        = [
    Icons.dashboard_outlined,
    Icons.location_city_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outline_rounded,
  ];
  static const _iconsSelected = [
    Icons.dashboard_rounded,
    Icons.location_city_rounded,
    Icons.calendar_month_rounded,
    Icons.people_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3D8),
      body: SafeArea(
        child: Column(
          children: [

            // ── Admin nav bar ──────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE8E3D8),
                border: Border(
                    bottom: BorderSide(
                        color: Color(0xFFCCC5B8), width: 0.5)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 16), // pushes title right
                        const Icon(Icons.admin_panel_settings_outlined,
                            color: Color(0xFF5C6B4A), size: 16),
                        const SizedBox(width: 6),
                        const Text('EvntlyBloom Admin',
                            style: TextStyle(
                              fontFamily:    'Georgia',
                              fontSize:      16,
                              fontWeight:    FontWeight.w600,
                              color:         Color(0xFF5C6B4A),
                              letterSpacing: 0.3,
                            )),
                        const Spacer(),
                        // ── Logout button ──────
                        GestureDetector(
                          onTap: _logout,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded,
                                    color: Color(0xFF993C1D), size: 18),
                                SizedBox(width: 4),
                                Text('Logout',
                                    style: TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w600,
                                      color:      Color(0xFF993C1D),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      padding:    const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5C6B4A).withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: List.generate(_labels.length, (i) {
                          final sel = i == _currentIndex;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setIndex(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF5C6B4A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: sel
                                      ? [BoxShadow(
                                      color: const Color(0xFF5C6B4A)
                                          .withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      sel ? _iconsSelected[i] : _icons[i],
                                      size:  16,
                                      color: sel
                                          ? Colors.white
                                          : const Color(0xFF6B7B60),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(_labels[i],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:   10,
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: sel
                                              ? Colors.white
                                              : const Color(0xFF6B7B60),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page content ───────────────────
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  AdminDashboardScreen(),
                  AdminVenuesScreen(),
                  AdminBookingsScreen(),
                  AdminUsersScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
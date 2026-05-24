import 'package:flutter/material.dart';
import 'user_home_screen.dart';
import 'user_venue_screen.dart';
import 'user_my_bookings_screen.dart';
import 'user_profile_screen.dart';

// ─────────────────────────────────────────────
//  EvntlyBloom — Main Screen
//  Place this file at: lib/screens/main_screen.dart
// ─────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => MainScreenState();
}

// Public state so child screens can call setIndex()
class MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setIndex(int i) => setState(() => _currentIndex = i);

  static const _labels = ['Home', 'Venues', 'My Bookings', 'Profile'];

  static const _icons = [
    Icons.home_outlined,
    Icons.location_city_outlined,
    Icons.calendar_month_outlined,
    Icons.person_outline,
  ];

  static const _iconsSelected = [
    Icons.home_rounded,
    Icons.location_city_rounded,
    Icons.calendar_month_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3D8),
      body: SafeArea(
        child: Column(
          children: [

            // ── Nav bar ────────────────────────
            _NavBar(
              currentIndex: _currentIndex,
              onTap:        setIndex,
              labels:       _labels,
              icons:        _icons,
              iconsSelected: _iconsSelected,
            ),

            // ── Page content ───────────────────
            Expanded(
              child: IndexedStack(
                index:    _currentIndex,
                children: const [
                  UserHomeScreen(),
                  UserVenueScreen(),
                  UserMyBookingsScreen(),
                  UserProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Nav bar — green aesthetic, single instance
// ─────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final int                currentIndex;
  final void Function(int) onTap;
  final List<String>       labels;
  final List<IconData>     icons;
  final List<IconData>     iconsSelected;

  const _NavBar({
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    required this.icons,
    required this.iconsSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8E3D8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFCCC5B8), width: 0.5),
        ),
      ),
      child: Column(
        children: [

          // ── EvntlyBloom title ────────────────
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 10),
            child: Text(
              'EvntlyBloom',
              style: TextStyle(
                fontFamily:    'Georgia',
                fontSize:      17,
                fontWeight:    FontWeight.w600,
                color:         Color(0xFF5C6B4A),
                letterSpacing: 0.3,
              ),
            ),
          ),

          // ── Nav pills ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding:    const EdgeInsets.all(4),
              decoration: BoxDecoration(
                // Slightly green-tinted background
                color: const Color(0xFFDDD5C5),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:      const Color(0xFF5C6B4A).withOpacity(0.08),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(labels.length, (i) {
                  final selected = i == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve:    Curves.easeInOut,
                        padding:  const EdgeInsets.symmetric(
                            vertical: 8),
                        decoration: BoxDecoration(
                          // Selected pill: soft green
                          color: selected
                              ? const Color(0xFF5C6B4A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: selected
                              ? [BoxShadow(
                            color: const Color(0xFF5C6B4A)
                                .withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration:
                              const Duration(milliseconds: 200),
                              child: Icon(
                                selected
                                    ? iconsSelected[i]
                                    : icons[i],
                                key: ValueKey(selected),
                                size:  16,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7B60),
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration:
                              const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontSize:   10,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF6B7B60),
                              ),
                              child: Text(
                                labels[i],
                                textAlign: TextAlign.center,
                              ),
                            ),
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
    );
  }
}
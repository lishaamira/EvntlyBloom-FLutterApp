import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final PageController _bannerCtrl = PageController();
  int _currentBanner = 0;

  String  _username       = '';
  bool    _loadingUser    = true;

  Map<String, dynamic>? _upcomingBooking;
  bool    _loadingBooking = true;

  final List<String> _bannerImages = [
    'assets/images/conf1.jpg',
    'assets/images/hall1.png',
    'assets/images/conf2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUpcomingBooking();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_currentBanner + 1) % _bannerImages.length;
      _bannerCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _startAutoSlide();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _username    = doc.data()?['username'] ?? 'there';
          _loadingUser = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  // ── FIXED: no orderBy, filter by date in code ──
  Future<void> _loadUpcomingBooking() async {
    if (mounted) setState(() => _loadingBooking = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loadingBooking = false);
        return;
      }

      // Only filter by userId — no orderBy to avoid index issues
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get();

      final today = DateTime.now();
      Map<String, dynamic>? soonest;
      DateTime? soonestDate;

      for (final doc in snap.docs) {
        final data   = doc.data();
        final status = data['status'] ?? '';

        // Skip cancelled bookings
        if (status == 'Cancelled') continue;

        // Parse date "d/m/yyyy"
        final dateStr = data['date'] ?? '';
        final parts   = dateStr.split('/');
        if (parts.length != 3) continue;

        final dt = DateTime.tryParse(
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}',
        );
        if (dt == null) continue;

        // Must be today or in the future
        if (dt.isBefore(today.subtract(const Duration(days: 1)))) continue;

        // Pick the soonest upcoming booking
        if (soonestDate == null || dt.isBefore(soonestDate)) {
          soonestDate = dt;
          soonest     = {'id': doc.id, ...data};
        }
      }

      if (mounted) {
        setState(() {
          _upcomingBooking = soonest;
          _loadingBooking  = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading booking: $e');
      if (mounted) setState(() => _loadingBooking = false);
    }
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic price) {
    final p = (price is double)
        ? price.toInt()
        : (price is int ? price : 0);
    return p.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadUserData(), _loadUpcomingBooking()]);
      },
      color: const Color(0xFF5C6B4A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),

            // ── Greeting row ─────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,',
                          style: TextStyle(
                            fontSize:   14,
                            color:      Color(0xFF8B7355),
                            fontWeight: FontWeight.w400,
                          )),
                      const SizedBox(height: 2),
                      _loadingUser
                          ? const SizedBox(
                        height: 28, width: 120,
                        child: LinearProgressIndicator(
                          color:           Color(0xFF5C6B4A),
                          backgroundColor: Color(0xFFDDD5C5),
                          borderRadius:    BorderRadius.all(
                              Radius.circular(4)),
                        ),
                      )
                          : Text('$_username.',
                        style: const TextStyle(
                          fontSize:   24,
                          fontWeight: FontWeight.w800,
                          color:      Color(0xFF2C2416),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      _loadingUser    = true;
                      _loadingBooking = true;
                    });
                    await Future.wait(
                        [_loadUserData(), _loadUpcomingBooking()]);
                  },
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color:        const Color(0xFFDDD5C5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFBFB8AA), width: 0.5),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF5C6B4A), size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Banner slider ─────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller:    _bannerCtrl,
                      onPageChanged: (i) =>
                          setState(() => _currentBanner = i),
                      itemCount: _bannerImages.length,
                      itemBuilder: (_, i) => Image.asset(
                        _bannerImages[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFCCC5B8),
                          child: const Center(
                              child: Icon(Icons.image_outlined,
                                  color: Color(0xFF8B7355), size: 40)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Left arrow
                Positioned(
                  left: 8, top: 0, bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_currentBanner > 0) {
                          _bannerCtrl.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve:    Curves.easeInOut);
                        }
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
                // Right arrow
                Positioned(
                  right: 8, top: 0, bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_currentBanner < _bannerImages.length - 1) {
                          _bannerCtrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve:    Curves.easeInOut);
                        }
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_right,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
                // Dot indicators
                Positioned(
                  bottom: 10, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _bannerImages.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width:  _currentBanner == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentBanner == i
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Upcoming Booking ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Upcoming Booking',
                    style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF2C2416),
                    )),
                if (!_loadingBooking && _upcomingBooking != null)
                  GestureDetector(
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<MainScreenState>();
                      state?.setIndex(2);
                    },
                    child: const Text('See all →',
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFF5C6B4A),
                        )),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Loading ────────────────────────
            if (_loadingBooking)
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color:        const Color(0xFFDDD5C5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF5C6B4A), strokeWidth: 2),
                ),
              )

            // ── No upcoming bookings ───────────
            else if (_upcomingBooking == null)
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        const Color(0xFFDDD5C5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFBFB8AA), width: 0.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF8B7355), size: 36),
                    const SizedBox(height: 10),
                    const Text('No upcoming bookings',
                        style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFF5C5040),
                        )),
                    const SizedBox(height: 4),
                    const Text(
                      'Book a venue below to get started!',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF8B7355)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          final state = context
                              .findAncestorStateOfType<MainScreenState>();
                          state?.setIndex(1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6B4A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Book Now',
                            style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  ],
                ),
              )

            // ── Upcoming booking card ──────────
            else
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        const Color(0xFF5C6B4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('NEXT EVENT',
                              style: TextStyle(
                                fontSize:      10,
                                fontWeight:    FontWeight.w600,
                                color:         Colors.white,
                                letterSpacing: 1.2,
                              )),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _upcomingBooking!['status'] ?? 'Confirmed',
                            style: const TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.w600,
                              color:      Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (_upcomingBooking!['venueName'] ?? '')
                          .toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize:   20,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: [
                        _WhitePill(text: _upcomingBooking!['date'] ?? ''),
                        _WhitePill(
                            text: _upcomingBooking!['timeSlot'] ?? ''),
                        if ((_upcomingBooking!['guestRange'] ?? '')
                            .isNotEmpty)
                          _WhitePill(
                              text: '${_upcomingBooking!['guestRange']}'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white70)),
                            Text(
                              'RM ${_formatPrice(_upcomingBooking!['totalPrice'])}',
                              style: const TextStyle(
                                fontSize:   18,
                                fontWeight: FontWeight.w800,
                                color:      Colors.white,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () {
                            final state = context
                                .findAncestorStateOfType<MainScreenState>();
                            state?.setIndex(2);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white54, width: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('View',
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Book a Venue ──────────────────
            const Text('Book a Venue',
                style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF2C2416),
                )),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _VenueCategoryCard(
                    icon:     Icons.account_balance_outlined,
                    title:    'Event Hall',
                    subtitle: 'Weddings, galas,\nprom dinner, etc',
                    color:    const Color(0xFF5C6B4A),
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<MainScreenState>();
                      state?.setIndex(1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VenueCategoryCard(
                    icon:     Icons.desktop_windows_outlined,
                    title:    'Conference Room',
                    subtitle: 'Meetings,\nseminars, etc',
                    color:    const Color(0xFF8B7355),
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<MainScreenState>();
                      state?.setIndex(1);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Quick Stats ───────────────────
            _QuickStatsRow(
                uid: FirebaseAuth.instance.currentUser?.uid ?? ''),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _WhitePill extends StatelessWidget {
  final String text;
  const _WhitePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }
}

// ─────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final String uid;
  const _QuickStatsRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final all       = snap.data!.docs;
        final total     = all.length;
        final confirmed = all
            .where((d) => (d.data() as Map)['status'] == 'Confirmed')
            .length;
        final cancelled = all
            .where((d) => (d.data() as Map)['status'] == 'Cancelled')
            .length;

        if (total == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Activity',
                style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF2C2416),
                )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    value: '$total',
                    label: 'Total\nBookings',
                    icon:  Icons.calendar_month_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    value: '$confirmed',
                    label: 'Confirmed',
                    icon:  Icons.check_circle_outline_rounded,
                    color: const Color(0xFF5C6B4A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    value: '$cancelled',
                    label: 'Cancelled',
                    icon:  Icons.cancel_outlined,
                    color: const Color(0xFF993C1D),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String   value;
  final String   label;
  final IconData icon;
  final Color    color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    this.color = const Color(0xFF8B7355),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFFDDD5C5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFB8AA), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.w800,
                color:      color,
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

// ─────────────────────────────────────────────
class _VenueCategoryCard extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final Color        color;
  final VoidCallback onTap;

  const _VenueCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        const Color(0xFFDDD5C5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFB8AA), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF2C2416),
                )),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color:    Color(0xFF7A7060),
                  height:   1.4,
                )),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Explore',
                    style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color:      color,
                    )),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 12, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
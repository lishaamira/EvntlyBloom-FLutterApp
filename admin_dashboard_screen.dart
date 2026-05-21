import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_main_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;

  int    _bookingsToday  = 0;
  double _revenueToday   = 0;
  int    _totalVenues    = 0;
  int    _totalUsers     = 0;

  List<Map<String, dynamic>> _recentBookings = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final now   = DateTime.now();
      final today = '${now.day}/${now.month}/${now.year}';

      // ── All bookings ──────────────────────
      final bookingSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      int    bookingsToday = 0;
      double revenueToday  = 0;

      for (final doc in bookingSnap.docs) {
        final data = doc.data();
        if ((data['date'] ?? '') == today) {
          bookingsToday++;
          revenueToday += (data['totalPrice'] ?? 0) is int
              ? (data['totalPrice'] as int).toDouble()
              : (data['totalPrice'] ?? 0.0) as double;
        }
      }

      // ── Recent 5 bookings ─────────────────
      final recent = bookingSnap.docs
          .take(5)
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      // ── Total venues ──────────────────────
      final venueSnap = await FirebaseFirestore.instance
          .collection('venues')
          .get();

      // ── Total users (exclude admins) ──────
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      if (mounted) {
        setState(() {
          _bookingsToday = bookingsToday;
          _revenueToday  = revenueToday;
          _totalVenues   = venueSnap.docs.length;
          _totalUsers    = userSnap.docs.length;
          _recentBookings = recent;
          _isLoading     = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFF5C6B4A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 8),

            // ── Welcome ──────────────────────
            const Text('Welcome, Admin.',
                style: TextStyle(
                  fontFamily:  'Georgia',
                  fontSize:    22,
                  fontWeight:  FontWeight.w700,
                  color:       Color(0xFF2C2416),
                )),
            const SizedBox(height: 4),
            const Text("Here's what's happening today.",
                style: TextStyle(fontSize: 13, color: Color(0xFF8B7355))),

            const SizedBox(height: 20),

            // ── Stats grid ───────────────────
            _isLoading
                ? Container(
              height: 160,
              decoration: BoxDecoration(
                color:        const Color(0xFFDDD5C5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF5C6B4A)),
              ),
            )
                : GridView.count(
              shrinkWrap:       true,
              physics:          const NeverScrollableScrollPhysics(),
              crossAxisCount:   2,
              crossAxisSpacing: 12,
              mainAxisSpacing:  12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  icon:      Icons.calendar_today_rounded,
                  label:     'Bookings Today',
                  value:     '$_bookingsToday',
                  iconColor: const Color(0xFF5C6B4A),
                  bgColor:   const Color(0xFFE8F0E3),
                ),
                _StatCard(
                  icon:      Icons.attach_money_rounded,
                  label:     'Revenue Today',
                  value:     'RM ${_formatPrice(_revenueToday)}',
                  iconColor: const Color(0xFF8B7355),
                  bgColor:   const Color(0xFFF0EBE3),
                ),
                _StatCard(
                  icon:      Icons.location_city_rounded,
                  label:     'Total Venues',
                  value:     '$_totalVenues',
                  iconColor: const Color(0xFF5C6B4A),
                  bgColor:   const Color(0xFFE8F0E3),
                ),
                _StatCard(
                  icon:      Icons.people_rounded,
                  label:     'Total Users',
                  value:     '$_totalUsers',
                  iconColor: const Color(0xFF8B7355),
                  bgColor:   const Color(0xFFF0EBE3),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Quick actions ─────────────────
            const Text('Quick Actions',
                style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF2C2416),
                )),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon:  Icons.add_business_rounded,
                    label: 'Add Venue',
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<AdminMainScreenState>();
                      state?.setIndex(1);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon:  Icons.calendar_month_rounded,
                    label: 'All Bookings',
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<AdminMainScreenState>();
                      state?.setIndex(2);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon:  Icons.people_rounded,
                    label: 'Manage Users',
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<AdminMainScreenState>();
                      state?.setIndex(3);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Recent bookings ───────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Bookings',
                    style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF2C2416),
                    )),
                GestureDetector(
                  onTap: _loadDashboard,
                  child: const Icon(Icons.refresh,
                      color: Color(0xFF8B7355), size: 18),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF5C6B4A)),
              )
            else if (_recentBookings.isEmpty)
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        const Color(0xFFDDD5C5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFBFB8AA), width: 0.5),
                ),
                child: const Center(
                  child: Text('No bookings yet.',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF8B7355))),
                ),
              )
            else
              ..._recentBookings.map(
                      (b) => _RecentBookingCard(booking: b)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _RecentBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _RecentBookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':    return const Color(0xFF5C6B4A);
      case 'Pending Edit': return const Color(0xFFB87A00);
      case 'Cancelled':    return const Color(0xFF993C1D);
      default:             return const Color(0xFF8B7355);
    }
  }

  String _formatPrice(dynamic price) {
    final p = price is double
        ? price.toInt()
        : (price is int ? price : 0);
    return p.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0xFFDDD5C5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFB8AA), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        const Color(0xFF5C6B4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: Color(0xFF5C6B4A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['name'] ?? '',
                    style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      Color(0xFF2C2416),
                    )),
                const SizedBox(height: 2),
                Text(
                  '${booking['venueName'] ?? ''}  •  ${booking['date'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8B7355)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RM ${_formatPrice(booking['totalPrice'])}',
                  style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF2C2416),
                  )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      _statusColor(status),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    iconColor;
  final Color    bgColor;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0xFFDDD5C5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFB8AA), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF2C2416),
                  )),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8B7355))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color:        const Color(0xFF5C6B4A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w500,
                  color:      Colors.white,
                  height:     1.3,
                )),
          ],
        ),
      ),
    );
  }
}
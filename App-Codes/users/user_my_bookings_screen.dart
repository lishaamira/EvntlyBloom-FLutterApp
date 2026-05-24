import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
//  EvntlyBloom — User My Bookings Screen
// ─────────────────────────────────────────────

const _hallTimeSlots = [
  '8:00 AM – 1:00 PM',
  '2:00 PM – 7:00 PM',
  '6:00 PM – 11:00 PM',
];
const _confTimeSlots = [
  '8:00 AM – 10:00 AM',
  '11:00 AM – 1:00 PM',
  '3:00 PM – 5:00 PM',
  '6:00 PM – 8:00 PM',
];

String _imagePath(Map<String, dynamic> booking) {
  final stored = booking['imagePath'] as String?;
  if (stored != null && stored.isNotEmpty) return stored;
  final type = booking['venueType'] ?? 'event_hall';
  return type == 'event_hall'
      ? 'assets/images/hall1.png'
      : 'assets/images/conf1.jpg';
}

DateTime? _parseDate(String date) {
  try {
    final p = date.split('/');
    if (p.length != 3) return null;
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  } catch (_) {
    return null;
  }
}

String _formatPrice(double price) {
  return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─────────────────────────────────────────────
class UserMyBookingsScreen extends StatefulWidget {
  const UserMyBookingsScreen({super.key});

  @override
  State<UserMyBookingsScreen> createState() => _UserMyBookingsScreenState();
}

class _UserMyBookingsScreenState extends State<UserMyBookingsScreen>
    with SingleTickerProviderStateMixin {
  bool    _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _past     = [];

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) { setState(() => _isLoading = false); return; }

      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get();

      final today    = DateTime.now();
      final upcoming = <Map<String, dynamic>>[];
      final past     = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = {'id': doc.id, ...doc.data()};
        final dt   = _parseDate(data['date'] ?? '');
        if (dt != null && dt.isAfter(today.subtract(const Duration(days: 1)))) {
          upcoming.add(data);
        } else {
          past.add(data);
        }
      }

      upcoming.sort((a, b) {
        final da = _parseDate(a['date'] ?? '');
        final db = _parseDate(b['date'] ?? '');
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });
      past.sort((a, b) {
        final da = _parseDate(a['date'] ?? '');
        final db = _parseDate(b['date'] ?? '');
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _upcoming  = upcoming;
          _past      = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // ── Cancel ────────────────────────────────
  void _cancelBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFE8E3D8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: Color(0xFF2C2416))),
        content: Text(
          'Are you sure you want to cancel your booking for '
              '${booking['venueName']} on ${booking['date']}?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF5C5040)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep It',
                style: TextStyle(color: Color(0xFF8B7355))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(booking['id'])
                    .delete();
                if (mounted) {
                  _showSnackBar('Booking cancelled.', isError: true);
                  _loadBookings();
                }
              } catch (e) {
                if (mounted) _showSnackBar('Error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF993C1D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  // ── Request Edit ──────────────────────────
  void _requestEdit(Map<String, dynamic> booking) {
    final venueType = booking['venueType'] ?? 'event_hall';
    final timeSlots = venueType == 'event_hall' ? _hallTimeSlots : _confTimeSlots;

    DateTime? selectedDate =
        _parseDate(booking['date'] ?? '') ?? DateTime.now().add(const Duration(days: 1));
    String? selectedTimeSlot   = booking['timeSlot'];
    String? selectedGuestRange = booking['guestRange'];

    final guestRanges = venueType == 'event_hall'
        ? ['100 pax', '200 pax', '300 pax', '400 pax',
      '500 pax', '600 pax', '1,000 pax', '1,500 pax', '2,000 pax']
        : ['50 pax', '75 pax', '100 pax', '200 pax',
      '300 pax', '350 pax', '400 pax', '500 pax', '600 pax'];

    if ((booking['status'] ?? '') == 'Pending Edit') {
      _showSnackBar('You already have a pending edit request.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE8E3D8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 36),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFB8AA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Edit',
                            style: TextStyle(fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2416))),
                        SizedBox(height: 2),
                        Text('Awaiting admin approval after submit.',
                            style: TextStyle(fontSize: 12,
                                color: Color(0xFF8B7355))),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDD5C5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close,
                            color: Color(0xFF8B7355), size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Date
                const _SheetLabel(text: 'Event Date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF5C6B4A),
                            onPrimary: Colors.white,
                            surface: Color(0xFFE8E3D8),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) ss(() => selectedDate = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDD5C5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFBFB8AA), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C6B4A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today_outlined,
                              size: 18, color: Color(0xFF5C6B4A)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null
                              ? 'Select a date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF3B3228),
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: Color(0xFF8B7355), size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Time slot
                const _SheetLabel(text: 'Time Slot'),
                const SizedBox(height: 8),
                Column(
                  children: timeSlots.map((slot) {
                    final sel = selectedTimeSlot == slot;
                    return GestureDetector(
                      onTap: () => ss(() =>
                      selectedTimeSlot = sel ? null : slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF5C6B4A)
                              : const Color(0xFFDDD5C5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF5C6B4A)
                                : const Color(0xFFBFB8AA),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sel ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              size: 20,
                              color: sel ? Colors.white : const Color(0xFF8B7355),
                            ),
                            const SizedBox(width: 12),
                            Text(slot,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: sel ? Colors.white : const Color(0xFF3B3228),
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Guest range
                const _SheetLabel(text: 'Number of Guests'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: guestRanges.map((range) {
                    final sel = selectedGuestRange == range;
                    return GestureDetector(
                      onTap: () => ss(() =>
                      selectedGuestRange = sel ? null : range),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF5C6B4A)
                              : const Color(0xFFDDD5C5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF5C6B4A)
                                : const Color(0xFFBFB8AA),
                            width: 0.8,
                          ),
                        ),
                        child: Text(range,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: sel ? Colors.white : const Color(0xFF3B3228),
                            )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedDate == null ||
                          selectedTimeSlot == null ||
                          selectedGuestRange == null) {
                        _showSnackBar('Please select all fields.');
                        return;
                      }
                      final newDate =
                          '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
                      Navigator.pop(ctx);
                      try {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(booking['id'])
                            .update({
                          'status': 'Pending Edit',
                          'editRequest': {
                            'date':        newDate,
                            'timeSlot':    selectedTimeSlot,
                            'guestRange':  selectedGuestRange,
                            'requestedAt': FieldValue.serverTimestamp(),
                          },
                        });
                        if (mounted) {
                          _showSnackBar(
                              'Edit request sent! Awaiting admin approval.');
                          _loadBookings();
                        }
                      } catch (e) {
                        if (mounted) _showSnackBar('Error: $e', isError: true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6B4A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Submit Edit Request',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
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

  Widget _statusBadge(String status) {
    Color bg; Color fg; IconData icon;
    switch (status) {
      case 'Confirmed':
        bg = const Color(0xFF5C6B4A).withOpacity(0.12);
        fg = const Color(0xFF5C6B4A);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'Pending Edit':
        bg = const Color(0xFFF5A623).withOpacity(0.15);
        fg = const Color(0xFFB87A00);
        icon = Icons.pending_outlined;
        break;
      default:
        bg = const Color(0xFFCCC5B8);
        fg = const Color(0xFF5C5040);
        icon = Icons.info_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5C6B4A)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF993C1D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: Color(0xFF993C1D), size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Failed to load bookings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2416))),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8B7355))),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6B4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [

        // ── Header ──────────────────────────
        Container(
          color: const Color(0xFFE8E3D8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Bookings',
                      style: TextStyle(
                        fontFamily:  'Georgia',
                        fontSize:    22,
                        fontWeight:  FontWeight.w700,
                        color:       Color(0xFF2C2416),
                      )),
                  GestureDetector(
                    onTap: _loadBookings,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFBFB8AA), width: 0.5),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Color(0xFF5C6B4A), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_upcoming.length} upcoming · ${_past.length} past',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF8B7355)),
              ),
              const SizedBox(height: 16),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD5C5),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: const Color(0xFF5C6B4A),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF7A7060),
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400),
                  tabs: [
                    Tab(text: 'Upcoming (${_upcoming.length})'),
                    Tab(text: 'Past (${_past.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),

        // ── Tab content ──────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [

              // ── Upcoming tab ───────────────
              RefreshIndicator(
                onRefresh: _loadBookings,
                color: const Color(0xFF5C6B4A),
                child: _upcoming.isEmpty
                    ? const _EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No Upcoming Bookings',
                  subtitle: 'Your confirmed bookings will appear here.',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _upcoming.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BookingCard(
                      booking:       _upcoming[i],
                      isUpcoming:    true,
                      onCancel:      () => _cancelBooking(_upcoming[i]),
                      onRequestEdit: () => _requestEdit(_upcoming[i]),
                      statusBadge:
                      _statusBadge(_upcoming[i]['status'] ?? ''),
                    ),
                  ),
                ),
              ),

              // ── Past tab ───────────────────
              RefreshIndicator(
                onRefresh: _loadBookings,
                color: const Color(0xFF5C6B4A),
                child: _past.isEmpty
                    ? const _EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No Past Bookings',
                  subtitle: 'Your booking history will appear here.',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _past.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BookingCard(
                      booking:    _past[i],
                      isUpcoming: false,
                      statusBadge:
                      _statusBadge(_past[i]['status'] ?? ''),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Booking Card
// ─────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool                 isUpcoming;
  final VoidCallback?        onCancel;
  final VoidCallback?        onRequestEdit;
  final Widget               statusBadge;

  const _BookingCard({
    required this.booking,
    required this.isUpcoming,
    required this.statusBadge,
    this.onCancel,
    this.onRequestEdit,
  });

  @override
  Widget build(BuildContext context) {
    final venueName = booking['venueName'] ?? '';
    final imgPath   = _imagePath(booking);
    final addOns    = List<String>.from(booking['addOns'] ?? []);
    final isPending = (booking['status'] ?? '') == 'Pending Edit';
    final editReq   = booking['editRequest'] as Map<String, dynamic>?;
    final rawPrice  = booking['totalPrice'];
    final price     = rawPrice != null
        ? _formatPrice((rawPrice as num).toDouble()) : '0';

    return Container(
      decoration: BoxDecoration(
        color:        const Color(0xFFDDD5C5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFB8AA), width: 0.5),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Venue image (upcoming only) ──
          if (isUpcoming)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: Image.asset(
                    imgPath,
                    height: 150,
                    width:  double.infinity,
                    fit:    BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      color:  const Color(0xFFCCC5B8),
                      child:  const Center(
                        child: Icon(Icons.image_outlined,
                            color: Color(0xFF8B7355), size: 40),
                      ),
                    ),
                  ),
                ),
                // Venue name overlay
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end:   Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(venueName,
                              style: const TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700,
                                color:      Colors.white,
                              )),
                        ),
                        statusBadge,
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // ── Info section ─────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Status for past cards
                if (!isUpcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(venueName,
                            style: const TextStyle(
                              fontSize:   15,
                              fontWeight: FontWeight.w700,
                              color:      Color(0xFF2C2416),
                            )),
                        statusBadge,
                      ],
                    ),
                  ),

                // Booking ID chip
                if (isUpcoming && (booking['bookingId'] ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6B4A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID: ${booking['bookingId']}',
                      style: const TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      Color(0xFF5C6B4A),
                      ),
                    ),
                  ),

                // Info rows
                _InfoRow(
                    icon:  Icons.person_outline_rounded,
                    label: booking['name'] ?? ''),
                _InfoRow(
                    icon:  Icons.phone_outlined,
                    label: booking['phone'] ?? ''),
                _InfoRow(
                    icon:  Icons.calendar_today_outlined,
                    label: '${booking['date'] ?? ''}'),
                _InfoRow(
                    icon:  Icons.access_time_rounded,
                    label: booking['timeSlot'] ?? ''),
                _InfoRow(
                    icon:  Icons.people_outline_rounded,
                    label: booking['guestRange'] ?? ''),
                _InfoRow(
                    icon:  Icons.payment_outlined,
                    label: booking['payment'] ?? ''),

                if (addOns.isNotEmpty)
                  _InfoRow(
                      icon:  Icons.add_circle_outline_rounded,
                      label: addOns.join(', ')),

                const SizedBox(height: 8),

                // Total price
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6B4A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Paid',
                          style: TextStyle(
                            fontSize:   12,
                            color:      Color(0xFF5C5040),
                            fontWeight: FontWeight.w500,
                          )),
                      Text('RM $price',
                          style: const TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w800,
                            color:      Color(0xFF5C6B4A),
                          )),
                    ],
                  ),
                ),

                // Pending edit notice
                if (isPending && editReq != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF5A623).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.pending_outlined,
                                size: 14, color: Color(0xFFB87A00)),
                            SizedBox(width: 6),
                            Text('Pending Edit Request',
                                style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700,
                                  color:      Color(0xFFB87A00),
                                )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '📅  ${editReq['date'] ?? ''}   '
                              '🕐  ${editReq['timeSlot'] ?? ''}   '
                              '👥  ${editReq['guestRange'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF5C5040),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons (upcoming only)
                if (isUpcoming) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRequestEdit,
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5C6B4A),
                            side: const BorderSide(
                                color: Color(0xFF5C6B4A), width: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel_outlined, size: 15),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF993C1D),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8B7355)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF3B3228))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFDDD5C5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF8B7355), size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF2C2416),
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8B7355))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w700,
          color:      Color(0xFF2C2416),
        ));
  }
}
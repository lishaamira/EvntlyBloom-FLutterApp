import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _filterStatus = 'All';
  final _searchCtrl    = TextEditingController();
  String _searchQuery  = '';
  bool   _isLoading    = true;

  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _bookings  = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _bookings.where((b) {
      final matchSearch = _searchQuery.isEmpty ||
          (b['name']  ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (b['venueName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _filterStatus == 'All' ||
          (b['status'] ?? '') == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':    return const Color(0xFF5C6B4A);
      case 'Pending Edit': return const Color(0xFFB87A00);
      case 'Cancelled':    return const Color(0xFF993C1D);
      default:             return const Color(0xFF8B7355);
    }
  }

  // ── Update booking status in Firestore ──────
  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      final update = {'status': newStatus};
      // If approving an edit request, apply the editRequest fields
      if (newStatus == 'Confirmed') {
        final booking = _bookings.firstWhere((b) => b['id'] == docId);
        final editReq = booking['editRequest'] as Map<String, dynamic>?;
        if (editReq != null) {
          update['date']      = editReq['date'];
          update['timeSlot']  = editReq['timeSlot'];
          update['guestRange'] = editReq['guestRange'];
          // Clear the edit request after applying
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(docId)
              .update({
            ...update,
            'editRequest': FieldValue.delete(),
          });
          await _loadBookings();
          return;
        }
      }
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update(update);
      await _loadBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: const Color(0xFF993C1D)),
        );
      }
    }
  }

  // ── Delete booking ──────────────────────────
  Future<void> _deleteBooking(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .delete();
      await _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deleted.'),
              backgroundColor: Color(0xFF993C1D)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: const Color(0xFF993C1D)),
        );
      }
    }
  }

  void _showBookingActions(Map<String, dynamic> booking) {
    final docId      = booking['id'] as String;
    final isPending  = (booking['status'] ?? '') == 'Pending Edit';
    final editReq    = booking['editRequest'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context:         context,
      backgroundColor: const Color(0xFFE8E3D8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text('Booking ${booking['bookingId'] ?? docId}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2416))),
            const SizedBox(height: 4),
            Text('${booking['name'] ?? ''} • ${booking['venueName'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8B7355))),

            // ── Show pending edit details if applicable ──
            if (isPending && editReq != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF5A623).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User Requested Changes:',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB87A00))),
                    const SizedBox(height: 4),
                    Text('New date: ${editReq['date'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF5C5040))),
                    Text('New time: ${editReq['timeSlot'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF5C5040))),
                    Text('New guests: ${editReq['guestRange'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF5C5040))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Approve edit (only if pending edit) ──
            if (isPending) ...[
              _ActionButton(
                icon:  Icons.check_circle_outline_rounded,
                label: 'Approve Edit Request',
                color: const Color(0xFF5C6B4A),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(docId, 'Confirmed');
                },
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon:  Icons.cancel_outlined,
                label: 'Reject Edit Request',
                color: const Color(0xFF8B7355),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(docId, 'Confirmed');
                  // Just revert to Confirmed without applying changes
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(docId)
                      .update({'editRequest': FieldValue.delete()});
                  await _loadBookings();
                },
              ),
            ] else ...[
              _ActionButton(
                icon:  Icons.check_circle_outline_rounded,
                label: 'Mark as Confirmed',
                color: const Color(0xFF5C6B4A),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(docId, 'Confirmed');
                },
              ),
            ],

            const SizedBox(height: 10),

            _ActionButton(
              icon:  Icons.delete_outline_rounded,
              label: 'Delete Booking',
              color: const Color(0xFF993C1D),
              onTap: () async {
                Navigator.pop(context);
                await _deleteBooking(docId);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [

        const SizedBox(height: 12),

        // ── Search bar ────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color:        const Color(0xFFEDE8E0),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFCCC5B8), width: 0.8),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(Icons.search, color: Color(0xFF8B7355), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF3B3228)),
                    decoration: const InputDecoration(
                      hintText:  'Search by name or venue...',
                      hintStyle: TextStyle(color: Color(0xFFADA99F)),
                      border:    InputBorder.none,
                      isDense:   true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _loadBookings,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.refresh,
                        color: Color(0xFF8B7355), size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Status filter ─────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['All', 'Confirmed', 'Pending Edit', 'Cancelled']
                .map((s) {
              final sel = _filterStatus == s;
              return GestureDetector(
                onTap: () => setState(() => _filterStatus = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF5C6B4A)
                        : const Color(0xFFDDD5C5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF5C6B4A)
                          : const Color(0xFFBFB8AA),
                    ),
                  ),
                  child: Text(s,
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : const Color(0xFF5C5040),
                      )),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // ── Booking list ──────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C6B4A)))
              : filtered.isEmpty
              ? const Center(
              child: Text('No bookings found.',
                  style: TextStyle(color: Color(0xFF8B7355))))
              : RefreshIndicator(
            onRefresh: _loadBookings,
            color: const Color(0xFF5C6B4A),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final b      = filtered[i];
                final status = b['status'] ?? '';
                return GestureDetector(
                  onTap: () => _showBookingActions(b),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:        const Color(0xFFDDD5C5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFBFB8AA),
                          width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b['name'] ?? '',
                                style: const TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.w700,
                                  color:      Color(0xFF2C2416),
                                )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status)
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(status,
                                  style: TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(status),
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${b['venueName'] ?? ''} • ${b['venueType'] == 'event_hall' ? 'Event Hall' : 'Conference Room'}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF5C5040)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${b['date'] ?? ''}  •  ${b['timeSlot'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8B7355)),
                            ),
                            Text(
                              'RM ${b['totalPrice'] ?? 0}',
                              style: const TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w700,
                                color:      Color(0xFF2C2416),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking ID: ${b['bookingId'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFADA99F)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon:  Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
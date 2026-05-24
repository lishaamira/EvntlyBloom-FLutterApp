import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_venue_screen.dart';
import 'user_payment_screen.dart';

//user_booking_screen.dart//

class UserBookingScreen extends StatefulWidget {
  final Venue venue;
  const UserBookingScreen({super.key, required this.venue});

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  DateTime? _selectedDate;
  String?   _selectedTimeSlot;
  String?   _selectedGuestRange;
  bool      _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ── Load logged-in user data from Firestore ──
  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _nameCtrl.text  = data['username'] ?? '';
            _phoneCtrl.text = data['phone']    ?? '';
            _emailCtrl.text = data['email']    ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  // ── Time slots per venue type ──────────────
  List<String> get _timeSlots {
    if (widget.venue.type == 'event_hall') {
      return [
        '8:00 AM – 1:00 PM',
        '2:00 PM – 7:00 PM',
        '6:00 PM – 11:00 PM',
      ];
    } else {
      return [
        '8:00 AM – 10:00 AM',
        '11:00 AM – 1:00 PM',
        '3:00 PM – 5:00 PM',
        '6:00 PM – 8:00 PM',
      ];
    }
  }

  // ── Guest ranges per venue capacity ────────
  List<String> get _guestRanges {
    final cap = widget.venue.capacity.toLowerCase();
    if (cap.contains('small')) {
      return widget.venue.type == 'conference_room'
          ? ['50 pax', '75 pax', '100 pax']
          : ['100 pax', '200 pax', '300 pax'];
    } else if (cap.contains('medium')) {
      return widget.venue.type == 'conference_room'
          ? ['200 pax', '300 pax', '350 pax']
          : ['400 pax', '500 pax', '600 pax'];
    } else {
      return widget.venue.type == 'conference_room'
          ? ['400 pax', '500 pax', '600 pax']
          : ['1,000 pax', '1,500 pax', '2,000 pax'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDate ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate:  DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   Color(0xFF5C6B4A),
            onPrimary: Colors.white,
            surface:   Color(0xFFE8E3D8),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _goToPayment() {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _selectedDate == null ||
        _selectedTimeSlot == null ||
        _selectedGuestRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Please fill in all required fields.'),
          backgroundColor: Color(0xFF5C6B4A),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserPaymentScreen(
          venue:      widget.venue,
          name:       _nameCtrl.text.trim(),
          phone:      _phoneCtrl.text.trim(),
          email:      _emailCtrl.text.trim(),
          date:       '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          timeSlot:   _selectedTimeSlot!,
          guestRange: _selectedGuestRange!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEventHall = widget.venue.type == 'event_hall';

    return Scaffold(
      backgroundColor: const Color(0xFFE8E3D8),
      body: SafeArea(
        child: Column(
          children: [

            // ── Header ─────────────────────────
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Text('EvntlyBloom',
                    style: TextStyle(
                      fontFamily:    'Georgia',
                      fontSize:      16,
                      fontWeight:    FontWeight.w600,
                      color:         Color(0xFF5C6B4A),
                      letterSpacing: 0.3,
                    )),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        size: 32, color: Color(0xFF2C2416)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Book ${widget.venue.name}',
                        style: const TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF2C2416),
                        ),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),

            // ── Loading indicator ──────────────
            if (_loadingUser)
              const LinearProgressIndicator(
                color:            Color(0xFF5C6B4A),
                backgroundColor:  Color(0xFFDDD5C5),
                minHeight:        2,
              ),

            // ── Scrollable form ────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Venue summary card ───────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFBFB8AA), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 70, height: 70,
                              child: Image.asset(
                                widget.venue.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFCCC5B8),
                                    child: const Icon(
                                        Icons.image_outlined,
                                        color: Color(0xFF8B7355),
                                        size: 28)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.venue.name,
                                    style: const TextStyle(
                                      fontSize:   15,
                                      fontWeight: FontWeight.w700,
                                      color:      Color(0xFF2C2416),
                                    )),
                                const SizedBox(height: 4),
                                Text(widget.venue.priceRange,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF5C5040))),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isEventHall
                                        ? const Color(0xFF5C6B4A)
                                        .withOpacity(0.12)
                                        : const Color(0xFF8B7355)
                                        .withOpacity(0.12),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isEventHall
                                        ? '🏛️  Event Hall'
                                        : '🏢  Conference Room',
                                    style: TextStyle(
                                      fontSize:   11,
                                      fontWeight: FontWeight.w600,
                                      color: isEventHall
                                          ? const Color(0xFF5C6B4A)
                                          : const Color(0xFF8B7355),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Full Name ─────────────────
                    const _FieldLabel(text: 'Full Name'),
                    const SizedBox(height: 8),
                    _InputField(
                        controller: _nameCtrl,
                        hint: 'Enter your full name'),

                    const SizedBox(height: 16),

                    // ── Phone ─────────────────────
                    const _FieldLabel(text: 'Phone Number'),
                    const SizedBox(height: 8),
                    _InputField(
                        controller:   _phoneCtrl,
                        hint:         'e.g. 0123456789',
                        keyboardType: TextInputType.phone),

                    const SizedBox(height: 16),

                    // ── Email ─────────────────────
                    const _FieldLabel(text: 'Email'),
                    const SizedBox(height: 8),
                    _InputField(
                        controller:   _emailCtrl,
                        hint:         'e.g. you@email.com',
                        keyboardType: TextInputType.emailAddress),

                    const SizedBox(height: 16),

                    // ── Date ─────────────────────
                    const _FieldLabel(text: 'Event Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color:        const Color(0xFFEDE8E0),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: const Color(0xFFCCC5B8),
                              width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: Color(0xFF5C6B4A)),
                            const SizedBox(width: 10),
                            Text(
                              _selectedDate == null
                                  ? 'Select a date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDate == null
                                    ? const Color(0xFFADA99F)
                                    : const Color(0xFF3B3228),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Time slots ────────────────
                    const _FieldLabel(text: 'Time Slot'),
                    const SizedBox(height: 4),
                    Text(
                      isEventHall
                          ? '5 hours per slot — select one.'
                          : '2 hours per slot — select one.',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8B7355)),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: _timeSlots.map((slot) {
                        final sel = _selectedTimeSlot == slot;
                        return GestureDetector(
                          onTap: () => setState(() =>
                          _selectedTimeSlot = sel ? null : slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width:  double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 13),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF5C6B4A)
                                  : const Color(0xFFEDE8E0),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF5C6B4A)
                                    : const Color(0xFFCCC5B8),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sel
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  size:  18,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF8B7355),
                                ),
                                const SizedBox(width: 10),
                                Text(slot,
                                    style: TextStyle(
                                      fontSize:   14,
                                      fontWeight: FontWeight.w500,
                                      color: sel
                                          ? Colors.white
                                          : const Color(0xFF3B3228),
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // ── Guest range ───────────────
                    const _FieldLabel(text: 'Number of Guests'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _guestRanges.map((range) {
                        final sel = _selectedGuestRange == range;
                        return GestureDetector(
                          onTap: () => setState(() =>
                          _selectedGuestRange =
                          sel ? null : range),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF5C6B4A)
                                  : const Color(0xFFEDE8E0),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF5C6B4A)
                                    : const Color(0xFFCCC5B8),
                                width: 0.8,
                              ),
                            ),
                            child: Text(range,
                                style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w500,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF3B3228),
                                )),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Fixed Next button ──────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _goToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C6B4A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Next — Review & Pay',
                style: TextStyle(
                  fontFamily:  'Georgia',
                  fontSize:    16,
                  fontWeight:  FontWeight.w600,
                )),
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
          fontWeight: FontWeight.w600,
          color:      Color(0xFF3B3228),
        ));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final TextInputType         keyboardType;
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        const Color(0xFFEDE8E0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: const Color(0xFFCCC5B8), width: 0.8),
      ),
      child: TextField(
        controller:   controller,
        keyboardType: keyboardType,
        style: const TextStyle(
            fontSize: 14, color: Color(0xFF3B3228)),
        decoration: InputDecoration(
          hintText:       hint,
          hintStyle:      const TextStyle(
              color: Color(0xFFADA99F)),
          border:         InputBorder.none,
          isDense:        true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}
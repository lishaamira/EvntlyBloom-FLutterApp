import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_venue_screen.dart';
import 'main_screen.dart';

//user_payment_screen.dart//

class _AddOnItem {
  final String   name;
  final int      price;
  final IconData icon;
  bool           selected;

  _AddOnItem({
    required this.name,
    required this.price,
    required this.icon,
    this.selected = false,
  });
}

class UserPaymentScreen extends StatefulWidget {
  final Venue  venue;
  final String name;
  final String phone;
  final String email;
  final String date;
  final String timeSlot;
  final String guestRange;

  const UserPaymentScreen({
    super.key,
    required this.venue,
    required this.name,
    required this.phone,
    required this.email,
    required this.date,
    required this.timeSlot,
    required this.guestRange,
  });

  @override
  State<UserPaymentScreen> createState() => _UserPaymentScreenState();
}

class _UserPaymentScreenState extends State<UserPaymentScreen> {

  late final List<_AddOnItem> _addOns;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.venue.type == 'event_hall') {
      _addOns = [
        _AddOnItem(name: 'Videographer',       price: 800,  icon: Icons.videocam_outlined),
        _AddOnItem(name: 'Photography',        price: 600,  icon: Icons.camera_alt_outlined),
        _AddOnItem(name: 'Extra Sound System', price: 400,  icon: Icons.speaker_outlined),
        _AddOnItem(name: 'Live Band',          price: 1500, icon: Icons.music_note_outlined),
        _AddOnItem(name: 'Flower Decoration',  price: 350,  icon: Icons.local_florist_outlined),
        _AddOnItem(name: 'LED Backdrop',       price: 500,  icon: Icons.tv_outlined),
        _AddOnItem(name: 'Emcee / Host',       price: 300,  icon: Icons.mic_outlined),
        _AddOnItem(name: 'Photo Booth',        price: 450,  icon: Icons.photo_camera_outlined),
      ];
    } else {
      _addOns = [
        _AddOnItem(name: 'AV Equipment Setup',      price: 300,  icon: Icons.settings_input_hdmi_outlined),
        _AddOnItem(name: 'Video Conferencing',       price: 400,  icon: Icons.video_call_outlined),
        _AddOnItem(name: 'Catering (Lunch)',         price: 600,  icon: Icons.lunch_dining_outlined),
        _AddOnItem(name: 'Catering (Refreshments)',  price: 250,  icon: Icons.coffee_outlined),
        _AddOnItem(name: 'Whiteboard & Stationery',  price: 100,  icon: Icons.edit_outlined),
        _AddOnItem(name: 'Simultaneous Translation', price: 800,  icon: Icons.translate_outlined),
        _AddOnItem(name: 'Recording Service',        price: 500,  icon: Icons.fiber_manual_record_outlined),
        _AddOnItem(name: 'Event Photographer',       price: 600,  icon: Icons.camera_alt_outlined),
      ];
    }
  }

  String _selectedPayment = 'Online Banking';
  final List<String> _paymentMethods = [
    'Online Banking',
    'Credit / Debit Card',
    'E-Wallet (Touch\'n Go)',
  ];

  double get _basePrice   => widget.venue.minPrice.toDouble();
  double get _addOnsTotal => _addOns
      .where((a) => a.selected)
      .fold(0.0, (sum, a) => sum + a.price);
  double get _totalPrice  => _basePrice + _addOnsTotal;

  // ── Price formatter ───────────────────────
  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }

  // ── Save booking to Firestore ──────────────
  Future<void> _confirmPayment() async {
    setState(() => _isSaving = true);

    try {
      final user      = FirebaseAuth.instance.currentUser;
      final bookingId =
          'EB${DateTime.now().millisecondsSinceEpoch % 900000000 + 100000000}';
      final selectedAddOnNames = _addOns
          .where((a) => a.selected)
          .map((a) => a.name)
          .toList();

      await FirebaseFirestore.instance.collection('bookings').add({
        'bookingId':  bookingId,
        'userId':     user?.uid ?? '',
        'imagePath':  widget.venue.imagePath,
        'name':       widget.name,
        'phone':      widget.phone,
        'email':      widget.email,
        'venueId':    widget.venue.id,
        'venueName':  widget.venue.name,
        'venueType':  widget.venue.type,
        'date':       widget.date,
        'timeSlot':   widget.timeSlot,
        'guestRange': widget.guestRange,
        'addOns':     selectedAddOnNames,
        'totalPrice': _totalPrice,
        'payment':    _selectedPayment,
        'status':     'Confirmed',
        'createdAt':  FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSuccessDialog(bookingId);

    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Failed to save booking: $e'),
          backgroundColor: const Color(0xFF993C1D),
        ),
      );
    }
  }

  void _showSuccessDialog(String bookingId) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFE8E3D8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF5C6B4A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF2C2416),
                )),
            const SizedBox(height: 8),
            Text('Booking ID: $bookingId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize:   13,
                  color:      Color(0xFF5C6B4A),
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Text(
              'Your booking for ${widget.venue.name} on ${widget.date} is confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color:    Color(0xFF5C5040),
                height:   1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        const Color(0xFFDDD5C5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Total Paid',
                      style: TextStyle(
                        fontSize: 12,
                        color:    Color(0xFF8B7355),
                      )),
                  const SizedBox(height: 4),
                  // ── FIXED ──
                  Text('RM ${_formatPrice(_totalPrice)}',
                      style: const TextStyle(
                        fontSize:   20,
                        fontWeight: FontWeight.w800,
                        color:      Color(0xFF2C2416),
                      )),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                      const MainScreen(initialIndex: 2)),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6B4A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('View My Bookings',
                  style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Payment',
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF2C2416),
                      )),
                ],
              ),
            ),

            if (_isSaving)
              const LinearProgressIndicator(
                color:           Color(0xFF5C6B4A),
                backgroundColor: Color(0xFFDDD5C5),
                minHeight:       2,
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Booking summary ───────────
                    const _SectionTitle(text: 'Booking Summary'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFBFB8AA),
                            width: 0.5),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Venue',
                              value: widget.venue.name),
                          _SummaryRow(label: 'Name',
                              value: widget.name),
                          _SummaryRow(label: 'Phone',
                              value: widget.phone),
                          _SummaryRow(label: 'Date',
                              value: widget.date),
                          _SummaryRow(label: 'Time',
                              value: widget.timeSlot),
                          _SummaryRow(label: 'Guests',
                              value: widget.guestRange),
                          // ── FIXED ──
                          _SummaryRow(
                            label:      'Base Price',
                            value:      'RM ${_formatPrice(_basePrice)}',
                            valueColor: const Color(0xFF5C6B4A),
                            isBold:     true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Add-ons ───────────────────
                    const _SectionTitle(text: 'Add-ons'),
                    const SizedBox(height: 4),
                    Text(
                      widget.venue.type == 'event_hall'
                          ? 'Enhance your event with these extras.'
                          : 'Equip your conference with professional services.',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8B7355)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color:        const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFBFB8AA),
                            width: 0.5),
                      ),
                      child: Column(
                        children: List.generate(_addOns.length, (i) {
                          final addon  = _addOns[i];
                          final isLast = i == _addOns.length - 1;
                          return Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.vertical(
                                  top: i == 0
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                  bottom: isLast
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                ),
                                onTap: () => setState(() =>
                                addon.selected = !addon.selected),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 13),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: addon.selected
                                              ? const Color(0xFF5C6B4A)
                                              : Colors.transparent,
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          border: Border.all(
                                            color: addon.selected
                                                ? const Color(0xFF5C6B4A)
                                                : const Color(0xFFBFB8AA),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: addon.selected
                                            ? const Icon(Icons.check,
                                            size:  14,
                                            color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(addon.icon,
                                          size:  18,
                                          color: addon.selected
                                              ? const Color(0xFF5C6B4A)
                                              : const Color(0xFF8B7355)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(addon.name,
                                            style: TextStyle(
                                              fontSize:   13,
                                              fontWeight: addon.selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: addon.selected
                                                  ? const Color(0xFF2C2416)
                                                  : const Color(0xFF3B3228),
                                            )),
                                      ),
                                      Text(
                                        '+ RM ${addon.price}',
                                        style: TextStyle(
                                          fontSize:   12,
                                          fontWeight: FontWeight.w600,
                                          color: addon.selected
                                              ? const Color(0xFF5C6B4A)
                                              : const Color(0xFF8B7355),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                    height: 1,
                                    color:  Color(0xFFCCC5B8),
                                    indent: 16, endIndent: 16),
                            ],
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Price breakdown ───────────
                    const _SectionTitle(text: 'Price Breakdown'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFBFB8AA),
                            width: 0.5),
                      ),
                      child: Column(
                        children: [
                          // ── FIXED ──
                          _PriceRow(
                            label:  'Base price',
                            amount: 'RM ${_formatPrice(_basePrice)}',
                          ),
                          ..._addOns
                              .where((a) => a.selected)
                              .map((a) => _PriceRow(
                            label:   a.name,
                            amount:  '+ RM ${a.price}',
                            isAddOn: true,
                          )),
                          const SizedBox(height: 8),
                          const Divider(
                              color: Color(0xFFBFB8AA), height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                    fontSize:   16,
                                    fontWeight: FontWeight.w700,
                                    color:      Color(0xFF2C2416),
                                  )),
                              AnimatedSwitcher(
                                duration: const Duration(
                                    milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                        opacity: anim, child: child),
                                // ── FIXED ──
                                child: Text(
                                  'RM ${_formatPrice(_totalPrice)}',
                                  key: ValueKey(_totalPrice),
                                  style: const TextStyle(
                                    fontSize:   18,
                                    fontWeight: FontWeight.w800,
                                    color:      Color(0xFF5C6B4A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Payment method ────────────
                    const _SectionTitle(text: 'Payment Method'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color:        const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFBFB8AA),
                            width: 0.5),
                      ),
                      child: Column(
                        children: List.generate(
                            _paymentMethods.length, (i) {
                          final method = _paymentMethods[i];
                          final sel    = method == _selectedPayment;
                          final isLast =
                              i == _paymentMethods.length - 1;
                          return Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.vertical(
                                  top: i == 0
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                  bottom: isLast
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                ),
                                onTap: () => setState(
                                        () => _selectedPayment = method),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        sel
                                            ? Icons.radio_button_checked
                                            : Icons
                                            .radio_button_unchecked,
                                        size:  20,
                                        color: sel
                                            ? const Color(0xFF5C6B4A)
                                            : const Color(0xFFBFB8AA),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(method,
                                          style: TextStyle(
                                            fontSize:   14,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: sel
                                                ? const Color(0xFF2C2416)
                                                : const Color(0xFF5C5040),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                    height: 1,
                                    color:  Color(0xFFCCC5B8),
                                    indent: 16, endIndent: 16),
                            ],
                          );
                        }),
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

      // ── Fixed bottom bar ───────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFE8E3D8),
          border: Border(
              top: BorderSide(
                  color: Color(0xFFCCC5B8), width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total to pay:',
                    style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      Color(0xFF2C2416),
                    )),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  // ── FIXED ──
                  child: Text(
                    'RM ${_formatPrice(_totalPrice)}',
                    key: ValueKey(_totalPrice),
                    style: const TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.w800,
                      color:      Color(0xFF5C6B4A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width:  double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6B4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _isSaving
                    ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       Colors.white,
                    ))
                    : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    // ── FIXED ──
                    'Confirm & Pay  RM ${_formatPrice(_totalPrice)}',
                    key: ValueKey(_totalPrice),
                    style: const TextStyle(
                      fontFamily:  'Georgia',
                      fontSize:    16,
                      fontWeight:  FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section title ────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize:   15,
          fontWeight: FontWeight.w700,
          color:      Color(0xFF2C2416),
        ));
  }
}

// ─── Summary row ──────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool   isBold;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color:    Color(0xFF8B7355)))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: isBold
                      ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? const Color(0xFF2C2416),
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Price row ────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool   isAddOn;
  const _PriceRow({
    required this.label,
    required this.amount,
    this.isAddOn = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: isAddOn
                    ? const Color(0xFF5C6B4A)
                    : const Color(0xFF3B3228),
              )),
          Text(amount,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color: isAddOn
                    ? const Color(0xFF5C6B4A)
                    : const Color(0xFF2C2416),
              )),
        ],
      ),
    );
  }
}
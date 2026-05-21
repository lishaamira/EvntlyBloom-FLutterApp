import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/user_venue_screen.dart';

// admin_venues_screen.dart//

const _hallImages = [
  'assets/images/hall1.png',
  'assets/images/hall2.png',
  'assets/images/hall3.png',
  'assets/images/hall4.jpg',
  'assets/images/hall5.jpeg',
];

const _confImages = [
  'assets/images/conf1.jpg',
  'assets/images/conf2.jpg',
  'assets/images/conf3.jpg',
  'assets/images/conf4.png',
  'assets/images/conf5.png',
];

const _hallAmenityPresets = [
  'Stage', 'Sound System', 'Air Conditioning',
  'Parking', 'Catering', 'Lighting', 'Prep Room',
  'Projector', 'Wi-Fi', 'Dressing Room', 'LED Backdrop',
  'Photo Booth', 'Flower Decoration',
];

const _confAmenityPresets = [
  'Projector', 'Wi-Fi', 'Whiteboard', 'Air Conditioning',
  'AV System', 'Video Conferencing', 'Parking',
  'Printing Service', 'Coffee & Tea', 'Sound System',
];

class AdminVenuesScreen extends StatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  State<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen> {
  int  _selectedTab = 0;
  bool _isLoading   = true;

  List<Venue> _halls = [];
  List<Venue> _rooms = [];

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final snap = await _firestore.collection('venues').get();
      final all  = snap.docs
          .map((d) => Venue.fromFirestore(d))
          .toList();
      if (mounted) {
        setState(() {
          _halls     = all.where((v) => v.type == 'event_hall').toList();
          _rooms     = all.where((v) => v.type == 'conference_room').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading venues: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Venue> get _currentList =>
      _selectedTab == 0 ? _halls : _rooms;

  // ── Delete ─────────────────────────────────
  void _deleteVenue(Venue venue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFE8E3D8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Venue',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF2C2416),
            )),
        content: Text(
            'Are you sure you want to delete "${venue.name}"?',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF5C5040))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF8B7355)))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _firestore
                      .collection('venues')
                      .doc(venue.id)
                      .delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Venue deleted.'),
                            backgroundColor: Color(0xFF993C1D)));
                    _loadVenues();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'),
                            backgroundColor:
                            const Color(0xFF993C1D)));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF993C1D),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Delete')),
        ],
      ),
    );
  }

  // ── Add / Edit ─────────────────────────────
  void _showAddEditDialog({Venue? venue}) {
    final nameCtrl     = TextEditingController(text: venue?.name ?? '');
    final priceCtrl    = TextEditingController(text: venue?.priceRange ?? '');
    final capCtrl      = TextEditingController(text: venue?.capacity ?? '');
    final descCtrl     = TextEditingController(text: venue?.description ?? '');
    final bestCtrl     = TextEditingController(text: venue?.bestFor ?? '');
    final unitCtrl     = TextEditingController(text: venue?.bookingUnit ?? '');
    final amenityCtrl  = TextEditingController();
    final minPriceCtrl = TextEditingController(
        text: venue?.minPrice != null && venue!.minPrice > 0
            ? venue.minPrice.toString() : '');
    final maxPriceCtrl = TextEditingController(
        text: venue?.maxPrice != null && venue!.maxPrice > 0
            ? venue.maxPrice.toString() : '');

    final isEdit    = venue != null;
    final imageList = _selectedTab == 0 ? _hallImages : _confImages;
    final presets   = _selectedTab == 0
        ? _hallAmenityPresets : _confAmenityPresets;

    String       selectedImage = venue?.imagePath.isNotEmpty == true
        ? venue!.imagePath : imageList[0];
    List<String> amenities     = List.from(venue?.amenities ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: const Color(0xFFE8E3D8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Edit Venue' : 'Add New Venue',
              style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF2C2416),
              )),

          content: SizedBox(
            width:  double.maxFinite,
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Image selector ───────────
                  const Text('Venue Image',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      Color(0xFF3B3228),
                      )),
                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      selectedImage,
                      height: 130,
                      width:  double.infinity,
                      fit:    BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 130,
                        color:  const Color(0xFFCCC5B8),
                        child:  const Center(
                          child: Icon(Icons.image_outlined,
                              color: Color(0xFF8B7355), size: 36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageList.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final img = imageList[i];
                        final sel = selectedImage == img;
                        return GestureDetector(
                          onTap: () =>
                              ss(() => selectedImage = img),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(8),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF5C6B4A)
                                    : const Color(0xFFCCC5B8),
                                width: sel ? 2.5 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(7),
                              child: Image.asset(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                      color: const Color(0xFFCCC5B8),
                                      child: const Icon(
                                          Icons.image_outlined,
                                          size:  20,
                                          color: Color(0xFF8B7355)),
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Basic fields ─────────────
                  _DialogField(
                      label: 'Venue Name',
                      ctrl:  nameCtrl,
                      hint:  'e.g. Sunflower Hall'),
                  const SizedBox(height: 12),
                  _DialogField(
                      label: 'Price Range',
                      ctrl:  priceCtrl,
                      hint:  'e.g. RM 2,000 - RM 3,000'),
                  const SizedBox(height: 4),
                  const Text(
                    'Display label shown to users.',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF8B7355)),
                  ),
                  const SizedBox(height: 12),

                  // ── Min / Max Price ──────────
                  Row(
                    children: [
                      Expanded(
                        child: _DialogField(
                          label:        'Min Price (RM)',
                          ctrl:         minPriceCtrl,
                          hint:         'e.g. 2000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogField(
                          label:        'Max Price (RM)',
                          ctrl:         maxPriceCtrl,
                          hint:         'e.g. 3000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Min price is used as base price during booking.',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF8B7355)),
                  ),
                  const SizedBox(height: 12),

                  _DialogField(
                      label: 'Capacity',
                      ctrl:  capCtrl,
                      hint:  'e.g. Small (200 - 300 pax)'),
                  const SizedBox(height: 12),
                  _DialogField(
                      label: 'Booking Unit',
                      ctrl:  unitCtrl,
                      hint:  'e.g. Full day / Per 2 hours'),
                  const SizedBox(height: 12),
                  _DialogField(
                      label: 'Best For',
                      ctrl:  bestCtrl,
                      hint:  'e.g. Weddings, Galas'),
                  const SizedBox(height: 12),
                  _DialogField(
                      label:    'Description',
                      ctrl:     descCtrl,
                      hint:     'Enter venue description...',
                      maxLines: 6),

                  const SizedBox(height: 16),

                  // ── Amenities ────────────────
                  const Text('Amenities',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      Color(0xFF3B3228),
                      )),
                  const SizedBox(height: 4),
                  const Text(
                      'Tap presets to select, or add custom:',
                      style: TextStyle(
                        fontSize: 11,
                        color:    Color(0xFF8B7355),
                      )),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: presets.map((a) {
                      final selected = amenities.contains(a);
                      return GestureDetector(
                        onTap: () => ss(() {
                          if (selected) {
                            amenities.remove(a);
                          } else {
                            amenities.add(a);
                          }
                        }),
                        child: AnimatedContainer(
                          duration:
                          const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF5C6B4A)
                                : const Color(0xFFDDD5C5),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF5C6B4A)
                                  : const Color(0xFFBFB8AA),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.check,
                                      size:  12,
                                      color: Colors.white),
                                ),
                              Text(a,
                                  style: TextStyle(
                                    fontSize:   12,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF3B3228),
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  const Text('Add custom amenity:',
                      style: TextStyle(
                        fontSize: 11,
                        color:    Color(0xFF8B7355),
                      )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amenityCtrl,
                          style: const TextStyle(
                              fontSize: 13,
                              color:    Color(0xFF3B3228)),
                          decoration: InputDecoration(
                            hintText:  'e.g. Valet Parking...',
                            hintStyle: const TextStyle(
                                color:    Color(0xFFADA99F),
                                fontSize: 12),
                            filled:    true,
                            fillColor: const Color(0xFFEDE8E0),
                            border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFCCC5B8),
                                    width: 0.8)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFCCC5B8),
                                    width: 0.8)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF5C6B4A),
                                    width: 1.5)),
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final val = amenityCtrl.text.trim();
                          if (val.isNotEmpty &&
                              !amenities.contains(val)) {
                            ss(() {
                              amenities.add(val);
                              amenityCtrl.clear();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C6B4A),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),

                  Builder(builder: (_) {
                    final customs = amenities
                        .where((a) => !presets.contains(a))
                        .toList();
                    if (customs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text('Custom amenities:',
                            style: TextStyle(
                              fontSize: 11,
                              color:    Color(0xFF8B7355),
                            )),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: customs.map((a) {
                            return Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical:   5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8FBA72),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(a,
                                      style: const TextStyle(
                                        fontSize:   12,
                                        color:      Colors.white,
                                        fontWeight: FontWeight.w500,
                                      )),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => ss(() =>
                                        amenities.remove(a)),
                                    child: const Icon(
                                        Icons.close,
                                        size:  14,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF8B7355)))),
            ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a venue name.'),
                        backgroundColor: Color(0xFF993C1D),
                      ),
                    );
                    return;
                  }

                  final minP = int.tryParse(
                      minPriceCtrl.text.trim().replaceAll(',', '')) ?? 0;
                  final maxP = int.tryParse(
                      maxPriceCtrl.text.trim().replaceAll(',', '')) ?? 0;

                  final type = _selectedTab == 0
                      ? 'event_hall' : 'conference_room';

                  final data = {
                    'name':        nameCtrl.text.trim(),
                    'priceRange':  priceCtrl.text.trim(),
                    'capacity':    capCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'bestFor':     bestCtrl.text.trim(),
                    'bookingUnit': unitCtrl.text.trim().isEmpty
                        ? (_selectedTab == 0
                        ? 'Full day' : 'Per 2 hours')
                        : unitCtrl.text.trim(),
                    'type':        type,
                    'pricing':     priceCtrl.text.trim(),
                    'imagePath':   selectedImage,
                    'amenities':   amenities,
                    'minPrice':    minP,
                    'maxPrice':    maxP,
                  };

                  Navigator.pop(ctx);

                  try {
                    if (isEdit) {
                      await _firestore
                          .collection('venues')
                          .doc(venue!.id)
                          .update(data);
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text('Venue updated!'),
                            backgroundColor:
                            Color(0xFF5C6B4A)));
                      }
                    } else {
                      await _firestore
                          .collection('venues')
                          .add(data);
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text('Venue added!'),
                            backgroundColor:
                            Color(0xFF5C6B4A)));
                      }
                    }
                    _loadVenues();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                          content: Text('Error: $e'),
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
                child: Text(
                    isEdit ? 'Save Changes' : 'Add Venue')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venues = _currentList;

    return Stack(
      children: [
        Column(
          children: [

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _TabPill(
                    label:      'Event Halls',
                    isSelected: _selectedTab == 0,
                    onTap: () =>
                        setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    label:      'Conference Rooms',
                    isSelected: _selectedTab == 1,
                    onTap: () =>
                        setState(() => _selectedTab = 1),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadVenues,
                    child: const Icon(Icons.refresh,
                        color: Color(0xFF8B7355), size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${venues.length} venue${venues.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize:   12,
                  color:      Color(0xFF8B7355),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF5C6B4A)))
                  : venues.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                        Icons.location_city_outlined,
                        color: Color(0xFF8B7355),
                        size: 48),
                    const SizedBox(height: 8),
                    const Text('No venues yet.',
                        style: TextStyle(
                            color: Color(0xFF8B7355))),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddEditDialog(),
                      icon: const Icon(Icons.add,
                          size: 18),
                      label: const Text(
                          'Add First Venue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF5C6B4A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                20)),
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadVenues,
                color: const Color(0xFF5C6B4A),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 100),
                  itemCount: venues.length,
                  itemBuilder: (_, i) {
                    final v = venues[i];
                    return Container(
                      margin: const EdgeInsets.only(
                          bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDD5C5),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color:
                            const Color(0xFFBFB8AA),
                            width: 0.5),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                            const BorderRadius
                                .horizontal(
                                left: Radius.circular(
                                    14)),
                            child: SizedBox(
                              width:  80,
                              height: 90,
                              child: Image.asset(
                                v.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                      color: const Color(
                                          0xFFCCC5B8),
                                      child: const Icon(
                                          Icons
                                              .image_outlined,
                                          color: Color(
                                              0xFF8B7355),
                                          size: 28),
                                    ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(v.name,
                                      style: const TextStyle(
                                        fontSize:   14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C2416),
                                      )),
                                  const SizedBox(height: 2),
                                  Text(v.priceRange,
                                      style: const TextStyle(
                                        fontSize:   12,
                                        color: Color(0xFF5C5040),
                                      )),
                                  const SizedBox(height: 2),
                                  Text(
                                    'RM ${v.minPrice} – RM ${v.maxPrice}',
                                    style: const TextStyle(
                                      fontSize:   11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5C6B4A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(v.capacity,
                                      style: const TextStyle(
                                        fontSize:   11,
                                        color: Color(0xFF8B7355),
                                      )),
                                  const SizedBox(height: 2),
                                  if (v.amenities.isNotEmpty)
                                    Text(
                                      v.amenities.take(3).join(', ') +
                                          (v.amenities.length > 3
                                              ? '...' : ''),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5C6B4A),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _showAddEditDialog(venue: v),
                                icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF5C6B4A),
                                    size: 20),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () =>
                                    _deleteVenue(v),
                                icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFF993C1D),
                                    size: 20),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        Positioned(
          bottom: 24, right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddEditDialog(),
            backgroundColor: const Color(0xFF5C6B4A),
            foregroundColor: Colors.white,
            elevation: 2,
            icon:  const Icon(Icons.add),
            label: const Text('Add Venue',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   14)),
          ),
        ),
      ],
    );
  }
}

// ─── Tab Pill ──────────────────────────────────
class _TabPill extends StatelessWidget {
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5C6B4A)
              : const Color(0xFFE8E3D8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5C6B4A)
                : const Color(0xFFBFB8AA),
            width: 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize:   13,
              fontWeight: isSelected
                  ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF7A7060),
            )),
      ),
    );
  }
}

// ─── Dialog Field ──────────────────────────────
class _DialogField extends StatelessWidget {
  final String                    label;
  final TextEditingController     ctrl;
  final String?                   hint;
  final int                       maxLines;
  final TextInputType             keyboardType;
  final List<TextInputFormatter>  inputFormatters;

  const _DialogField({
    required this.label,
    required this.ctrl,
    this.hint,
    this.maxLines       = 1,
    this.keyboardType   = TextInputType.text,
    this.inputFormatters = const [],
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
          controller:      ctrl,
          maxLines:        maxLines,
          keyboardType:    keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF3B3228)),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(
                color: Color(0xFFADA99F), fontSize: 12),
            filled:    true,
            fillColor: const Color(0xFFEDE8E0),
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
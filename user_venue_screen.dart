import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_venue_detail_screen.dart';

// ── Venue model ───────────────────────────────
class Venue {
  final String       id;
  final String       name;
  final String       priceRange;
  final String       type;
  final String       imagePath;
  final String       description;
  final String       capacity;
  final String       pricing;
  final String       bookingUnit;
  final String       bestFor;
  final List<String> amenities;
  final int          minPrice;
  final int          maxPrice;

  const Venue({
    required this.id,
    required this.name,
    required this.priceRange,
    required this.type,
    required this.imagePath,
    required this.description,
    required this.capacity,
    required this.pricing,
    required this.bookingUnit,
    required this.bestFor,
    required this.amenities,
    required this.minPrice,
    required this.maxPrice,
  });

  // ── Create Venue from Firestore document ──
  factory Venue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // ── Safely parse minPrice / maxPrice ──────
    // Handles both int and string stored in Firestore
    int parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) {
        return int.tryParse(
            val.replaceAll(',', '').replaceAll('RM', '').trim()) ??
            0;
      }
      return 0;
    }

    // ── If minPrice is 0, try to parse from priceRange ──
    // e.g. "RM 4,000 - RM 6,000" → minPrice = 4000
    int parsedMin = parsePrice(data['minPrice']);
    int parsedMax = parsePrice(data['maxPrice']);

    if (parsedMin == 0) {
      final priceStr = (data['priceRange'] ?? '').toString();
      final matches  = RegExp(r'\d[\d,]*').allMatches(priceStr);
      final prices   = matches
          .map((m) =>
      int.tryParse(m.group(0)!.replaceAll(',', '')) ?? 0)
          .where((n) => n >= 100)
          .toList();
      if (prices.isNotEmpty) parsedMin = prices[0];
      if (prices.length > 1) parsedMax = prices[1];
    }

    return Venue(
      id:          doc.id,
      name:        data['name']        ?? '',
      priceRange:  data['priceRange']  ?? '',
      type:        data['type']        ?? 'event_hall',
      imagePath:   data['imagePath']   ?? 'assets/images/hall1.png',
      description: data['description'] ?? '',
      capacity:    data['capacity']    ?? '',
      pricing:     data['pricing']     ?? data['priceRange'] ?? '',
      bookingUnit: data['bookingUnit'] ?? 'Full day',
      bestFor:     data['bestFor']     ?? '',
      amenities: List<String>.from(data['amenities'] ?? []),
      minPrice:    ((data['minPrice'] ?? 0) as num).toInt(),
      maxPrice:    ((data['maxPrice'] ?? 0) as num).toInt(),
    );
  }

  // ── Convert to Map for Firestore ──────────
  Map<String, dynamic> toMap() => {
    'name':        name,
    'priceRange':  priceRange,
    'type':        type,
    'imagePath':   imagePath,
    'description': description,
    'capacity':    capacity,
    'pricing':     pricing,
    'bookingUnit': bookingUnit,
    'bestFor':     bestFor,
    'amenities':   amenities,
    'minPrice':    minPrice,
    'maxPrice':    maxPrice,
  };
}

// ── Sample local data (fallback if Firestore empty) ──
final List<Venue> eventHalls = [
  Venue(
    id: 'hall1', name: 'Sunflower Hall',
    priceRange: 'RM 2,000 - RM 3,000', type: 'event_hall',
    imagePath: 'assets/images/hall1.png',
    capacity: 'Small (200 - 300 pax)', pricing: 'RM 2,000 - RM 3,000',
    bookingUnit: 'Full day', bestFor: 'Weddings, Prom Dinner',
    minPrice: 2000, maxPrice: 3000,
    description: 'Our event halls are grand, fully equipped spaces built to host your most memorable occasions.',
    amenities: ['Stage', 'Sound System', 'Air Conditioning', 'Parking', 'Catering', 'Lighting', 'Prep Room'],
  ),
  Venue(
    id: 'hall2', name: 'Baby Breath Hall',
    priceRange: 'RM 5,000 - RM 6,000', type: 'event_hall',
    imagePath: 'assets/images/hall2.png',
    capacity: 'Medium (400-600 pax)', pricing: 'RM 5,000 - RM 6,000',
    bookingUnit: 'Full day', bestFor: 'Weddings, Prom Dinner',
    minPrice: 5000, maxPrice: 6000,
    description: 'Our event halls are grand, fully equipped spaces built to host your most memorable occasions.',
    amenities: ['Stage', 'Sound System', 'Air Conditioning', 'Parking', 'Catering', 'Lighting', 'Prep Room'],
  ),
  Venue(
    id: 'hall3', name: 'Rose Hall',
    priceRange: 'RM 8,000 - RM 10,000', type: 'event_hall',
    imagePath: 'assets/images/hall3.png',
    capacity: 'Large (1,000 - 2,000 pax)', pricing: 'RM 8,000 - RM 10,000',
    bookingUnit: 'Full day', bestFor: 'Weddings, Galas, Concerts',
    minPrice: 8000, maxPrice: 10000,
    description: 'Our event halls are grand, fully equipped spaces built to host your most memorable occasions.',
    amenities: ['Stage', 'Sound System', 'Air Conditioning', 'Parking', 'Catering', 'Lighting', 'Prep Room'],
  ),
];

final List<Venue> conferenceRooms = [
  Venue(
    id: 'conf1', name: 'Cucumber Room',
    priceRange: 'RM 1,000 - RM 1,500', type: 'conference_room',
    imagePath: 'assets/images/conf1.jpg',
    capacity: 'Small (50 - 100 pax)', pricing: 'RM 1,000 - RM 1,500',
    bookingUnit: 'Per 2 hours', bestFor: 'Meetings, Seminars',
    minPrice: 1000, maxPrice: 1500,
    description: 'Our conference rooms offer a focused and productive environment for your professional needs.',
    amenities: ['Projector', 'Wi-Fi', 'Whiteboard', 'Air Conditioning', 'AV System', 'Video Conferencing'],
  ),
  Venue(
    id: 'conf2', name: 'Apple Room',
    priceRange: 'RM 2,000 - RM 2,500', type: 'conference_room',
    imagePath: 'assets/images/conf2.jpg',
    capacity: 'Medium (300 - 350 pax)', pricing: 'RM 2,000 - RM 2,500',
    bookingUnit: 'Per 2 hours', bestFor: 'Meetings, Training',
    minPrice: 2000, maxPrice: 2500,
    description: 'Our conference rooms offer a focused and productive environment for your professional needs.',
    amenities: ['Projector', 'Wi-Fi', 'Whiteboard', 'Air Conditioning', 'AV System', 'Video Conferencing'],
  ),
  Venue(
    id: 'conf3', name: 'Lemon Room',
    priceRange: 'RM 4,000 - RM 4,500', type: 'conference_room',
    imagePath: 'assets/images/conf3.jpg',
    capacity: 'Large (500 - 600 pax)', pricing: 'RM 4,000 - RM 4,500',
    bookingUnit: 'Per 2 hours', bestFor: 'Large Conferences',
    minPrice: 4000, maxPrice: 4500,
    description: 'Our conference rooms offer a focused and productive environment for your professional needs.',
    amenities: ['Projector', 'Wi-Fi', 'Whiteboard', 'Air Conditioning', 'AV System', 'Video Conferencing'],
  ),
];

// ─────────────────────────────────────────────
class UserVenueScreen extends StatefulWidget {
  final int initialTab;
  const UserVenueScreen({super.key, this.initialTab = 0});

  @override
  State<UserVenueScreen> createState() => _UserVenueScreenState();
}

class _UserVenueScreenState extends State<UserVenueScreen> {
  late int   _selectedTab;
  final      _searchCtrl = TextEditingController();
  String     _searchQuery      = '';
  String?    _selectedCapacity;
  int?       _maxPriceFilter;
  bool       _isLoading        = true;
  List<Venue> _firestoreHalls  = [];
  List<Venue> _firestoreRooms  = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadVenues();
  }

  // ── Load venues from Firestore ─────────────
  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('venues')
          .get();

      final all = snap.docs
          .map((d) => Venue.fromFirestore(d))
          .toList();

      if (mounted) {
        setState(() {
          _firestoreHalls = all
              .where((v) => v.type == 'event_hall')
              .toList();
          _firestoreRooms = all
              .where((v) => v.type == 'conference_room')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading venues: $e');
      // Fall back to local data if Firestore fails
      if (mounted) {
        setState(() {
          _firestoreHalls = eventHalls;
          _firestoreRooms = conferenceRooms;
          _isLoading      = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasActiveFilter =>
      _selectedCapacity != null || _maxPriceFilter != null;

  void _clearFilters() => setState(() {
    _selectedCapacity = null;
    _maxPriceFilter   = null;
  });

  // ── Capacity options per tab ───────────────
  List<String> get _capacityOptions {
    if (_selectedTab == 0) {
      return [
        'Small (200 - 300 pax)',
        'Medium (400-600 pax)',
        'Large (1,000 - 2,000 pax)',
      ];
    } else {
      return [
        'Small (50 - 100 pax)',
        'Medium (300 - 350 pax)',
        'Large (500 - 600 pax)',
      ];
    }
  }

  List<Venue> get _currentVenues =>
      _selectedTab == 0 ? _firestoreHalls : _firestoreRooms;

  List<Venue> get _venues {
    return _currentVenues.where((v) {
      if (_searchQuery.isNotEmpty &&
          !v.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCapacity != null &&
          v.capacity != _selectedCapacity) {
        return false;
      }
      if (_maxPriceFilter != null &&
          v.minPrice > _maxPriceFilter!) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showFilterSheet() {
    String? tempCapacity = _selectedCapacity;
    int?    tempMaxPrice = _maxPriceFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE8E3D8),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Venues',
                      style: TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF2C2416))),
                  GestureDetector(
                    onTap: () => ss(() {
                      tempCapacity = null;
                      tempMaxPrice = null;
                    }),
                    child: const Text('Clear all',
                        style: TextStyle(
                            fontSize:        13,
                            color:           Color(0xFF5C6B4A),
                            decoration:      TextDecoration.underline,
                            decorationColor: Color(0xFF5C6B4A))),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFCCC5B8), height: 1),
              const SizedBox(height: 20),

              // Capacity
              const Text('Capacity',
                  style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      Color(0xFF2C2416))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _capacityOptions.map((cap) {
                  final sel = tempCapacity == cap;
                  return GestureDetector(
                    onTap: () => ss(() =>
                    tempCapacity = sel ? null : cap),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF5C6B4A)
                            : const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF5C6B4A)
                                : const Color(0xFFBFB8AA)),
                      ),
                      child: Text(cap,
                          style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w500,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF2C2416))),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFCCC5B8), height: 1),
              const SizedBox(height: 20),

              // Max Price
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Max Price',
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      Color(0xFF2C2416))),
                  Text(
                    tempMaxPrice != null
                        ? 'RM ${tempMaxPrice!}'
                        : 'Any',
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      Color(0xFF5C6B4A)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(ctx).copyWith(
                  activeTrackColor:   const Color(0xFF5C6B4A),
                  inactiveTrackColor: const Color(0xFFDDD5C5),
                  thumbColor:         const Color(0xFF5C6B4A),
                  overlayColor: const Color(0xFF5C6B4A)
                      .withOpacity(0.2),
                ),
                child: Slider(
                  value: (tempMaxPrice ?? 10000).toDouble(),
                  min: 1000, max: 10000, divisions: 18,
                  onChanged: (v) =>
                      ss(() => tempMaxPrice = v.toInt()),
                ),
              ),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: const [
                  Text('RM 1,000',
                      style: TextStyle(
                          fontSize: 11,
                          color:    Color(0xFF8B7355))),
                  Text('RM 10,000',
                      style: TextStyle(
                          fontSize: 11,
                          color:    Color(0xFF8B7355))),
                ],
              ),

              const SizedBox(height: 28),

              // Apply button
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCapacity = tempCapacity;
                      _maxPriceFilter   = tempMaxPrice;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6B4A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(30)),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venues = _venues;

    return Column(
      children: [

        const SizedBox(height: 12),

        // ── Tabs ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _TabPill(
                label:      'Event Hall',
                isSelected: _selectedTab == 0,
                onTap: () => setState(() {
                  _selectedTab      = 0;
                  _searchQuery      = '';
                  _selectedCapacity = null;
                  _maxPriceFilter   = null;
                  _searchCtrl.clear();
                }),
              ),
              const SizedBox(width: 8),
              _TabPill(
                label:      'Conference Room',
                isSelected: _selectedTab == 1,
                onTap: () => setState(() {
                  _selectedTab      = 1;
                  _searchQuery      = '';
                  _selectedCapacity = null;
                  _maxPriceFilter   = null;
                  _searchCtrl.clear();
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Search bar ────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color:        const Color(0xFFEDE8E0),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: const Color(0xFFCCC5B8), width: 0.8),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(Icons.search,
                      color: Color(0xFF8B7355), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged:  (v) =>
                        setState(() => _searchQuery = v),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF3B3228)),
                    decoration: const InputDecoration(
                      hintText:  'Search venues...',
                      hintStyle: TextStyle(
                          color: Color(0xFFADA99F)),
                      border:    InputBorder.none,
                      isDense:   true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.tune,
                            color: _hasActiveFilter
                                ? const Color(0xFF5C6B4A)
                                : const Color(0xFF8B7355),
                            size: 22),
                        if (_hasActiveFilter)
                          Positioned(
                            top: -2, right: -2,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF5C6B4A),
                                  shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Active filter chips ───────────────
        if (_hasActiveFilter) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
            const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_selectedCapacity != null)
                  _Chip(
                    label:    _selectedCapacity!,
                    onRemove: () => setState(
                            () => _selectedCapacity = null),
                  ),
                if (_maxPriceFilter != null)
                  _Chip(
                    label:    'Max RM ${_maxPriceFilter!}',
                    onRemove: () =>
                        setState(() => _maxPriceFilter = null),
                  ),
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Clear all',
                        style: TextStyle(
                          fontSize:        12,
                          color:           Color(0xFF5C6B4A),
                          decoration:      TextDecoration.underline,
                          decorationColor: Color(0xFF5C6B4A),
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // ── Venue list ────────────────────────
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
                const Icon(Icons.search_off,
                    color: Color(0xFF8B7355),
                    size: 40),
                const SizedBox(height: 8),
                const Text('No venues found.',
                    style: TextStyle(
                        color: Color(0xFF8B7355))),
                if (_hasActiveFilter) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: const Text('Clear filters',
                        style: TextStyle(
                          color:           Color(0xFF5C6B4A),
                          fontWeight:      FontWeight.w600,
                          decoration:      TextDecoration.underline,
                          decorationColor: Color(0xFF5C6B4A),
                        )),
                  ),
                ],
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadVenues,
            color:     const Color(0xFF5C6B4A),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 24),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8E0),
                      borderRadius:
                      BorderRadius.circular(16),
                      border: Border.all(
                          color:
                          const Color(0xFFCCC5B8),
                          width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        // Image
                        ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(
                              top: Radius.circular(
                                  16)),
                          child: Image.asset(
                            venue.imagePath,
                            height: 180,
                            width:  double.infinity,
                            fit:    BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                                  height: 180,
                                  color: const Color(
                                      0xFFCCC5B8),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        const Icon(
                                            Icons
                                                .image_outlined,
                                            color: Color(
                                                0xFF8B7355),
                                            size: 40),
                                        const SizedBox(
                                            height: 8),
                                        Text(venue.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(
                                                  0xFF5C5040),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                        ),

                        // Name + price + Book button
                        Padding(
                          padding:
                          const EdgeInsets.fromLTRB(
                              14, 10, 14, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(venue.name,
                                        style: const TextStyle(
                                          fontSize:   14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(
                                              0xFF2C2416),
                                        )),
                                    const SizedBox(
                                        height: 2),
                                    Text(
                                        venue.priceRange,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(
                                              0xFF5C5040),
                                        )),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserVenueDetailScreen(
                                                venue: venue),
                                      ),
                                    ),
                                style: ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                  const Color(
                                      0xFF5C6B4A),
                                  foregroundColor:
                                  Colors.white,
                                  elevation: 0,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 20,
                                      vertical:   10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          20)),
                                ),
                                child: const Text('Book',
                                    style: TextStyle(
                                      fontSize:   13,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ],
                          ),
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

// ─── Tab Pill ─────────────────────────────────
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

// ─── Filter Chip ──────────────────────────────
class _Chip extends StatelessWidget {
  final String       label;
  final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color:        const Color(0xFF5C6B4A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color:      Colors.white,
              )),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
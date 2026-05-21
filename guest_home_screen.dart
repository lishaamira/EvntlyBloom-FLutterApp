import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────
//  EvntlyBloom — Guest Home Screen
// ─────────────────────────────────────────────

class GuestVenue {
  final String name;
  final String priceRange;
  final String type;
  final String imagePath;
  final int    minPrice;
  final int    maxPrice;
  final String capacity;

  const GuestVenue({
    required this.name,
    required this.priceRange,
    required this.type,
    required this.imagePath,
    required this.minPrice,
    required this.maxPrice,
    required this.capacity,
  });

  factory GuestVenue.fromFirestore(Map<String, dynamic> data) {
    return GuestVenue(
      name:       data['name']       ?? '',
      priceRange: data['priceRange'] ?? '',
      type:       data['type']       ?? 'event_hall',
      imagePath:  data['imagePath']  ?? 'assets/images/hall1.png',
      minPrice:   (data['minPrice']  ?? 0) is int
          ? data['minPrice']
          : (data['minPrice'] as num).toInt(),
      maxPrice:   (data['maxPrice']  ?? 0) is int
          ? data['maxPrice']
          : (data['maxPrice'] as num).toInt(),
      capacity:   data['capacity']   ?? '',
    );
  }
}

// ─────────────────────────────────────────────
class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int    _selectedTab = 0;
  final  _searchCtrl  = TextEditingController();
  String _searchQuery = '';

  String? _selectedCapacity;
  int?    _maxPriceFilter;

  bool              _isLoading    = true;
  List<GuestVenue>  _halls        = [];
  List<GuestVenue>  _rooms        = [];

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('venues')
          .get();

      final all = snap.docs
          .map((d) => GuestVenue.fromFirestore(d.data()))
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

  List<GuestVenue> get _currentVenues =>
      _selectedTab == 0 ? _halls : _rooms;

  // ── Capacity options derived from loaded venues ──
  List<String> get _capacityOptions {
    final caps = _currentVenues
        .map((v) => v.capacity)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    caps.sort();
    return caps;
  }

  List<GuestVenue> get _filteredVenues {
    return _currentVenues.where((v) {
      final matchSearch   = _searchQuery.isEmpty ||
          v.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCapacity = _selectedCapacity == null ||
          v.capacity == _selectedCapacity;
      final matchPrice    = _maxPriceFilter == null ||
          v.minPrice <= _maxPriceFilter!;
      return matchSearch && matchCapacity && matchPrice;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _selectedCapacity != null || _maxPriceFilter != null;

  void _clearFilters() => setState(() {
    _selectedCapacity = null;
    _maxPriceFilter   = null;
  });

  void _showFilterSheet() {
    String? tempCapacity = _selectedCapacity;
    int?    tempMaxPrice = _maxPriceFilter;

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    const Color(0xFFE8E3D8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize:      MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Venues',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: Color(0xFF2C2416))),
                  GestureDetector(
                    onTap: () => ss(() {
                      tempCapacity = null;
                      tempMaxPrice = null;
                    }),
                    child: const Text('Clear all',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF8B7355),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF8B7355))),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFCCC5B8), height: 1),
              const SizedBox(height: 20),

              const Text('Capacity',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2416))),
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
                                : const Color(0xFF2C2416),
                          )),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFCCC5B8), height: 1),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Max Price',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2416))),
                  Text(
                    tempMaxPrice != null ? 'RM $tempMaxPrice' : 'Any',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Color(0xFF5C6B4A)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(ctx).copyWith(
                  activeTrackColor:   const Color(0xFF5C6B4A),
                  inactiveTrackColor: const Color(0xFFDDD5C5),
                  thumbColor:         const Color(0xFF5C6B4A),
                  overlayColor:
                  const Color(0xFF5C6B4A).withOpacity(0.2),
                ),
                child: Slider(
                  value:     (tempMaxPrice ?? 10000).toDouble(),
                  min:       1000,
                  max:       10000,
                  divisions: 18,
                  onChanged: (v) =>
                      ss(() => tempMaxPrice = v.toInt()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('RM 1,000',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8B7355))),
                  Text('RM 10,000',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8B7355))),
                ],
              ),

              const SizedBox(height: 28),

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
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3D8),
      body: SafeArea(
        child: Column(
          children: [

            // ── Logo ───────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 12),
              child: Image.asset(
                'assets/images/eventlybloom_logo.png',
                height: 40, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('EvntlyBloom',
                    style: TextStyle(
                        fontFamily: 'Georgia', fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C6B4A))),
              ),
            ),

            // ── Tabs ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PillTabSwitcher(
                selectedIndex: _selectedTab,
                onTabChanged: (i) => setState(() {
                  _selectedTab = i;
                  _searchQuery = '';
                  _searchCtrl.clear();
                  _clearFilters();
                }),
              ),
            ),

            const SizedBox(height: 12),

            // ── Search bar ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(
                controller:      _searchCtrl,
                onChanged:       (val) => setState(() => _searchQuery = val),
                onFilterTap:     _showFilterSheet,
                hasActiveFilter: _hasActiveFilter,
              ),
            ),

            // ── Active filter chips ────────────
            if (_hasActiveFilter) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (_selectedCapacity != null)
                      _FilterChip(
                        label:    _selectedCapacity!,
                        onRemove: () =>
                            setState(() => _selectedCapacity = null),
                      ),
                    if (_maxPriceFilter != null)
                      _FilterChip(
                        label:    'Max RM $_maxPriceFilter',
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
                              color:           Color(0xFF8B7355),
                              decoration:      TextDecoration.underline,
                              decorationColor: Color(0xFF8B7355),
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Venue list ─────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF5C6B4A)))
                  : _filteredVenues.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off,
                        color: Color(0xFF5C6B4A), size: 40),
                    const SizedBox(height: 8),
                    const Text('No venues match your filters.',
                        style: TextStyle(color: Color(0xFF5C6B4A))),
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
                color: const Color(0xFF5C6B4A),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _filteredVenues.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 16),
                  itemBuilder: (context, i) => _VenueCard(
                    venue: _filteredVenues[i],
                    onDetailsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
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

// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String       label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color:        const Color(0xFF5C6B4A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: Colors.white)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _PillTabSwitcher extends StatelessWidget {
  final int                  selectedIndex;
  final void Function(int)   onTabChanged;
  const _PillTabSwitcher(
      {required this.selectedIndex, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:        const Color(0xFFD6CFC3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _PillTab(label: 'Event Hall',      isSelected: selectedIndex == 0, onTap: () => onTabChanged(0)),
          _PillTab(label: 'Conference Room', isSelected: selectedIndex == 1, onTap: () => onTabChanged(1)),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  const _PillTab(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8E3D8) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [BoxShadow(
                color:      Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset:     const Offset(0, 1))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   13,
                fontWeight: isSelected
                    ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF3B5232)
                    : const Color(0xFF7A7060),
              )),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback           onFilterTap;
  final bool                   hasActiveFilter;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    required this.hasActiveFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              controller: controller,
              onChanged:  onChanged,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF3B3228)),
              decoration: const InputDecoration(
                hintText:       'Search venues...',
                hintStyle:      TextStyle(color: Color(0xFFADA99F)),
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.tune,
                      color: hasActiveFilter
                          ? const Color(0xFF5C6B4A)
                          : const Color(0xFF8B7355),
                      size: 22),
                  if (hasActiveFilter)
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
    );
  }
}

// ─────────────────────────────────────────────
class _VenueCard extends StatelessWidget {
  final GuestVenue   venue;
  final VoidCallback onDetailsTap;
  const _VenueCard({required this.venue, required this.onDetailsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        const Color(0xFFEDE8E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCC5B8), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
            child: SizedBox(
              height: 180, width: double.infinity,
              child: Image.asset(
                venue.imagePath, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFCCC5B8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_outlined,
                          color: Color(0xFF8B7355), size: 40),
                      const SizedBox(height: 6),
                      Text(venue.name,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF5C5040))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(venue.name,
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      Color(0xFF2C2416))),
                Text(venue.priceRange,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF2C2416))),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 14, 10),
              child: GestureDetector(
                onTap: onDetailsTap,
                child: const Text('Click for more details',
                    style: TextStyle(
                      fontSize:        11,
                      color:           Color(0xFF5C6B4A),
                      decoration:      TextDecoration.underline,
                      decorationColor: Color(0xFF5C6B4A),
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
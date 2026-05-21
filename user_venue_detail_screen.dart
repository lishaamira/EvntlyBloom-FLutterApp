import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user_venue_screen.dart';
import 'user_booking_screen.dart';

class UserVenueDetailScreen extends StatelessWidget {
  final Venue venue;
  const UserVenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E3D8),
      body: Stack(
        children: [

          // ── Scrollable content ─────────────
          CustomScrollView(
            slivers: [

              // ── Hero image app bar ───────────
              SliverAppBar(
                expandedHeight:  280,
                pinned:          true,
                backgroundColor: const Color(0xFF5C6B4A),
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:        Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        venue.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFCCC5B8),
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                color: Color(0xFF8B7355), size: 60),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end:   Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Name + price card ────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFDDD5C5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFBFB8AA), width: 0.5),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(venue.name,
                                    style: const TextStyle(
                                      fontFamily:  'Georgia',
                                      fontSize:    24,
                                      fontWeight:  FontWeight.w800,
                                      color:       Color(0xFF2C2416),
                                      height:      1.2,
                                    )),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C6B4A)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  venue.type == 'event_hall'
                                      ? '🏛️ Event Hall'
                                      : '🏢 Conference',
                                  style: const TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w600,
                                    color:      Color(0xFF5C6B4A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.attach_money_rounded,
                                  color: Color(0xFF5C6B4A), size: 20),
                              const SizedBox(width: 4),
                              Text(venue.priceRange,
                                  style: const TextStyle(
                                    fontSize:   18,
                                    fontWeight: FontWeight.w700,
                                    color:      Color(0xFF5C6B4A),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: Color(0xFF8B7355), size: 16),
                              const SizedBox(width: 6),
                              Text(venue.bookingUnit,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color:    Color(0xFF8B7355),
                                  )),
                              const SizedBox(width: 16),
                              const Icon(Icons.people_outline_rounded,
                                  color: Color(0xFF8B7355), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(venue.capacity,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color:    Color(0xFF8B7355),
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Best For ─────────────────
                    if (venue.bestFor.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFF5C6B4A), size: 18),
                            const SizedBox(width: 8),
                            const Text('Best For  ',
                                style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w600,
                                  color:      Color(0xFF5C5040),
                                )),
                            Expanded(
                              child: Text(venue.bestFor,
                                  style: const TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w500,
                                    color:      Color(0xFF2C2416),
                                  )),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── Description ──────────────
                    _SectionHeader(title: 'About This Venue'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        const Color(0xFFDDD5C5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFBFB8AA), width: 0.5),
                        ),
                        child: Text(
                          venue.description.isEmpty
                              ? 'No description available.'
                              : venue.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color:    Color(0xFF3B3228),
                            height:   1.7,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Key Specs ─────────────────
                    _SectionHeader(title: 'Key Specs'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SpecCard(
                              icon:  Icons.people_outline_rounded,
                              label: 'Capacity',
                              value: venue.capacity,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SpecCard(
                              icon:  Icons.schedule_rounded,
                              label: 'Booking Unit',
                              value: venue.bookingUnit,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SpecCard(
                              icon:  Icons.attach_money_rounded,
                              label: 'Pricing',
                              value: venue.pricing,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SpecCard(
                              icon:  Icons.star_outline_rounded,
                              label: 'Best For',
                              value: venue.bestFor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Amenities ─────────────────
                    _SectionHeader(title: 'Amenities'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: venue.amenities.isEmpty
                          ? const Text('No amenities listed.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8B7355)))
                          : Wrap(
                        spacing:    8,
                        runSpacing: 8,
                        children: venue.amenities
                            .map((a) => _AmenityChip(label: a))
                            .toList(),
                      ),
                    ),

                    // Bottom padding for the fixed button
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // ── Fixed Book Now button ──────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E3D8),
                border: const Border(
                    top: BorderSide(
                        color: Color(0xFFCCC5B8), width: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset:     const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Price summary
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Starting from',
                          style: TextStyle(
                            fontSize: 11,
                            color:    Color(0xFF8B7355),
                          )),
                      Text(
                        'RM ${venue.minPrice.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (m) => '${m[1]},')}',
                        style: const TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w800,
                          color:      Color(0xFF2C2416),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Book button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    UserBookingScreen(venue: venue)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6B4A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Book Now',
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize:   17,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
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

// ─── Section Header ───────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              color:        const Color(0xFF5C6B4A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF2C2416),
              )),
        ],
      ),
    );
  }
}

// ─── Spec Card ────────────────────────────────
class _SpecCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _SpecCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0xFFDDD5C5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFBFB8AA), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color:        const Color(0xFF5C6B4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: const Color(0xFF5C6B4A), size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                fontSize: 11,
                color:    Color(0xFF8B7355),
              )),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF2C2416),
              )),
        ],
      ),
    );
  }
}

// ─── Amenity Chip ─────────────────────────────
class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:        const Color(0xFFDDD5C5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFBFB8AA), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF5C6B4A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color:      Color(0xFF3B3228),
              )),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl   = TextEditingController();
  String _searchQuery = '';
  bool   _isLoading   = true;

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Load users
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Load all bookings to count per user
      final bookingSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .get();

      final bookingCounts = <String, int>{};
      for (final doc in bookingSnap.docs) {
        final uid = doc.data()['userId'] as String? ?? '';
        if (uid.isNotEmpty) {
          bookingCounts[uid] = (bookingCounts[uid] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _users = userSnap.docs.map((d) {
            final data = d.data();
            return {
              'docId':    d.id,
              'uid':      data['uid']      ?? d.id,
              'name':     data['username'] ?? '',
              'email':    data['email']    ?? '',
              'phone':    data['phone']    ?? '',
              'role':     data['role']     ?? 'user',
              'status':   data['status']   ?? 'Active',
              'bookings': bookingCounts[data['uid'] ?? d.id] ?? 0,
            };
          }).where((u) => u['role'] != 'admin').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) =>
    u['name'].toString().toLowerCase()
        .contains(_searchQuery.toLowerCase()) ||
        u['email'].toString().toLowerCase()
            .contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final newStatus = user['status'] == 'Active' ? 'Disabled' : 'Active';
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['docId'])
          .update({'status': newStatus});
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: const Color(0xFF993C1D)),
        );
      }
    }
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: const Color(0xFFE8E3D8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color:  const Color(0xFF5C6B4A).withOpacity(0.1),
                shape:  BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF5C6B4A).withOpacity(0.3),
                    width: 2),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF5C6B4A), size: 36),
            ),

            const SizedBox(height: 12),

            Text(user['name'],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2416))),
            const SizedBox(height: 4),
            Text(user['email'],
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8B7355))),

            const SizedBox(height: 20),

            _UserInfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user['phone']),
            _UserInfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Total Bookings',
                value: '${user['bookings']} bookings'),
            _UserInfoRow(
                icon: Icons.circle,
                label: 'Status',
                value: user['status'],
                valueColor: user['status'] == 'Active'
                    ? const Color(0xFF5C6B4A)
                    : const Color(0xFF993C1D)),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _toggleStatus(user);
                },
                icon: Icon(
                  user['status'] == 'Active'
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                ),
                label: Text(
                  user['status'] == 'Active'
                      ? 'Disable Account'
                      : 'Enable Account',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: user['status'] == 'Active'
                      ? const Color(0xFF993C1D)
                      : const Color(0xFF5C6B4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _filtered;
    return Column(
      children: [

        const SizedBox(height: 12),

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
                      hintText:  'Search users...',
                      hintStyle: TextStyle(color: Color(0xFFADA99F)),
                      border:    InputBorder.none,
                      isDense:   true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _loadUsers,
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

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${users.length} users',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8B7355))),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: _isLoading
              ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C6B4A)))
              : users.isEmpty
              ? const Center(
              child: Text('No users found.',
                  style: TextStyle(color: Color(0xFF8B7355))))
              : RefreshIndicator(
            onRefresh: _loadUsers,
            color: const Color(0xFF5C6B4A),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u      = users[i];
                final active = u['status'] == 'Active';
                return GestureDetector(
                  onTap: () => _showUserDetail(u),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFDDD5C5)
                          : const Color(0xFFDDD5C5).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFBFB8AA),
                          width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF5C6B4A).withOpacity(0.1)
                                : const Color(0xFF993C1D).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_outline_rounded,
                              color: active
                                  ? const Color(0xFF5C6B4A)
                                  : const Color(0xFF993C1D),
                              size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name'],
                                  style: TextStyle(
                                    fontSize:   14,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? const Color(0xFF2C2416)
                                        : const Color(0xFF8B7355),
                                  )),
                              const SizedBox(height: 2),
                              Text(u['email'],
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF8B7355)),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '${u['bookings']} booking${u['bookings'] != 1 ? 's' : ''}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFADA99F)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF5C6B4A).withOpacity(0.1)
                                    : const Color(0xFF993C1D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(u['status'],
                                  style: TextStyle(
                                    fontSize:   11,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? const Color(0xFF5C6B4A)
                                        : const Color(0xFF993C1D),
                                  )),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFFBFB8AA), size: 18),
                          ],
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

class _UserInfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  const _UserInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B7355), size: 16),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8B7355))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF2C2416),
                )),
          ),
        ],
      ),
    );
  }
}
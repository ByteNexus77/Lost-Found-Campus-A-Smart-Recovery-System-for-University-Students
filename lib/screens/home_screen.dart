import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = "";
  String _selectedStatus = "All"; // 'All', 'Lost', 'Found', 'Resolved'
  String _selectedZone = "All Zones";

  final List<String> _zones = ['All Zones', 'Academic Zone', 'Library Zone', 'Cafeteria & Ground'];

  @override
  Widget build(BuildContext context) {
    // ইউজারের ইমেইলের প্রথম অক্ষরটি নেওয়া (গুগল অবতারের জন্য)
    final currentUser = FirebaseAuth.instance.currentUser;
    String userInitial = (currentUser?.email != null && currentUser!.email!.isNotEmpty)
        ? currentUser.email![0].toUpperCase()
        : "U";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Campus Lost & Found", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ==========================================
          // ১. GOOGLE-STYLE LETTER AVATAR IN APPBAR
          // ==========================================
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white, // সাদা বৃত্ত
                child: Text(
                  userInitial, // ইমেইলের প্রথম অক্ষর
                  style: const TextStyle(
                    color: Colors.blue, // নীল বোল্ড অক্ষর
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // লগআউট বাটন
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              icon: const Icon(Icons.logout)
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // সার্চ বার
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Search item, location or category...",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // স্ট্যাটাস ফিল্টার চিপস
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildStatusChip("All", Colors.blue),
                const SizedBox(width: 8),
                _buildStatusChip("Lost", Colors.red),
                const SizedBox(width: 8),
                _buildStatusChip("Found", Colors.green),
                const SizedBox(width: 8),
                _buildStatusChip("Resolved", Colors.blueGrey),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ক্যাম্পাস জোন ফিল্টার বাটন
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _zones.map((zone) {
                bool isSelected = _selectedZone == zone;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(
                        zone,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.blueGrey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        )
                    ),
                    selected: isSelected,
                    selectedColor: Colors.blueGrey[700],
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        _selectedZone = zone;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
                "Recent Items on Campus",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
          ),

          // মাল্টি-লেভেল ফিল্টারড লাইভ ডাটা স্ট্রিম
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        const Text("No items reported yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = (data['title'] ?? '').toString().toLowerCase();
                  String location = (data['location'] ?? '').toString().toLowerCase();
                  String category = (data['category'] ?? '').toString().toLowerCase();
                  String status = (data['status'] ?? '').toString();
                  String zone = (data['zone'] ?? '').toString();

                  bool matchesSearch = title.contains(_searchQuery) ||
                      location.contains(_searchQuery) ||
                      category.contains(_searchQuery);
                  bool matchesStatus = (_selectedStatus == "All") || (status.toLowerCase() == _selectedStatus.toLowerCase());
                  bool matchesZone = (_selectedZone == "All Zones") || (zone.toLowerCase() == _selectedZone.toLowerCase());

                  return matchesSearch && matchesStatus && matchesZone;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("No matching items found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var rawData = filteredDocs[index].data() as Map<String, dynamic>;

                    var itemData = Map<String, dynamic>.from(rawData);
                    itemData['id'] = filteredDocs[index].id;

                    bool isResolved = (itemData['status'] == 'Resolved');
                    Color badgeColor = isResolved
                        ? Colors.blueGrey
                        : (itemData['status'] == 'Lost' ? Colors.red : Colors.green);

                    String category = itemData['category'] ?? 'General';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: badgeColor.withOpacity(0.15),
                          child: Icon(
                            isResolved ? Icons.verified : _getCategoryIcon(category),
                            color: badgeColor,
                          ),
                        ),
                        title: Text(
                          itemData['title'] ?? 'No Title',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            decoration: isResolved ? TextDecoration.lineThrough : null,
                            color: isResolved ? Colors.grey[600] : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "🏢 ${itemData['zone'] ?? 'General'}",
                                    style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("📍 Spot: ${itemData['location']}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            const SizedBox(height: 2),
                            Text("📝 ${itemData['description']}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            itemData['status'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailsScreen(itemData: itemData),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        label: const Text("Post Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatusChip(String label, Color activeColor) {
    bool isSelected = _selectedStatus == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = label;
          });
        }
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'ID & Cards': return Icons.badge_outlined;
      case 'Electronics': return Icons.devices;
      case 'Wallets & Bags': return Icons.wallet;
      case 'Books & Notes': return Icons.menu_book;
      case 'Keys & Personal': return Icons.key;
      default: return Icons.category_outlined;
    }
  }
}
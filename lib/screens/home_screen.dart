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
  String _selectedStatus = "All"; // 'All', 'Lost', 'Found'

  // ==========================================
  // ক্যাম্পাসের ডিস্ট্রিবিউটেড জোন ফিল্টার স্টেট
  // ==========================================
  String _selectedZone = "All Zones";
  final List<String> _zones = ['All Zones', 'Academic Zone', 'Library Zone', 'Cafeteria & Ground'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Campus Lost & Found", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
            icon: const Icon(Icons.account_circle, size: 28),
          ),
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
          // ১. রিয়েল-টাইম সার্চ বার
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Search by item or location...",
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

          // ২. স্ট্যাটাস ফিল্টার চিপস (Lost / Found)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildStatusChip("All", Colors.blue),
                const SizedBox(width: 8),
                _buildStatusChip("Lost", Colors.red),
                const SizedBox(width: 8),
                _buildStatusChip("Found", Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ==========================================
          // ৩. ক্যাম্পাস জোন ফিল্টার বাটন (Horizontal Shards)
          // ==========================================
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

          // ৪. মাল্টি-লেভেল ফিল্টারড লাইভ ডাটা স্ট্রিম
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

                // ৩ স্তরের ফিল্টারিং: Search + Status + Zone
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = (data['title'] ?? '').toString().toLowerCase();
                  String location = (data['location'] ?? '').toString().toLowerCase();
                  String status = (data['status'] ?? '').toString();
                  String zone = (data['zone'] ?? '').toString();

                  bool matchesSearch = title.contains(_searchQuery) || location.contains(_searchQuery);
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
                    var itemData = filteredDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: itemData['status'] == 'Lost' ? Colors.red[100] : Colors.green[100],
                          child: Icon(
                            itemData['status'] == 'Lost' ? Icons.search : Icons.check_circle_outline,
                            color: itemData['status'] == 'Lost' ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(
                          itemData['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("📍 Location: ${itemData['location']}"),
                            // কার্ডে জোন দেখানো হচ্ছে
                            Text("🏢 Zone: ${itemData['zone'] ?? 'General'}", style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text("📝 ${itemData['description']}", maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: itemData['status'] == 'Lost' ? Colors.red : Colors.green,
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
}
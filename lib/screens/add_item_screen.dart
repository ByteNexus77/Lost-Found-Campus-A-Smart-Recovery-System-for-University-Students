import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();

  String _selectedStatus = 'Lost';

  // ১. ক্যাম্পাস জোন (Horizontal Sharding)
  String _selectedZone = 'Academic Zone';
  final List<String> _zones = ['Academic Zone', 'Library Zone', 'Cafeteria & Ground'];

  // ২. নতুন ফিচার: স্মার্ট ক্যাটাগরি লিস্ট
  String _selectedCategory = 'ID & Cards';
  final List<String> _categories = [
    'ID & Cards',
    'Electronics',
    'Wallets & Bags',
    'Books & Notes',
    'Keys & Personal',
    'Others'
  ];

  bool _isLoading = false;

  void _submitItem() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty || _locController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // ফায়ারবেসে ক্যাটাগরি এবং জোন সহ সম্পূর্ণ ডাটা পাঠানো
      await FirebaseFirestore.instance.collection('items').add({
        'title': _titleController.text.trim(),
        'category': _selectedCategory, // নতুন ক্যাটাগরি ফিল্ড
        'description': _descController.text.trim(),
        'location': _locController.text.trim(),
        'zone': _selectedZone,         // জোন শার্ডিং কী
        'status': _selectedStatus,
        'postedBy': user?.email ?? "Unknown User",
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item Reported Successfully!")),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error posting item: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Report Lost/Found Item"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // স্ট্যাটাস সিলেক্টর (Lost / Found)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text("Lost (হারিয়ে গেছে)", style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _selectedStatus == 'Lost',
                      onSelected: (val) => setState(() => _selectedStatus = 'Lost'),
                      selectedColor: Colors.red[100],
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(width: 15),
                    ChoiceChip(
                      label: const Text("Found (খুঁজে পেয়েছি)", style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _selectedStatus == 'Found',
                      onSelected: (val) => setState(() => _selectedStatus = 'Found'),
                      selectedColor: Colors.green[100],
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // আইটেমের নাম
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Item Name *",
                  hintText: "e.g., Student ID Card, Casio Calculator",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 15),

              // ক্যাটাগরি ড্রপডাউন
              const Text("Item Category *", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(_getCategoryIcon(cat), size: 20, color: Colors.blueGrey),
                          const SizedBox(width: 10),
                          Text(cat),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // স্পট / নির্দিষ্ট জায়গা
              TextField(
                controller: _locController,
                decoration: InputDecoration(
                  labelText: "Specific Spot / Room *",
                  hintText: "e.g., Library 2nd Floor, Room 304",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.place),
                ),
              ),
              const SizedBox(height: 15),

              // ক্যাম্পাস জোন ড্রপডাউন (Advanced Database Shard)
              const Text("Campus Zone (Database Shard) *", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedZone,
                    isExpanded: true,
                    items: _zones.map((zone) => DropdownMenuItem(
                      value: zone,
                      child: Row(
                        children: [
                          const Icon(Icons.domain, size: 20, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(zone),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedZone = val!),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // বিবরণ
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description *",
                  hintText: "Color, brand, special marks, etc.",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 30),

              // সাবমিট বাটন
              ElevatedButton(
                onPressed: _isLoading ? null : _submitItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("Submit Report", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ক্যাটাগরি আইকন হেল্পার
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
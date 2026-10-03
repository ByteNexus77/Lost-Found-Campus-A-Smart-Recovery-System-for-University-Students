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

  // Advanced Database: Horizontal Fragmentation Zone Key
  String _selectedZone = 'Academic Zone';
  final List<String> _zones = ['Academic Zone', 'Library Zone', 'Cafeteria & Ground'];

  bool _isLoading = false;

  void _submitItem() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty || _locController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // ফায়ারবেসে জোন ফ্র্যাগমেন্টেশন কি (zone) সহ ডাটা সেভ করা
      await FirebaseFirestore.instance.collection('items').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locController.text.trim(),
        'zone': _selectedZone, // ডিস্ট্রিবিউটেড ফ্র্যাগমেন্ট কী
        'status': _selectedStatus,
        'postedBy': user?.email ?? "Unknown User",
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Posted Successfully!")));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Lost/Found Item")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text("Lost"),
                      selected: _selectedStatus == 'Lost',
                      onSelected: (val) => setState(() => _selectedStatus = 'Lost'),
                      selectedColor: Colors.red[100],
                    ),
                    const SizedBox(width: 20),
                    ChoiceChip(
                      label: const Text("Found"),
                      selected: _selectedStatus == 'Found',
                      onSelected: (val) => setState(() => _selectedStatus = 'Found'),
                      selectedColor: Colors.green[100],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _locController, decoration: const InputDecoration(labelText: "Specific Spot (e.g. Room 302)", border: OutlineInputBorder())),
              const SizedBox(height: 15),

              // অ্যাডভান্সড ডাটাবেসের ফ্র্যাগমেন্টেশন জোন ড্রপডাউন
              const Text("Select Campus Zone (Database Shard):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedZone,
                    isExpanded: true,
                    items: _zones.map((zone) => DropdownMenuItem(value: zone, child: Text(zone))).toList(),
                    onChanged: (val) => setState(() => _selectedZone = val!),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 60)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Post", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const ItemDetailsScreen({super.key, required this.itemData});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.itemData['status'] ?? 'Lost';
  }

  // ইমেইল অ্যাপ ওপেন করার ফাংশন
  Future<void> _sendEmail(BuildContext context, String email, String title) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Regarding Lost/Found Item: $title',
        'body': 'Hello, I saw your post about the item "$title" on Campus Lost & Found app. I would like to contact you.',
      },
    );

    try {
      bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No email app found on this device.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open email app.")),
        );
      }
    }
  }

  // পোস্ট রেজলভড (Resolved) করার লজিক
  Future<void> _markAsResolved() async {
    setState(() => _isUpdating = true);
    try {
      String docId = widget.itemData['id'] ?? '';

      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('items').doc(docId).update({
          'status': 'Resolved',
        });
      }

      setState(() {
        _currentStatus = 'Resolved';
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item status updated to Resolved / Recovered!")),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating status: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String postedByEmail = widget.itemData['postedBy'] ?? '';
    final bool isMyPost = (currentUser?.email != null && currentUser!.email == postedByEmail);
    final bool isResolved = (_currentStatus == 'Resolved');

    // স্ট্যাটাস কালার নির্ধারণ
    Color statusColor = isResolved
        ? Colors.blueGrey
        : (_currentStatus == 'Lost' ? Colors.red : Colors.green);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Item Details"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. কালারফুল স্ট্যাটাস হেডার
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.2))),
              ),
              child: Column(
                children: [
                  Icon(
                    isResolved
                        ? Icons.verified
                        : (_currentStatus == 'Lost' ? Icons.help_outline : Icons.check_circle_outline),
                    size: 75,
                    color: statusColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isResolved ? "RECOVERED / RESOLVED" : _currentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ২. জিনিসের নাম
                  Text(
                    widget.itemData['title'] ?? "Untitled Item",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ৩. লোকেশন ও জোন
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 20),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Spot: ${widget.itemData['location'] ?? 'Unknown'} (${widget.itemData['zone'] ?? 'General'})",
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),

                  // ৪. বিবরণ
                  const Text("Item Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  Text(
                    widget.itemData['description'] ?? "No additional description provided.",
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // ৫. কন্টাক্ট পারসন কার্ড
                  const Text("Reported By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle, color: Colors.blue, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isMyPost ? "Your Submission" : "Student Email:", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                postedByEmail.isNotEmpty ? postedByEmail : "Anonymous",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ==========================================
                  // ৬. ডাইনামিক অ্যাকশন বাটন (Ownership Logic)
                  // ==========================================
                  if (isResolved)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text("This item has been recovered and resolved.", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else if (isMyPost)
                    ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _markAsResolved,
                      icon: _isUpdating
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text("Mark as Recovered / Resolved", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _sendEmail(context, postedByEmail, widget.itemData['title'] ?? ''),
                      icon: const Icon(Icons.mail_outline, color: Colors.white),
                      label: const Text("Contact Founder / Owner", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
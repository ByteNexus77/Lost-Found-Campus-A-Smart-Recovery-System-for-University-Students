import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> itemData;

  const ItemDetailsScreen({super.key, required this.itemData});




  Future<void> _sendEmail(BuildContext context, String email, String title) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Regarding Lost/Found Item: $title',
        'body': 'Hello, I saw your post about the item "$title" on the Campus Lost & Found app. I would like to contact you regarding this.',
      },
    );

    try {

      bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not find an email app on this device.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error opening email app. Please try manually.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    Color statusColor = itemData['status'] == 'Lost' ? Colors.red : Colors.green;

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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  Icon(
                    itemData['status'] == 'Lost' ? Icons.help_outline : Icons.check_circle_outline,
                    size: 80,
                    color: statusColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    itemData['status']?.toUpperCase() ?? "UNKNOWN",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    itemData['title'] ?? "Untitled Item",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),


                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 22),
                      const SizedBox(width: 5),
                      Text(
                        "Location: ${itemData['location'] ?? 'Unknown'}",
                        style: TextStyle(fontSize: 17, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const Divider(height: 50, thickness: 1),


                  const Text(
                    "Item Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    itemData['description'] ?? "No additional details provided.",
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 35),


                  const Text(
                    "Contact Person",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
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
                              const Text("Posted via Email:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                itemData['postedBy'] ?? "Not available",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),




                  ElevatedButton.icon(
                    onPressed: () => _sendEmail(
                        context,
                        itemData['postedBy'] ?? "",
                        itemData['title'] ?? ""
                    ),
                    icon: const Icon(Icons.mail_outline, color: Colors.white),
                    label: const Text(
                      "Contact Now via Email",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
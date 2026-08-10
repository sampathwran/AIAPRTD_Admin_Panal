import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MarketplacePendingTab extends StatelessWidget {
  const MarketplacePendingTab({super.key});

  void _updateAdStatus(String id, String status) {
    FirebaseFirestore.instance.collection('marketplace_ads').doc(id).update({
      'status': status,
    });
  }

  void _showAdDetails(BuildContext context, Map<String, dynamic> adData) {
    final imageUrls = adData['imageUrls'] as List<dynamic>? ?? [];
    final title = adData['title'] ?? 'No Title';
    final price = adData['price'] ?? '0';
    final category = adData['category'] ?? '';
    final desc = adData['description'] ?? 'No description provided.';
    final address = adData['address'] ?? 'No address provided.';
    final lat = adData['lat']?.toString() ?? 'N/A';
    final lng = adData['lng']?.toString() ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageUrls.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: imageUrls.length,
                        itemBuilder: (context, idx) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Image.network(
                              imageUrls[idx],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    "Price: LKR $price",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Category: $category",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Description:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(desc),
                  const SizedBox(height: 16),
                  const Text(
                    "Location:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(address),
                  Text(
                    "Coordinates: $lat, $lng",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('marketplace_ads')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList();

        // Sort locally to avoid needing a Firestore composite index
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) return const Center(child: Text("No pending ads."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
            final title = data['title'] ?? 'No Title';
            final price = data['price'] ?? '0';
            final category = data['category'] ?? '';
            final desc = data['description'] ?? '';
            final createdAt = data['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        imageUrls.isNotEmpty
                            ? Image.network(
                                imageUrls[0],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image),
                                    ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Price: LKR $price",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text("Category: $category"),
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Posted: ${createdAt != null ? DateFormat.yMd().add_jm().format(createdAt.toDate()) : 'Unknown'}",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showAdDetails(context, data),
                          icon: const Icon(Icons.visibility),
                          label: const Text("View Details"),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _updateAdStatus(docs[index].id, 'rejected'),
                          icon: const Icon(Icons.close),
                          label: const Text("Reject"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _updateAdStatus(docs[index].id, 'approved'),
                          icon: const Icon(Icons.check),
                          label: const Text("Approve"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

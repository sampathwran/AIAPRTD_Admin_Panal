import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MarketplaceSoldTab extends StatelessWidget {
  const MarketplaceSoldTab({super.key});

  void _deleteAd(String id) {
    FirebaseFirestore.instance.collection('marketplace_ads').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('marketplace_ads')
          .where('status', isEqualTo: 'sold')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['soldAt'] as Timestamp?;
          final bTime = bData['soldAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) return const Center(child: Text("No sold ads found."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
            final title = data['title'] ?? 'No Title';
            final price = data['price'] ?? '0';
            final category = data['category'] ?? '';
            final soldAt = data['soldAt'] as Timestamp?;

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
                              width: 100, height: 100, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 100, color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                            )
                          : Container(width: 100, height: 100, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough)),
                              Text("Price: LKR $price", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                              Text("Category: $category"),
                              const SizedBox(height: 8),
                              Text("Sold At: ${soldAt != null ? DateFormat.yMd().add_jm().format(soldAt.toDate()) : 'Unknown'}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAd(docs[index].id),
                          tooltip: "Delete Permanently",
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

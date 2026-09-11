import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecentHistoryList extends StatelessWidget {
  const RecentHistoryList({super.key});

  Future<void> _revertToPending(BuildContext context, Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final membershipNo = data['membershipNo'] as String?;
    final requestData = data['requestData'] as Map<String, dynamic>? ?? {};
    
    if (type == null || membershipNo == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reverting to pending..."), duration: Duration(seconds: 1)),
      );

      final firestore = FirebaseFirestore.instance;
      String collection = '';
      String statusField = 'status';
      String docId = membershipNo;

      if (type == 'VEHICLE_CHANGE') {
        collection = 'vehicles';
      } else if (type == 'KYC_VERIFICATION') {
        collection = 'verify_kyc';
        statusField = 'kycApprovalStatus';
      } else if (type == 'BANK_DETAILS_UPDATE') {
        collection = 'verify_bank';
      } else if (type == 'PROFILE_IMAGE_UPDATE') {
        collection = 'profile_image_requests';
        docId = requestData['docId'] ?? membershipNo; 
      } else if (type == 'PROFILE_INFO_UPDATE') {
        collection = 'requests';
        docId = requestData['id'] ?? membershipNo;
      } else {
        throw Exception("Unknown request type: $type");
      }

      if (collection == 'requests' || collection == 'profile_image_requests') {
        if (requestData['docId'] != null) {
            docId = requestData['docId'];
        } else {
            final query = await firestore.collection(collection)
               .where('membershipNo', isEqualTo: membershipNo)
               .limit(1)
               .get();
            if (query.docs.isNotEmpty) {
                docId = query.docs.first.id;
            }
        }
      }

      final updateData = <String, dynamic>{
        statusField: 'pending',
      };

      if (collection == 'vehicles') {
        updateData['canEdit'] = true; // So admin can edit again
      }

      await firestore.collection(collection).doc(docId).update(updateData);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reverted to Pending! You can now edit it from the queues."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reverting to pending: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRevertDialog(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'] ?? 'unknown';
    final type = data['type'] ?? 'Unknown';
    final isApproved = status.toString().toLowerCase() == 'approved';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text("Review Past Action"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Type: ${type.toString().replaceAll('_', ' ')}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Status was set to: ${status.toString().toUpperCase()}", 
                style: TextStyle(
                  color: isApproved ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold
                )
              ),
              const SizedBox(height: 16),
              const Text("Do you want to move this request back to the PENDING queue so you can edit and review it again?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _revertToPending(context, data);
              },
              child: const Text("Revert to Pending", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activation_history')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(threeDaysAgo))
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Recent History Error: ${snapshot.error}");
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Error loading history: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Row(
              children: [
                Icon(Icons.history_toggle_off_rounded, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'RECENT HISTORY (LAST 3 DAYS)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  "Click to Revert & Edit",
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final type = data['type'] ?? 'Unknown';
                final status = data['status'] ?? 'Unknown';
                final membershipNo = data['membershipNo'] ?? 'Unknown';
                final ts = data['timestamp'] as Timestamp?;
                
                String dateStr = "N/A";
                if (ts != null) {
                  dateStr = DateFormat('MMM dd, hh:mm a').format(ts.toDate());
                }
                
                final isApproved = status.toString().toLowerCase() == 'approved';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200)
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showRevertDialog(context, data),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Icon(
                              isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: isApproved ? Colors.green : Colors.red,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Member: $membershipNo",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  type.toString().replaceAll('_', ' '),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                dateStr,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "REVERT",
                                style: TextStyle(
                                  color: Colors.blue.shade700, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

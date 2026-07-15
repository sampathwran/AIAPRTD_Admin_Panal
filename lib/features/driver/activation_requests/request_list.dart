import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/request_details_page.dart';

class RequestList extends StatelessWidget {
  final String selectedStatus;
  final String searchQuery;

  // Dashboard එකෙන් select වෙන status එකයි search query එකයි මෙහාට pass කරනවා
  const RequestList({
    super.key,
    required this.selectedStatus,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    // Query එක dynamic කරනවා status එක අනුව
    Query query = FirebaseFirestore.instance.collection('vehicles');

    if (selectedStatus != 'all') {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var docs = snapshot.data!.docs;

        // Membership Number එකෙන් client-side filtering කරනවා (Realtime)
        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final membershipNo =
                data['membershipNo']?.toString().toLowerCase() ?? '';
            return membershipNo.contains(searchQuery.toLowerCase());
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true, // Dashboard එක ඇතුලේ scroll වෙන්න shrinkWrap දානවා
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            // DB fields missing නම් crash නොවෙන්න default tags දානවා
            final memberName = data['memberName'] ?? 'Unknown Member';
            final membershipNo = data['membershipNo'] ?? 'No ID';
            final profileImage = data['profileImage'] ?? '';
            final status = data['status'] ?? 'pending';
            final vehicleName = data['vehicleName'] ?? 'Vehicle Details N/A';

            return RequestCard(
              memberName: memberName,
              membershipNo: membershipNo,
              profileImage: profileImage,
              status: status,
              vehicleName: vehicleName,
              onViewPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestDetailsPage(requestId: doc.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Data නැති වෙලාවට පෙන්නන ලස්සන Empty View එකක්
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 50,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            "No ${selectedStatus != 'all' ? selectedStatus.toUpperCase() : ''} Requests Found",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final String memberName;
  final String membershipNo;
  final String profileImage;
  final String status;
  final String vehicleName;
  final VoidCallback onViewPressed;

  const RequestCard({
    super.key,
    required this.memberName,
    required this.membershipNo,
    required this.profileImage,
    required this.status,
    required this.vehicleName,
    required this.onViewPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Status එක අනුව color එක තීරණය කරනවා
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : null,
            child: profileImage.isEmpty
                ? Icon(Icons.person, color: Colors.grey.shade600)
                : null,
          ),
          title: Text(
            memberName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xff1B2735),
            ),
          ),
          subtitle: Text(
            "ID: $membershipNo",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Vehicle: $vehicleName",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1B2735),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onViewPressed,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Review Request",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
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

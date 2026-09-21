import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/request_details_page.dart';

class RequestList extends StatefulWidget {
  final String selectedStatus;
  final String searchQuery;

  const RequestList({
    super.key,
    required this.selectedStatus,
    required this.searchQuery,
  });

  @override
  State<RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<RequestList> {
  late Stream<QuerySnapshot> _stream;
  String _lastStatus = '';

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(RequestList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _initStream();
    }
  }

  void _initStream() {
    _lastStatus = widget.selectedStatus;
    Query query = FirebaseFirestore.instance.collection('vehicles');
    if (_lastStatus == 'pending') {
      query = query.where('status', whereIn: ['pending', 'pending_approval']);
    } else if (_lastStatus != 'all') {
      query = query.where('status', isEqualTo: _lastStatus);
    }
    _stream = query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
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

        // Search filtering logic (Name, MembershipNo, VehicleName)
        if (widget.searchQuery.isNotEmpty) {
          final queryStr = widget.searchQuery.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final membershipNo = data['membershipNo']?.toString().toLowerCase() ?? '';
            final memberName = data['memberName']?.toString().toLowerCase() ?? '';
            final vehicleName = data['vehicleName']?.toString().toLowerCase() ?? '';

            return membershipNo.contains(queryStr) ||
                memberName.contains(queryStr) ||
                vehicleName.contains(queryStr);
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final memberName = data['memberName'] ?? 'Unknown Member';
            final membershipNo = data['membershipNo']?.toString().isNotEmpty == true ? data['membershipNo'] : doc.id;
            final profileImage = data['profileImage'] ?? '';
            final status = data['status'] ?? 'pending';
            final vehicleName = data['vehicleName'] ?? 'Vehicle Details N/A';

            // Check if any document inside this request has a pending status (New Upload)
            bool hasPendingDocs = false;
            if (data['documents'] is List) {
              final docList = data['documents'] as List;
              hasPendingDocs = docList.any((d) => d is Map && (d['status'] == 'pending' || d['status'] == 'pending_approval'));
            }

            return RequestCard(
              memberName: memberName,
              membershipNo: membershipNo,
              profileImage: profileImage,
              status: status,
              vehicleName: vehicleName,
              hasPendingDocs: hasPendingDocs,
              onViewPressed: () {
                html.window.history.pushState(null, 'Request Details', '/dashboard/driver/activation_requests?subpage=RequestDetails&requestId=${doc.id}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestDetailsPage(requestId: doc.id),
                  ),
                ).then((_) {
                  html.window.history.pushState(null, 'Admin Dashboard', '/dashboard/driver/activation_requests');
                });
              },
            );
          },
        );
      },
    );
  }

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
            "No ${widget.selectedStatus != 'all' ? widget.selectedStatus.toUpperCase() : ''} Requests Found",
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
  final bool hasPendingDocs;
  final VoidCallback onViewPressed;

  const RequestCard({
    super.key,
    required this.memberName,
    required this.membershipNo,
    required this.profileImage,
    required this.status,
    required this.vehicleName,
    required this.hasPendingDocs,
    required this.onViewPressed,
  });

  @override
  Widget build(BuildContext context) {
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
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : null,
                child: profileImage.isEmpty
                    ? Icon(Icons.person, color: Colors.grey.shade600)
                    : null,
              ),
              if (hasPendingDocs)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
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

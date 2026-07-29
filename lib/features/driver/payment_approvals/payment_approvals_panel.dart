import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/payment_approvals/payment_approval_service.dart';

class PaymentApprovalsPanel extends StatefulWidget {
  const PaymentApprovalsPanel({super.key});

  @override
  State<PaymentApprovalsPanel> createState() => _PaymentApprovalsPanelState();
}

class _PaymentApprovalsPanelState extends State<PaymentApprovalsPanel> {
  final PaymentApprovalService _service = PaymentApprovalService();
  bool _isLoading = false;

  final List<String> _rejectReasons = [
    "Bank slip is not clear",
    "Payment amount mismatch",
    "Invalid bank slip",
    "Duplicate payment",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pending Payments Section
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pending Approvals",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('app_usage_payments')
                        .where('status', isEqualTo: 'pending')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No pending approvals",
                            style: TextStyle(color: AdminColors.faint),
                          ),
                        );
                      }
                      return _buildDataTable(docs, true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Approved Payments Section (Last 7 Days)
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recent Approvals (Last 7 Days)",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('app_usage_payments')
                        .where('status', isEqualTo: 'approved')
                        .where('approvedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))))
                        .orderBy('approvedAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No recent approvals",
                            style: TextStyle(color: AdminColors.faint),
                          ),
                        );
                      }
                      return _buildDataTable(docs, false);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> docs, bool isPending) {
    return ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AdminColors.sidebarLine.withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Driver Info')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Slip')),
            DataColumn(label: Text('Actions')),
          ],
          rows: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final paymentId = doc.id;
            final driverId = data['driverId'] ?? '';
            final amount = (data['amount'] ?? 0.0).toDouble();
            final imageUrl = data['imageUrl'] ?? '';
            final timestamp = data['timestamp'] as Timestamp?;
            final approvedAt = data['approvedAt'] as Timestamp?;
            
            final dateToShow = (isPending ? timestamp : approvedAt) ?? timestamp;
            final dateString = dateToShow != null 
                ? DateFormat('MMM dd, yyyy - hh:mm a').format(dateToShow.toDate())
                : 'Unknown';

            return DataRow(
              cells: [
                DataCell(Text(dateString, style: const TextStyle(fontSize: 13))),
                DataCell(_buildDriverInfo(driverId)),
                DataCell(
                  Text(
                    'LKR ${NumberFormat('#,##0.00').format(amount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AdminColors.primary),
                  ),
                ),
                DataCell(
                  TextButton.icon(
                    onPressed: () => _viewSlip(imageUrl),
                    icon: const Icon(Icons.image, size: 16),
                    label: const Text('View Slip'),
                  ),
                ),
                DataCell(
                  isPending 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleApprove(paymentId, driverId, amount),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Approve'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _isLoading ? null : () => _showRejectDialog(paymentId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Reject'),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            const Text('Approved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ],
            );
          }).toList(),
        ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo(String driverId) {
    return Consumer<MemberProvider>(
      builder: (context, provider, child) {
        final member = provider.allMembersList.firstWhere(
          (m) => m['membershipNo'] == driverId,
          orElse: () => <String, dynamic>{},
        );
        final name = member['fullName'] ?? 'Unknown Member';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(driverId, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(name, style: const TextStyle(fontSize: 12, color: AdminColors.faint)),
          ],
        );
      },
    );
  }

  void _viewSlip(String imageUrl) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No slip image available')));
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 300,
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 300,
                  height: 200,
                  child: Center(child: Text('Failed to load image', style: TextStyle(color: Colors.red))),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.7)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(String paymentId, String driverId, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment?'),
        content: Text('Are you sure you want to approve this payment of LKR ${NumberFormat('#,##0.00').format(amount)}? This will deduct the amount from the driver\'s outstanding balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Yes, Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _service.approvePayment(paymentId, driverId, amount);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment approved successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(String paymentId) {
    String? selectedReason;
    final otherController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Reject Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason for rejection:'),
                  const SizedBox(height: 10),
                  ..._rejectReasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value),
                    contentPadding: EdgeInsets.zero,
                  )),
                  if (selectedReason == 'Other')
                    TextField(
                      controller: otherController,
                      decoration: const InputDecoration(
                        labelText: 'Enter custom reason',
                        border: OutlineInputBorder(),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedReason == null ? null : () {
                  final finalReason = selectedReason == 'Other' ? otherController.text : selectedReason!;
                  if (finalReason.isEmpty) return;
                  Navigator.pop(context);
                  _handleReject(paymentId, finalReason);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleReject(String paymentId, String reason) async {
    setState(() => _isLoading = true);
    try {
      await _service.rejectPayment(paymentId, reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment rejected.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

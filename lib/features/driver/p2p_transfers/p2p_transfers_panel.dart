import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/p2p_transfers/p2p_transfers_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class P2PTransfersPanel extends StatefulWidget {
  const P2PTransfersPanel({super.key});

  @override
  State<P2PTransfersPanel> createState() => _P2PTransfersPanelState();
}

class _P2PTransfersPanelState extends State<P2PTransfersPanel> {
  final P2PTransfersService _service = P2PTransfersService();
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
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "P2P Transfers (App Usage Charges)",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.ink),
                ),
              ],
            ),
          ),
          
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AdminColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AdminColors.primary,
              tabs: [
                Tab(text: "Pending Union Verifications"),
                Tab(text: "All Transactions"),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.streamPendingVerifications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final debts = snapshot.data!;
        if (debts.isEmpty) {
          return const Center(child: Text("No pending union payments to verify."));
        }

        return Container(
          margin: const EdgeInsets.all(20),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectionArea(
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: const DataTableThemeData(
                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                    dataTextStyle: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  dataRowMaxHeight: double.infinity,
                  dataRowMinHeight: 56,
                  columns: const [
                  DataColumn(label: Text('Uploaded At')),
                  DataColumn(label: Text('Debtor (Paid)')),
                  DataColumn(label: Text('Creditor (Owed)')),
                  DataColumn(label: Text('Trip ID')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: debts.map((debt) {
                  final date = (debt['uploadedAt'] as Timestamp?)?.toDate();
                  final dateStr = date != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(date) : 'N/A';
                  final amount = (debt['amount'] ?? 0.0).toDouble();
                  final debtorId = debt['debtorId'] ?? 'Unknown';
                  final creditorId = debt['creditorId'] ?? 'Unknown';
                  final tripId = debt['tripId'] ?? '-';
                  final slipUrl = debt['slipUrl'];

                  return DataRow(
                    cells: [
                      DataCell(Text(dateStr)),
                      DataCell(Text(debtorId, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(creditorId, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(tripId)),
                      DataCell(Text('LKR ${NumberFormat('#,##0.00').format(amount)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (slipUrl != null)
                              OutlinedButton.icon(
                                onPressed: () => _showReviewDialog(debt['id'], debtorId, creditorId, amount, slipUrl),
                                icon: const Icon(Icons.remove_red_eye, size: 16),
                                label: const Text("Review & Approve"),
                              )
                            else
                              const Text("No Slip"),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.streamAllP2PTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final debts = snapshot.data!;
        if (debts.isEmpty) {
          return const Center(child: Text("No transactions yet."));
        }

        return Container(
          margin: const EdgeInsets.all(20),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectionArea(
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: const DataTableThemeData(
                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                    dataTextStyle: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  dataRowMaxHeight: double.infinity,
                  dataRowMinHeight: 56,
                  columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Debtor')),
                  DataColumn(label: Text('Creditor')),
                  DataColumn(label: Text('Trip ID')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Payment Method')),
                  DataColumn(label: Text('Status')),
                ],
                rows: debts.map((debt) {
                  final date = (debt['createdAt'] as Timestamp?)?.toDate();
                  final dateStr = date != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(date) : 'N/A';
                  final amount = (debt['amount'] ?? 0.0).toDouble();
                  final debtorId = debt['debtorId'] ?? '-';
                  final creditorId = debt['creditorId'] ?? '-';
                  final tripId = debt['tripId'] ?? '-';
                  final method = debt['paymentMethod'] ?? 'Not selected';
                  final status = debt['status'] ?? 'unknown';

                  return DataRow(
                    cells: [
                      DataCell(Text(dateStr)),
                      DataCell(Text(debtorId)),
                      DataCell(Text(creditorId)),
                      DataCell(Text(tripId)),
                      DataCell(Text('LKR ${NumberFormat('#,##0.00').format(amount)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(method.toString().toUpperCase())),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'settled': return Colors.green;
      case 'pending': return Colors.orange;
      case 'pending_admin_verification': return Colors.blue;
      case 'slip_uploaded': return Colors.purple;
      default: return Colors.grey;
    }
  }

  void _showReviewDialog(String debtId, String debtorId, String creditorId, double amount, String slipUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SelectionArea(
          child: SizedBox(
            width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Review Union Payment (P2P)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: slipUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.error, color: Colors.red, size: 40), SizedBox(height: 8), Text('Failed to load image')],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Details and Actions
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Transaction Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildDetailRow('Debtor', debtorId),
                          _buildDetailRow('Creditor (Receives)', creditorId),
                          _buildDetailRow('Amount', 'LKR ${NumberFormat('#,##0.00').format(amount)}', isHighlight: true),
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                            child: const Text(
                              'If approved, this amount will be added to the Creditor\'s Savings Balance since the payment was made to the Union account.',
                              style: TextStyle(color: Colors.blue, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () {
                                    Navigator.pop(context);
                                    _showRejectDialog(debtId, debtorId);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Reject Slip'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () {
                                    Navigator.pop(context);
                                    _handleApprove(debtId, creditorId, amount);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Approve Payment'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlight ? 18 : 14,
              color: isHighlight ? Colors.blue : Colors.black87,
            )
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String debtId, String debtorId) {
    String? selectedReason;
    final otherController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return SelectionArea(
            child: AlertDialog(
              title: const Text('Reject Union Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason for rejecting the slip:'),
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: selectedReason == null ? null : () {
                  final reason = selectedReason == 'Other' ? otherController.text : selectedReason!;
                  if (reason.isEmpty) return;
                  Navigator.pop(context);
                  _handleReject(debtId, debtorId, reason);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Reject Payment'),
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleApprove(String debtId, String creditorId, double amount) async {
    setState(() => _isLoading = true);
    try {
      await _service.approveUnionPayment(debtId, creditorId, amount);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment approved and credited to Savings.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject(String debtId, String debtorId, String reason) async {
    setState(() => _isLoading = true);
    try {
      await _service.rejectUnionPayment(debtId, debtorId, reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment rejected. Debtor can re-upload.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}


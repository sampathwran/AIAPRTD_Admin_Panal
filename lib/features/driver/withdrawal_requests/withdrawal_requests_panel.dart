import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/withdrawal_requests/withdrawal_requests_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequestsPanel extends StatefulWidget {
  const WithdrawalRequestsPanel({super.key});

  @override
  State<WithdrawalRequestsPanel> createState() => _WithdrawalRequestsPanelState();
}

class _WithdrawalRequestsPanelState extends State<WithdrawalRequestsPanel> {
  final WithdrawalRequestsService _service = WithdrawalRequestsService();
  bool _isLoading = false;

  final List<String> _rejectReasons = [
    "Invalid Bank Details",
    "Insufficient Balance",
    "Account Blocked",
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
                  "Withdrawal Requests",
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
                Tab(text: "Pending Requests"),
                Tab(text: "History"),
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
      stream: _service.streamPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text("No pending withdrawal requests."));
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
                  DataColumn(label: Text('Date & Time')),
                  DataColumn(label: Text('Member ID')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Savings Balance')),
                  DataColumn(label: Text('Bank Details')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: requests.map((req) {
                  final date = (req['timestamp'] as Timestamp?)?.toDate();
                  final dateStr = date != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(date) : 'N/A';
                  final amount = (req['amount'] ?? 0.0).toDouble();
                  final memberId = req['memberId'] ?? 'Unknown';
                  final bank = req['bankDetails'] ?? {};
return DataRow(
                    cells: [
                      DataCell(Text(dateStr)),
                      DataCell(Text(memberId, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('LKR ${NumberFormat('#,##0.00').format(amount)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                      DataCell(
                        FutureBuilder<double>(
                          future: _service.getMemberSavingsBalance(memberId),
                          builder: (context, balSnap) {
                            if (balSnap.connectionState == ConnectionState.waiting) return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
                            final bal = balSnap.data ?? 0.0;
                            return Text('LKR ${NumberFormat('#,##0.00').format(bal)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                          }
                        )
                      ),
                      DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${bank['bankName'] ?? 'N/A'} (${bank['branch'] ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${bank['accountName'] ?? 'N/A'}'),
                              Text('${bank['accountNumber'] ?? 'N/A'}', style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _handleApprove(req['id'], memberId, amount),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text("Approve"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _showRejectDialog(req['id'], memberId, amount),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text("Reject"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            ),
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
      stream: _service.streamRequestHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text("No request history."));
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
                  DataColumn(label: Text('Date & Time')),
                  DataColumn(label: Text('Member ID')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Bank Details')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Reason (If Rejected)')),
                ],
                rows: requests.map((req) {
                  final date = (req['timestamp'] as Timestamp?)?.toDate();
                  final dateStr = date != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(date) : 'N/A';
                  final amount = (req['amount'] ?? 0.0).toDouble();
                  final memberId = req['memberId'] ?? 'Unknown';
                  final status = req['status'] ?? 'unknown';
                  final reason = req['rejectReason'] ?? '-';
                  final bank = req['bankDetails'] ?? {};
return DataRow(
                    cells: [
                      DataCell(Text(dateStr)),
                      DataCell(Text(memberId, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('LKR ${NumberFormat('#,##0.00').format(amount)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${bank['bankName'] ?? 'N/A'} (${bank['branch'] ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${bank['accountName'] ?? 'N/A'}'),
                              Text('${bank['accountNumber'] ?? 'N/A'}', style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: status == 'approved' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: status == 'approved' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(reason)),
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

  Future<void> _handleApprove(String requestId, String memberId, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Withdrawal?'),
        content: Text('Are you sure you have deposited LKR ${NumberFormat('#,##0.00').format(amount)} to the member\'s bank account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Yes, Approved'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _service.approveWithdrawal(requestId, memberId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal approved successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(String requestId, String memberId, double amount) {
    String? selectedReason;
    final otherController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return SelectionArea(
            child: AlertDialog(
              title: const Text('Reject Withdrawal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This will refund LKR ${NumberFormat('#,##0.00').format(amount)} to their savings balance.'),
                    const SizedBox(height: 10),
                    const Text('Select a reason:'),
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
                    _handleReject(requestId, memberId, amount, reason);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Reject & Refund'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleReject(String requestId, String memberId, double amount, String reason) async {
    setState(() => _isLoading = true);
    try {
      await _service.rejectWithdrawal(requestId, memberId, amount, reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal rejected and refunded.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}


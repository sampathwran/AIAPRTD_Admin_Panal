import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FinancePanel extends StatefulWidget {
  const FinancePanel({super.key});

  @override
  State<FinancePanel> createState() => _FinancePanelState();
}

class _FinancePanelState extends State<FinancePanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: AdminSectionHeader(
            title: 'Finance Management',
            subtitle: 'Manage union revenue, system rates, and withdrawal requests',
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AdminColors.primary,
                  unselectedLabelColor: AdminColors.muted,
                  indicatorColor: AdminColors.primary,
                  tabs: const [
                    Tab(text: 'Settings & Rates'),
                    Tab(text: 'Withdrawal Requests'),
                    Tab(text: 'App Usage Payments'),
                    Tab(text: 'Revenue Overview'),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSettingsTab(),
                      _buildWithdrawalRequestsTab(),
                      _buildAppUsagePaymentsTab(),
                      _buildOverviewTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      child: Card(
        color: AdminColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: const FinanceSettingsForm(),
        ),
      ),
    );
  }

  Widget _buildWithdrawalRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('withdrawal_requests').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No withdrawal requests."));

        return SingleChildScrollView(
          child: Card(
            color: AdminColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AdminColors.line),
            ),
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Member ID")),
                DataColumn(label: Text("Amount (LKR)")),
                DataColumn(label: Text("Bank Details")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Actions")),
              ],
              rows: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['timestamp'] != null ? DateFormat('yyyy-MM-dd HH:mm').format((data['timestamp'] as Timestamp).toDate()) : 'N/A';
                final isPending = data['status'] == 'pending';
                final bank = data['bankDetails'] ?? {};
                
                return DataRow(
                  cells: [
                    DataCell(Text(date)),
                    DataCell(Text(data['memberId'] ?? '')),
                    DataCell(Text(NumberFormat('#,##0.00').format(data['amount'] ?? 0))),
                    DataCell(Text("${bank['bankName'] ?? ''}\n${bank['accountNumber'] ?? ''}")),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(
                      isPending ? ElevatedButton(
                        onPressed: () => _showWithdrawalApprovalDialog(doc.id, data),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                        child: const Text("Review", style: TextStyle(color: Colors.white)),
                      ) : const Text("-"),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showWithdrawalApprovalDialog(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Review Withdrawal"),
        content: Text("Approve withdrawal of LKR ${NumberFormat('#,##0.00').format(data['amount'])} for Member ${data['memberId']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('withdrawal_requests').doc(docId).update({'status': 'rejected'});
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final batch = FirebaseFirestore.instance.batch();
                
                // 1. Update Request Status
                batch.update(FirebaseFirestore.instance.collection('withdrawal_requests').doc(docId), {
                  'status': 'approved',
                  'processedAt': FieldValue.serverTimestamp(),
                });
                
                // 2. Deduct from Member Savings
                batch.set(FirebaseFirestore.instance.collection('members').doc(data['memberId']), {
                  'savingsBalance': FieldValue.increment(-(data['amount'] as num).toDouble()),
                }, SetOptions(merge: true));
                
                // 3. Add Finance Transaction Record
                final txnRef = FirebaseFirestore.instance.collection('finance_transactions').doc();
                batch.set(txnRef, {
                  'transactionId': txnRef.id,
                  'type': 'withdrawal_approved',
                  'memberId': data['memberId'],
                  'amount': data['amount'],
                  'timestamp': FieldValue.serverTimestamp(),
                });
                
                await batch.commit();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal Approved!')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsagePaymentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('app_usage_payments').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No app usage payments."));

        return SingleChildScrollView(
          child: Card(
            color: AdminColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AdminColors.line),
            ),
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Driver ID")),
                DataColumn(label: Text("Amount (LKR)")),
                DataColumn(label: Text("Slip")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Actions")),
              ],
              rows: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['timestamp'] != null ? DateFormat('yyyy-MM-dd HH:mm').format((data['timestamp'] as Timestamp).toDate()) : 'N/A';
                final isPending = data['status'] == 'pending';
                
                return DataRow(
                  cells: [
                    DataCell(Text(date)),
                    DataCell(Text(data['driverId'] ?? '')),
                    DataCell(Text(NumberFormat('#,##0.00').format(data['amount'] ?? 0))),
                    DataCell(
                      data['imageUrl'] != null
                          ? InkWell(
                              onTap: () => _showImageDialog(data['imageUrl']),
                              child: const Text("View Slip", style: TextStyle(color: AdminColors.primary, decoration: TextDecoration.underline)),
                            )
                          : const Text("No Slip"),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(
                      isPending ? ElevatedButton(
                        onPressed: () => _showSlipApprovalDialog(doc.id, data),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                        child: const Text("Review", style: TextStyle(color: Colors.white)),
                      ) : const Text("-"),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Image.network(url, fit: BoxFit.contain),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSlipApprovalDialog(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Review Bank Slip"),
        content: Text("Approve slip payment of LKR ${NumberFormat('#,##0.00').format(data['amount'])} for Driver ${data['driverId']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('app_usage_payments').doc(docId).update({'status': 'rejected'});
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final batch = FirebaseFirestore.instance.batch();
                
                // 1. Update Request Status
                batch.update(FirebaseFirestore.instance.collection('app_usage_payments').doc(docId), {
                  'status': 'approved',
                  'processedAt': FieldValue.serverTimestamp(),
                });
                
                // 2. Deduct from Member App Usage Balance
                batch.set(FirebaseFirestore.instance.collection('members').doc(data['driverId']), {
                  'appUsageChargeBalance': FieldValue.increment(-(data['amount'] as num).toDouble()),
                }, SetOptions(merge: true));
                
                // 3. Add Finance Transaction Record
                final txnRef = FirebaseFirestore.instance.collection('finance_transactions').doc();
                batch.set(txnRef, {
                  'transactionId': txnRef.id,
                  'type': 'app_usage_payment_approved',
                  'driverId': data['driverId'],
                  'amount': data['amount'],
                  'timestamp': FieldValue.serverTimestamp(),
                });
                
                await batch.commit();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Approved!')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return const Center(child: Text("Revenue Overview - Coming Soon"));
  }
}

class FinanceSettingsForm extends StatefulWidget {
  const FinanceSettingsForm({super.key});
  @override
  State<FinanceSettingsForm> createState() => _FinanceSettingsFormState();
}

class _FinanceSettingsFormState extends State<FinanceSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _driverCommissionCtrl = TextEditingController();
  final _appUsageCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _monthlyFeeCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final doc = await FirebaseFirestore.instance.collection('admin_settings').doc('finance').get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _driverCommissionCtrl.text = (data['driverCommissionPercentage'] ?? 10).toString();
        _appUsageCtrl.text = (data['appUsageChargePercentage'] ?? 3).toString();
        _savingsCtrl.text = (data['memberSavingsPercentage'] ?? 7).toString();
        _monthlyFeeCtrl.text = (data['monthlyMembershipFee'] ?? 500).toString();
        _bankNameCtrl.text = data['unionBankName'] ?? '';
        _accountNameCtrl.text = data['unionBankAccountName'] ?? '';
        _accountNumberCtrl.text = data['unionBankAccountNumber'] ?? '';
        _branchCtrl.text = data['unionBankBranch'] ?? '';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('admin_settings').doc('finance').set({
        'driverCommissionPercentage': double.tryParse(_driverCommissionCtrl.text) ?? 10.0,
        'appUsageChargePercentage': double.tryParse(_appUsageCtrl.text) ?? 3.0,
        'memberSavingsPercentage': double.tryParse(_savingsCtrl.text) ?? 7.0,
        'monthlyMembershipFee': double.tryParse(_monthlyFeeCtrl.text) ?? 500.0,
        'unionBankName': _bankNameCtrl.text,
        'unionBankAccountName': _accountNameCtrl.text,
        'unionBankAccountNumber': _accountNumberCtrl.text,
        'unionBankBranch': _branchCtrl.text,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finance Settings Saved successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Commission Rates (%)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField("Total Driver Commission (%)", _driverCommissionCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildField("Union App Usage Charge (%)", _appUsageCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildField("Passenger Savings Reward (%)", _savingsCtrl)),
            ],
          ),
          const SizedBox(height: 32),
          const Text("Monthly Fee & Bank Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField("Monthly Membership Fee (LKR)", _monthlyFeeCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildField("Union Bank Name", _bankNameCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField("Account Name", _accountNameCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildField("Account Number", _accountNumberCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildField("Branch", _branchCtrl)),
            ],
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Settings", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
    );
  }
}

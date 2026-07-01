// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/change_bank_details_provider.dart';

class BankAccountDetailsChangeRequests extends StatefulWidget {
  const BankAccountDetailsChangeRequests({super.key});

  @override
  State<BankAccountDetailsChangeRequests> createState() => _BankAccountDetailsChangeRequestsState();
}

class _BankAccountDetailsChangeRequestsState extends State<BankAccountDetailsChangeRequests> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChangeBankDetailsProvider>(context, listen: false).startListeningToBankRequests();
    });
  }

  // ==========================================================
  // 📝 🎯 SHOW EDIT & APPROVE DIALOG
  // ==========================================================
  void _showEditApproveDialog(BuildContext context, String membershipNo, Map<String, dynamic> data) {
    final holderCtrl = TextEditingController(text: data['accountHolderName'] ?? '');
    final bankCtrl = TextEditingController(text: data['bankName'] ?? '');
    final branchCtrl = TextEditingController(text: data['branchName'] ?? '');
    final accCtrl = TextEditingController(text: data['accountNumber'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text("Review & Approve", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "You can correct any spelling mistakes before approving the bank details.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(controller: holderCtrl, decoration: const InputDecoration(labelText: "Account Holder Name", isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: "Bank Name", isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: branchCtrl, decoration: const InputDecoration(labelText: "Branch Name", isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: accCtrl, decoration: const InputDecoration(labelText: "Account Number", isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);

              // 💡 Edit කරපු අලුත් Data ටික හදාගන්නවා
              Map<String, dynamic> updatedData = {
                'accountHolderName': holderCtrl.text.trim(),
                'bankName': bankCtrl.text.trim(),
                'branchName': branchCtrl.text.trim(),
                'accountNumber': accCtrl.text.trim(),
              };

              _handleApprove(context, membershipNo, updatedData);
            },
            child: const Text("Confirm & Approve"),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ⚠️ 🎯 SHOW REJECT REASON DIALOG (FIXED FOR FLUTTER 3.32+)
  // ==========================================================
  void _showRejectDialog(BuildContext context, String membershipNo) {
    String? selectedReason = "Account name does not match member name";
    final customReasonCtrl = TextEditingController();

    final List<String> rejectReasons = [
      "Account name does not match member name",
      "Invalid account number",
      "Branch details are incorrect",
      "Bank details are incomplete",
      "Other"
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text("Reject Request", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Please select a reason for rejection:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),

                    // 💡 අලුත් RadioGroup Widget එක පාවිච්චි කරලා තියෙන්නේ මෙතනයි
                    RadioGroup<String>(
                      groupValue: selectedReason,
                      onChanged: (val) {
                        setState(() { selectedReason = val; });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: rejectReasons.map((reason) => RadioListTile<String>(
                          title: Text(reason, style: const TextStyle(fontSize: 13)),
                          value: reason,
                          // ❌ මෙතනින් groupValue සහ onChanged අයින් කළා (Deprecation Fix)
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: Colors.redAccent,
                        )).toList(),
                      ),
                    ),

                    if (selectedReason == "Other")
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: customReasonCtrl,
                          decoration: const InputDecoration(
                            hintText: "Type custom reason here...",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    String finalReason = selectedReason == "Other" ? customReasonCtrl.text.trim() : selectedReason!;

                    if (finalReason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a reason!")));
                      return;
                    }

                    Navigator.pop(ctx);
                    _handleReject(context, membershipNo, finalReason);
                  },
                  child: const Text("Confirm Reject"),
                ),
              ],
            );
          }
      ),
    );
  }

  // ==========================================================
  // ✅ 🎯 APPROVE LOGIC (VIA PROVIDER)
  // ==========================================================
  void _handleApprove(BuildContext context, String membershipNo, Map<String, dynamic> data) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<ChangeBankDetailsProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );

    bool success = await provider.approveBankRequest(membershipNo, data);

    if (!context.mounted) return;
    Navigator.pop(context);

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Bank Details Approved Successfully! ✅"), backgroundColor: Colors.teal),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Approval Failed! ❌"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ==========================================================
  // ❌ 🎯 REJECT LOGIC (VIA PROVIDER)
  // ==========================================================
  void _handleReject(BuildContext context, String membershipNo, String reason) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<ChangeBankDetailsProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
    );

    bool success = await provider.rejectBankRequest(membershipNo, reason);

    if (!context.mounted) return;
    Navigator.pop(context);

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Bank Update Request Rejected! ❌"), backgroundColor: Colors.redAccent),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Rejection Failed! ❌"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        title: const Text(
          "Bank Account Updates",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<ChangeBankDetailsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (provider.pendingRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_rounded, size: 80, color: Colors.teal.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    "No Pending Bank Updates!",
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingRequests.length,
            itemBuilder: (context, index) {
              final data = provider.pendingRequests[index];
              final String membershipNo = data['membershipNo'] ?? 'Unknown';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
                            child: const Icon(Icons.account_balance, color: Colors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Member: $membershipNo",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const Text(
                                  "New Bank Details Requested",
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(),
                      ),
                      _buildDetailRow("Account Holder", data['accountHolderName'] ?? 'N/A'),
                      _buildDetailRow("Bank Name", data['bankName'] ?? 'N/A'),
                      _buildDetailRow("Branch Name", data['branchName'] ?? 'N/A'),
                      _buildDetailRow("Account Number", data['accountNumber'] ?? 'N/A', isHighlight: true),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showRejectDialog(context, membershipNo),
                              child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: () => _showEditApproveDialog(context, membershipNo, data),
                              child: const Text("Review & Approve", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Text(":", style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
                fontSize: isHighlight ? 14 : 13,
                color: isHighlight ? Colors.teal.shade800 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
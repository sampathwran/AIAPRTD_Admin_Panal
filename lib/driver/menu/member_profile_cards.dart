import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/profile_image_provider.dart';

// =============================================================================
// 🧩 MODULAR SECTIONS (CARDS)
// =============================================================================

// 🟢 1. Profile Header Card
class ProfileHeaderCard extends StatelessWidget {
  final Map<String, dynamic> memberData;
  const ProfileHeaderCard({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final bool isApproved = memberData['isApproved'] == true;
    final String currentStatus = (memberData['status'] ?? 'pending').toString().toUpperCase();
    final String membershipNo = memberData['membershipNo']?.toString() ?? '-';

    final imageProvider = Provider.of<ProfileImageProvider>(context);
    String imageUrl = imageProvider.getImageUrl(membershipNo);

    if (imageUrl.isEmpty) {
      imageUrl = memberData['profileImage']?.toString() ?? '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error_outline, size: 36, color: Colors.redAccent);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                      child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))
                      )
                  );
                },
              )
                  : const Icon(Icons.person_rounded, size: 36, color: Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memberData['fullName'] ?? 'Unknown Member', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(memberData['user_email'] ?? 'No email provided', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusBadge(currentStatus, currentStatus == 'ACTIVE' ? Colors.green : Colors.amber),
                    const SizedBox(width: 8),
                    _statusBadge(isApproved ? 'APPROVED' : 'PENDING APPROVAL', isApproved ? Colors.blue : Colors.red),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// 🟢 2. Personal Details Card
class PersonalDetailsCard extends StatefulWidget {
  final Map<String, dynamic> memberData;
  const PersonalDetailsCard({super.key, required this.memberData});

  @override
  State<PersonalDetailsCard> createState() => _PersonalDetailsCardState();
}

class _PersonalDetailsCardState extends State<PersonalDetailsCard> {
  String? _currentJoinDate;

  @override
  void initState() {
    super.initState();
    _currentJoinDate = widget.memberData['joinDate']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final String docId = widget.memberData['docId'] ?? widget.memberData['membershipNo'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.badge_rounded, 'Personal Details'),
          const Divider(height: 16),
          _editableInfoTile(context, 'System Join Date', _currentJoinDate, docId),
          _infoTile('First Name', widget.memberData['firstName']),
          _infoTile('Last Name', widget.memberData['lastName']),
          _infoTile('Membership No', widget.memberData['membershipNo']),
          _infoTile('NIC Number', widget.memberData['nic']),
          _infoTile('Mobile Connection', widget.memberData['mobile']),
          _infoTile('Gender', widget.memberData['gender']),
          _infoTile('Date of Birth', widget.memberData['dob']),
          _infoTile('Religion Origin', widget.memberData['religion']),
          _infoTile('Residential Address', widget.memberData['address']),
        ],
      ),
    );
  }

  Widget _editableInfoTile(BuildContext context, String label, dynamic value, String docId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 11))),
          Expanded(
            child: Text(value?.toString() ?? 'Not Set', style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          InkWell(
            onTap: () => _updateJoinDate(context, docId, value?.toString()),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.edit_calendar_rounded, size: 14, color: Color(0xFF1E3A8A)),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _updateJoinDate(BuildContext context, String docId, String? currentDateStr) async {
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Member Document ID not found!')));
      return;
    }

    DateTime initialDate = DateTime.now();
    if (currentDateStr != null && currentDateStr.isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentDateStr);
      } catch (e) {
        // Parse error fallback to today
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

      try {
        await FirebaseFirestore.instance.collection('member').doc(docId).update({
          'joinDate': formattedDate,
        });

        setState(() {
          _currentJoinDate = formattedDate;
          widget.memberData['joinDate'] = formattedDate;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text('Join Date updated successfully!')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Failed to update date: $error')),
          );
        }
      }
    }
  }
}

// 🟢 3. Vehicle Info Card
class VehicleInfoCard extends StatelessWidget {
  final Map<String, dynamic> memberData;
  const VehicleInfoCard({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final String membershipNo = memberData['membershipNo']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.local_taxi_rounded, 'Vehicle & System Info'),
          const Divider(height: 16),

          if (membershipNo.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Membership Number is missing. Cannot load vehicle data.', style: TextStyle(color: Colors.red, fontSize: 11)),
            )
          else
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('vehicles').doc(membershipNo).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))),
                    ),
                  );
                }

                String vehicleCategory = '-';
                String makeAndModel = '-';
                String plateNumber = '-';
                String wpId = memberData['wp_id']?.toString() ?? '-';
                String platform = memberData['platform']?.toString() ?? 'AIAPRTD';
                String rating = memberData['rating']?.toString() ?? '0.0';

                String lastSync = '-';
                if (memberData['lastLocationUpdate'] != null) {
                  if (memberData['lastLocationUpdate'] is Timestamp) {
                    DateTime dt = (memberData['lastLocationUpdate'] as Timestamp).toDate();
                    lastSync = "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour}:${dt.minute}";
                  } else {
                    lastSync = memberData['lastLocationUpdate'].toString();
                  }
                }

                if (snapshot.hasData && snapshot.data!.exists) {
                  final vehicleDoc = snapshot.data!.data() as Map<String, dynamic>;
                  vehicleCategory = vehicleDoc['selectedCategory']?.toString() ?? '-';

                  final details = vehicleDoc['details'] as Map<String, dynamic>? ?? {};
                  String brand = details['brand']?.toString() ?? '';
                  String model = details['model']?.toString() ?? '';
                  makeAndModel = '$brand $model'.trim();
                  if (makeAndModel.isEmpty) makeAndModel = '-';

                  final docs = vehicleDoc['documents'] as List<dynamic>? ?? [];
                  for (var docItem in docs) {
                    if (docItem is Map<String, dynamic>) {
                      final reviewData = docItem['reviewData'] as Map<String, dynamic>?;
                      if (reviewData != null && reviewData.containsKey('Plate Number')) {
                        plateNumber = reviewData['Plate Number'].toString();
                        break;
                      }
                    }
                  }
                }

                return Column(
                  children: [
                    _infoTile('Vehicle Category', vehicleCategory),
                    _infoTile('Vehicle Registration', plateNumber),
                    _infoTile('Primary Category', makeAndModel),
                    _infoTile('Western Province ID', wpId),
                    _infoTile('Operating Platform', platform),
                    _infoTile('Performance Rating', '⭐ $rating Stars'),
                    _infoTile('Last Live Sync', lastSync),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// 🟢 4. Bank Details Card (💡 FIXED: Fetching directly from Firebase member document)
class BankDetailsCard extends StatelessWidget {
  final Map<String, dynamic> memberData;
  const BankDetailsCard({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final String docId = memberData['docId'] ?? memberData['membershipNo'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.account_balance_rounded, 'Bank Account Details'),
          const Divider(height: 16),

          if (docId.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Invalid Member ID', style: TextStyle(color: Colors.red, fontSize: 11)),
            )
          else
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('member').doc(docId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))),
                    ),
                  );
                }

                String bankName = '-';
                String accHolder = '-';
                String accNumber = '-';
                String branchName = '-';
                String branchCode = '-';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  bankName = data['bankName']?.toString() ?? memberData['bankName']?.toString() ?? '-';
                  accHolder = data['accountHolderName']?.toString() ?? memberData['accountHolderName']?.toString() ?? '-';
                  accNumber = data['accountNumber']?.toString() ?? memberData['accountNumber']?.toString() ?? '-';
                  branchName = data['branchName']?.toString() ?? memberData['branchName']?.toString() ?? '-';
                  branchCode = data['branchCode']?.toString() ?? memberData['branchCode']?.toString() ?? '-';
                }

                return Column(
                  children: [
                    _infoTile('Bank Name', bankName),
                    _infoTile('Account Holder', accHolder),
                    _infoTile('Account Number', accNumber),
                    _infoTile('Branch Name', branchName),
                    _infoTile('Branch Code', branchCode),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// 🟢 5. Payment History Card
class PaymentHistoryCard extends StatelessWidget {
  final Map<String, dynamic> memberData;
  const PaymentHistoryCard({super.key, required this.memberData});

  @override
  Widget build(BuildContext context) {
    final String membershipNo = memberData['membershipNo']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.history_toggle_off_rounded, 'Payment & Fee Transactions'),
          const Divider(height: 16),

          if (membershipNo.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Invalid Membership ID.', style: TextStyle(color: Colors.grey, fontSize: 12))),
            )
          else
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('payments').doc(membershipNo).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))),
                    ),
                  );
                }

                List paymentHistory = [];

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  paymentHistory = data['payment_history'] as List? ?? [];
                }

                if (paymentHistory.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No payment log transitions available for this profile.', style: TextStyle(color: Colors.grey, fontSize: 12))),
                  );
                }

                return Column(
                  children: paymentHistory.map((p) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF1F5F9))
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 16),
                        ),
                        title: Text('${p['month']} - ${p['reason']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text('Date Log: ${p['date']} | Mode: ${p['type']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: Text('Rs. ${p['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.green)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 🛠️ REUSABLE HELPER WIDGETS
// =============================================================================

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE2E8F0)),
  );
}

Widget _buildSectionTitle(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, color: const Color(0xFF1E3A8A), size: 16),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
    ],
  );
}

Widget _infoTile(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 11))),
        Expanded(child: SelectableText(value?.toString() ?? '-', style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w500))),
      ],
    ),
  );
}
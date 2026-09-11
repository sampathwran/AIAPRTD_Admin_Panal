import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDriverProfileDialog extends StatefulWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onUpdated;

  const EditDriverProfileDialog({
    super.key,
    required this.driver,
    required this.onUpdated,
  });

  @override
  State<EditDriverProfileDialog> createState() =>
      _EditDriverProfileDialogState();
}

class _EditDriverProfileDialogState extends State<EditDriverProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for Basic Information
  late TextEditingController _membershipNoCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _joinDateCtrl;
  late TextEditingController _nicCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _religionCtrl;
  late TextEditingController _addressCtrl;

  // Controllers for Account & App Details
  late TextEditingController _profileStatusCtrl;
  late TextEditingController _onlineStatusCtrl;
  late TextEditingController _totalAcceptedCtrl;
  late TextEditingController _ratingCtrl;
  late TextEditingController _kycApprovalCtrl;
  late TextEditingController _faceKycCtrl;
  late TextEditingController _bankUpdateCtrl;
  late TextEditingController _authUidCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;

    _membershipNoCtrl = TextEditingController(
      text: d['membershipNo']?.toString() ?? '',
    );
    _fullNameCtrl = TextEditingController(
      text: d['fullName']?.toString() ?? d['firstName']?.toString() ?? '',
    );

    _joinDateCtrl = TextEditingController(
      text: d['joinDate']?.toString() ?? '',
    );
    _nicCtrl = TextEditingController(text: d['nic']?.toString() ?? '');
    _mobileCtrl = TextEditingController(text: d['mobile']?.toString() ?? '');
    _emailCtrl = TextEditingController(
      text: d['user_email']?.toString() ?? d['email']?.toString() ?? '',
    );
    _genderCtrl = TextEditingController(text: d['gender']?.toString() ?? '');
    _dobCtrl = TextEditingController(text: d['dob']?.toString() ?? '');
    _religionCtrl = TextEditingController(
      text: d['religion']?.toString() ?? '',
    );
    _addressCtrl = TextEditingController(text: d['address']?.toString() ?? '');

    _profileStatusCtrl = TextEditingController(
      text: d['profile_status']?.toString() ?? d['status']?.toString() ?? '',
    );
    _onlineStatusCtrl = TextEditingController(
      text: d['onlineStatus']?.toString() ?? '',
    );
    _totalAcceptedCtrl = TextEditingController(
      text: d['totalAcceptedCount']?.toString() ?? '',
    );
    _ratingCtrl = TextEditingController(text: d['rating']?.toString() ?? '');
    _kycApprovalCtrl = TextEditingController(
      text: d['kycApprovalStatus']?.toString() ?? '',
    );
    _faceKycCtrl = TextEditingController(
      text: d['faceKycStatus']?.toString() ?? '',
    );
    _bankUpdateCtrl = TextEditingController(
      text: d['bankUpdateStatus']?.toString() ?? '',
    );
    _authUidCtrl = TextEditingController(
      text: d['auth_uid']?.toString() ?? d['uid']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _membershipNoCtrl.dispose();
    _fullNameCtrl.dispose();
    _joinDateCtrl.dispose();
    _nicCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _genderCtrl.dispose();
    _dobCtrl.dispose();
    _religionCtrl.dispose();
    _addressCtrl.dispose();

    _profileStatusCtrl.dispose();
    _onlineStatusCtrl.dispose();
    _totalAcceptedCtrl.dispose();
    _ratingCtrl.dispose();
    _kycApprovalCtrl.dispose();
    _faceKycCtrl.dispose();
    _bankUpdateCtrl.dispose();
    _authUidCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final docId =
          widget.driver['doc_id'] ??
          widget.driver['membershipNo'] ??
          widget.driver['uid'];
      if (docId == null || docId.toString().isEmpty) {
        throw Exception('Cannot find document ID for this member');
      }

      final updates = {
        'membershipNo': _membershipNoCtrl.text.trim(),
        'fullName': _fullNameCtrl.text.trim(),
        'firstName': _fullNameCtrl.text
            .trim(), // Assuming we update both for safety
        'joinDate': _joinDateCtrl.text.trim(),
        'nic': _nicCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'user_email': _emailCtrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'dob': _dobCtrl.text.trim(),
        'religion': _religionCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'status': _profileStatusCtrl.text.trim(),
        'profile_status': _profileStatusCtrl.text.trim(),
        'onlineStatus': _onlineStatusCtrl.text.trim(),
        'totalAcceptedCount':
            int.tryParse(_totalAcceptedCtrl.text.trim()) ??
            _totalAcceptedCtrl.text.trim(),
        'rating':
            double.tryParse(_ratingCtrl.text.trim()) ?? _ratingCtrl.text.trim(),
        'kycApprovalStatus': _kycApprovalCtrl.text.trim(),
        'faceKycStatus': _faceKycCtrl.text.trim(),
        'bankUpdateStatus': _bankUpdateCtrl.text.trim(),
        'auth_uid': _authUidCtrl.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('member')
          .doc(docId.toString())
          .update(updates);

      // Update in vehicles collection for joinDate if applicable
      try {
        final membershipNo = widget.driver['membershipNo'];
        if (membershipNo != null &&
            membershipNo.toString().isNotEmpty &&
            membershipNo != '-') {
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(membershipNo.toString())
              .set({
                'joinDate': _joinDateCtrl.text.trim(),
              }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint(
          'Warning: Could not update vehicles collection joinDate: $e',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Member Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionHeader('Basic Information'),
                    _buildTextField('Membership Number', _membershipNoCtrl),
                    _buildTextField('Full Name', _fullNameCtrl),
                    _buildTextField('Join Date', _joinDateCtrl),
                    _buildTextField('NIC Number', _nicCtrl),
                    _buildTextField('Mobile', _mobileCtrl),
                    _buildTextField('Email', _emailCtrl),
                    _buildTextField('Gender', _genderCtrl),
                    _buildTextField('Date of Birth', _dobCtrl),
                    _buildTextField('Religion', _religionCtrl),
                    _buildTextField('Address', _addressCtrl),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Account & App Details'),
                    _buildTextField('Profile Status', _profileStatusCtrl),
                    _buildTextField('Online Status', _onlineStatusCtrl),
                    _buildTextField('Total Accepted', _totalAcceptedCtrl),
                    _buildTextField('Rating', _ratingCtrl),
                    _buildTextField('KYC Approval', _kycApprovalCtrl),
                    _buildTextField('Face KYC Status', _faceKycCtrl),
                    _buildTextField('Bank Update', _bankUpdateCtrl),
                    _buildTextField('Auth UID', _authUidCtrl),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveChanges,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

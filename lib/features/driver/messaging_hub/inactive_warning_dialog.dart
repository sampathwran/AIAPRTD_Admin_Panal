import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';
import 'package:intl/intl.dart';

Future<bool?> showInactiveWarningDialog(BuildContext context, Map<String, dynamic> driverData) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => _InactiveWarningDialog(driverData: driverData),
  );
}

class _InactiveWarningDialog extends StatefulWidget {
  final Map<String, dynamic> driverData;

  const _InactiveWarningDialog({required this.driverData});

  @override
  State<_InactiveWarningDialog> createState() => _InactiveWarningDialogState();
}

class _InactiveWarningDialogState extends State<_InactiveWarningDialog> {
  bool _isSaving = false;

  String _getMemberFullName() {
    String fullName = widget.driverData['fullName']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    String fName = widget.driverData['first_name']?.toString().trim() ?? widget.driverData['firstName']?.toString().trim() ?? '';
    String lName = widget.driverData['last_name']?.toString().trim() ?? widget.driverData['lastName']?.toString().trim() ?? '';
    if (fName.isNotEmpty || lName.isNotEmpty) return '$fName $lName'.trim();
    return 'Unknown';
  }

  String _translateReason(String englishReason) {
    final reason = englishReason.toLowerCase();
    if (reason.contains('fee')) {
      return 'සාමාජික ගාස්තු ගෙවා නොමැති වීම';
    }
    if (reason.contains('profile image')) {
      return 'පැතිකඩ ඡායාරූපය (Profile Image) ඇතුළත් කර නොමැති වීම';
    }
    if (reason.contains('vehicle documents')) {
      return 'වාහන ලියකියවිලි සම්පූර්ණ කර නොමැති වීම';
    }
    if (reason.contains('kyc') || reason.contains('face') || reason.contains('personal') || reason.contains('one-time registration')) {
      return 'පුද්ගලික විස්තර සහ මුහුණේ ඡායාරූපය (Live Face verification) තහවුරු කර නොමැති වීම';
    }
    if (reason.contains('pending admin approval')) {
      return 'තොරතුරු Admin විසින් අනුමත කිරීමට තිබීම';
    }
    if (reason.contains('rejected')) {
      return 'ඔබගේ ලියකියවිලි හෝ තොරතුරු ප්‍රතික්ෂේප වී තිබීම';
    }
    if (reason.contains('expired')) {
      return 'ලියකියවිලි වල කල් ඉකුත් වී තිබීම';
    }
    if (reason.contains('revenue license')) return 'ආදායම් බලපත්‍රය (Revenue License) යාවත්කාලීන කර නොමැති වීම';
    if (reason.contains('insurance')) return 'රක්ෂණ සහතිකය (Insurance) යාවත්කාලීන කර නොමැති වීම';
    if (reason.contains('registration')) return 'වාහන ලියාපදිංචි සහතිකය යාවත්කාලීන කර නොමැති වීම';
    if (reason.contains('driving license')) return 'රියදුරු බලපත්‍රය යාවත්කාලීන කර නොමැති වීම';
    
    return 'ඔබගේ තොරතුරු සම්පූර්ණ කර නොමැති වීම';
  }

  String _previewMessage = 'Loading preview...';

  @override
  void initState() {
    super.initState();
    _loadPreviewMessage();
  }

  Future<void> _loadPreviewMessage() async {
    final status = calculateMemberStatus(widget.driverData);
    if (status['isActive'] == true) {
      if (mounted) {
        setState(() {
          _previewMessage = 'This member is already active. No warning needed.';
        });
      }
      return;
    }

    final String rawReasons = status['reason'] ?? '';
    final List<String> reasonsList = rawReasons.split(RegExp(r' \? | \? | \| ')).where((r) => r.trim().isNotEmpty).toList();
    
    List<String> sinhalaReasons = [];
    if (reasonsList.isEmpty || reasonsList.length == 1) {
       if (rawReasons.toLowerCase().contains('fee')) sinhalaReasons.add('- ${_translateReason('fee not paid')}');
       if (rawReasons.toLowerCase().contains('profile image')) sinhalaReasons.add('- ${_translateReason('profile image is not uploaded')}');
       if (rawReasons.toLowerCase().contains('kyc') || rawReasons.toLowerCase().contains('face') || rawReasons.toLowerCase().contains('personal')) sinhalaReasons.add('- ${_translateReason('kyc')}');
       if (rawReasons.toLowerCase().contains('vehicle') || rawReasons.toLowerCase().contains('revenue') || rawReasons.toLowerCase().contains('insurance')) sinhalaReasons.add('- ${_translateReason('vehicle documents not found')}');
       if (sinhalaReasons.isEmpty) sinhalaReasons.add('- ${_translateReason('other')}');
    } else {
       sinhalaReasons = reasonsList.map((r) => '- ${_translateReason(r)}').toSet().toList();
    }
    sinhalaReasons = sinhalaReasons.toSet().toList();
    
    String fName = widget.driverData['first_name']?.toString().trim() ?? widget.driverData['firstName']?.toString().trim() ?? '';
    String lName = widget.driverData['last_name']?.toString().trim() ?? widget.driverData['lastName']?.toString().trim() ?? '';
    String fullName = widget.driverData['fullName']?.toString().trim() ?? '$fName $lName'.trim();
    String membershipNo = widget.driverData['membershipNo']?.toString() ?? 'N/A';
    String reasonsText = sinhalaReasons.join('\n');

    String templateContent = '''ආයුබෝවන් {full_name},

ඔබගේ සාමාජික අංකය වන්නේ {membership_no} ය.

කරුණාකර ඔබගේ පහත සඳහන් විස්තර සම්පූර්ණ කර ගිණුම සක්‍රීය කර ගැනීමට කාරුණික වන්න:
{inactive_reasons}

ඇප් එක ඩවුන්ලෝඩ් කරගැනීමට:
https://play.google.com/store/apps/details?id=lk.aiaprtd.member&pcampaignid=web_share

ඔබ සංගමයේ සාමාජිකත්වයෙන් සම්පූර්ණයෙන්ම ඉවත් වන්නේ නම් ඒ බව දැනුම් දීමට කාරුණික වන්න. එසේ නොමැති නම්, මෙම පණිවිඩය ලැබුණු මොහොතේ සිට ඉදිරියට මාස 3කින් පසු ඔබගේ AIAPRTD සාමාජිකත්වය ස්වයංක්‍රීයව අහෝසි වනු ඇත.''';

    try {
      final query = await FirebaseFirestore.instance.collection('whatsapp_templates').where('title', isEqualTo: 'Inactive Warning').limit(1).get();
      if (query.docs.isNotEmpty) {
        templateContent = query.docs.first.data()['content'] ?? templateContent;
      }
    } catch (e) {
      // Use fallback
    }

    String finalMessage = templateContent
        .replaceAll('{first_name}', fName)
        .replaceAll('{last_name}', lName)
        .replaceAll('{full_name}', fullName)
        .replaceAll('{membership_no}', membershipNo)
        .replaceAll('{inactive_reasons}', reasonsText);

    if (mounted) {
      setState(() {
        _previewMessage = finalMessage;
      });
    }
  }

  Future<void> _sendWarning() async {
    final status = calculateMemberStatus(widget.driverData);
    if (status['isActive'] == true) return;

    setState(() => _isSaving = true);

    try {
      final String docId = widget.driverData['doc_id']?.toString() ?? 
                           widget.driverData['membershipNo']?.toString() ?? 
                           widget.driverData['uid']?.toString() ?? '';
      final now = FieldValue.serverTimestamp();
      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('member').doc(docId).update({
          'cancellationWarningSentAt': now,
        });
        widget.driverData['cancellationWarningSentAt'] = Timestamp.now(); // update local map
      }

      String finalMessage = _previewMessage;
      String rawPhone = widget.driverData['mobile']?.toString() ?? widget.driverData['phone']?.toString() ?? '';
      String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '94${cleanPhone.substring(1)}';
      } else if (cleanPhone.length == 9) {
        cleanPhone = '94$cleanPhone';
      }

      if (cleanPhone.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid mobile number found.')));
      } else {
        final String urlStr = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(finalMessage)}';
        final Uri url = Uri.parse(urlStr);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = calculateMemberStatus(widget.driverData);
    final bool isActive = status['isActive'] == true;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Send Inactive Warning'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: isActive 
        ? const Text('This member is Active. You do not need to send an inactive warning.')
        : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To: ${_getMemberFullName()} (${widget.driverData['mobile']})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('This action will start a 3-month cancellation countdown on their profile.', style: TextStyle(color: Colors.red, fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Message Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _previewMessage,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!isActive)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
            onPressed: _isSaving ? null : _sendWarning,
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 16),
            label: const Text('Send Warning & Start Countdown'),
          ),
      ],
    );
  }
}

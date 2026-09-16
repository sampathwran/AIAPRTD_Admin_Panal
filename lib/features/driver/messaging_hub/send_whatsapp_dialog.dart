import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/messaging_hub/whatsapp_template_service.dart';

Future<void> showSendWhatsAppDialog(BuildContext context, Map<String, dynamic> driverData) async {
  final service = WhatsAppTemplateService();
  await service.initializeDefaultsIfEmpty();
  final templates = await service.getTemplates();
  
  if (templates.isEmpty) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No WhatsApp templates found.')));
    return;
  }

  showDialog(
    context: context,
    builder: (context) => _SendWhatsAppDialog(driverData: driverData, templates: templates),
  );
}

class _SendWhatsAppDialog extends StatefulWidget {
  final Map<String, dynamic> driverData;
  final List<WhatsAppTemplate> templates;

  const _SendWhatsAppDialog({required this.driverData, required this.templates});

  @override
  State<_SendWhatsAppDialog> createState() => _SendWhatsAppDialogState();
}

class _SendWhatsAppDialogState extends State<_SendWhatsAppDialog> {
  late WhatsAppTemplate _selectedTemplate;
  final TextEditingController _customMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.templates.first;
  }

  String _getMemberFullName(Map<String, dynamic> member) {
    String fullName = member['fullName']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    String fName = member['first_name']?.toString().trim() ?? member['firstName']?.toString().trim() ?? '';
    String lName = member['last_name']?.toString().trim() ?? member['lastName']?.toString().trim() ?? '';
    if (fName.isNotEmpty || lName.isNotEmpty) return '$fName $lName'.trim();
    return 'Unknown';
  }

  String _generateFinalMessage() {
    String fName = widget.driverData['first_name']?.toString().trim() ?? widget.driverData['firstName']?.toString().trim() ?? '';
    String lName = widget.driverData['last_name']?.toString().trim() ?? widget.driverData['lastName']?.toString().trim() ?? '';
    String fullName = widget.driverData['fullName']?.toString().trim() ?? '$fName $lName'.trim();
    String membershipNo = widget.driverData['membershipNo']?.toString() ?? 'N/A';
    String dob = widget.driverData['dob']?.toString() ?? '-';
    String nic = widget.driverData['nic']?.toString() ?? '-';
    String mobile = widget.driverData['mobile']?.toString() ?? '-';
    String gender = widget.driverData['gender']?.toString() ?? '-';
    String address = widget.driverData['address']?.toString() ?? '-';

    String message = _selectedTemplate.content;
    message = message.replaceAll('{first_name}', fName);
    message = message.replaceAll('{last_name}', lName);
    message = message.replaceAll('{full_name}', fullName);
    message = message.replaceAll('{membership_no}', membershipNo);
    message = message.replaceAll('{dob}', dob);
    message = message.replaceAll('{nic}', nic);
    message = message.replaceAll('{mobile}', mobile);
    message = message.replaceAll('{gender}', gender);
    message = message.replaceAll('{address}', address);

    if (_selectedTemplate.isCustomMode) {
      String customText = _customMessageController.text.trim();
      message = message.replaceAll('[ඔබගේ පණිවිඩය මෙතන ටයිප් කරන්න]', customText);
      message = message.replaceAll('[Your Message Here]', customText);
    }

    return message;
  }

  Future<void> _sendWhatsAppMessage() async {
    String finalMessage = _generateFinalMessage();
    String rawPhone = widget.driverData['mobile']?.toString() ?? widget.driverData['phone']?.toString() ?? '';
    
    // Clean phone number (remove spaces, +, 0 at start)
    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '94${cleanPhone.substring(1)}';
    } else if (cleanPhone.length == 9) {
      cleanPhone = '94$cleanPhone'; // assuming 7XXXXXXXX
    }

    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid mobile number found for this member.')));
      return;
    }

    final String urlStr = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(finalMessage)}';
    final Uri url = Uri.parse(urlStr);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.message_rounded, color: Colors.green.shade600),
          const SizedBox(width: 8),
          const Text('Send WhatsApp Message'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To: ${_getMemberFullName(widget.driverData)} (${widget.driverData['mobile']})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('Select Template:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<WhatsAppTemplate>(
                value: _selectedTemplate,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: widget.templates.map((t) => DropdownMenuItem(value: t, child: Text(t.title))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTemplate = val);
                },
              ),
              if (_selectedTemplate.isCustomMode) ...[
                const SizedBox(height: 16),
                const Text('Custom Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: _customMessageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Type your message here...',
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Message Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _generateFinalMessage(),
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
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
          onPressed: _sendWhatsAppMessage,
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Send via WhatsApp'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/messaging_hub/whatsapp_template_service.dart';

class MessagingHubPanel extends StatefulWidget {
  const MessagingHubPanel({super.key});

  @override
  State<MessagingHubPanel> createState() => _MessagingHubPanelState();
}

class _MessagingHubPanelState extends State<MessagingHubPanel> {
  final WhatsAppTemplateService _service = WhatsAppTemplateService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  Future<void> _initDefaults() async {
    await _service.initializeDefaultsIfEmpty();
    setState(() {
      _isLoading = false;
    });
  }

  void _showTemplateDialog({WhatsAppTemplate? template}) {
    final titleController = TextEditingController(text: template?.title ?? '');
    final contentController = TextEditingController(text: template?.content ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(template == null ? 'Add New Template' : 'Edit Template'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Placeholders:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('{first_name}, {last_name}, {full_name}, {membership_no}, {nic}, {dob}, {mobile}, {gender}, {address}', style: TextStyle(color: Colors.blue)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Template Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message Content',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                onPressed: isSaving ? null : () async {
                  if (titleController.text.isEmpty || contentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                    return;
                  }
                  setState(() => isSaving = true);
                  if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                    if (template == null) {
                      await _service.saveTemplate(WhatsAppTemplate(
                        id: '', 
                        title: titleController.text, 
                        content: contentController.text
                      ));
                    } else {
                      await _service.updateTemplate(WhatsAppTemplate(
                        id: template.id, 
                        title: titleController.text, 
                        content: contentController.text,
                        isCustomMode: template.isCustomMode
                      ));
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteTemplate(WhatsAppTemplate template) {
    if (template.isCustomMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete the default Custom Message template.')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete ""?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _service.deleteTemplate(template.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('WhatsApp Templates Hub', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showTemplateDialog(),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('New Template', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<WhatsAppTemplate>>(
              stream: _service.getTemplatesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading templates'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final templates = snapshot.data!;
                if (templates.isEmpty) return const Center(child: Text('No templates found.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.message_rounded, color: Colors.green.shade600, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      template.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (template.isCustomMode)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                                        child: const Text('Custom Template', style: TextStyle(fontSize: 10, color: Colors.deepOrange)),
                                      )
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showTemplateDialog(template: template),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteTemplate(template),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                template.content,
                                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                              ),
                            ),
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
}

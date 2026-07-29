import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

class AddEditBenefitDialog extends StatefulWidget {
  final DocumentSnapshot? benefitDoc;

  const AddEditBenefitDialog({
    super.key,
    this.benefitDoc,
  });

  @override
  State<AddEditBenefitDialog> createState() => _AddEditBenefitDialogState();
}

class _AddEditBenefitDialogState extends State<AddEditBenefitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  final _iconUrlController = TextEditingController();
  
  bool _isGlobal = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.benefitDoc != null) {
      final data = widget.benefitDoc!.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _iconController.text = data['icon'] ?? 'star';
      _iconUrlController.text = data['iconUrl'] ?? '';
      _isGlobal = data['isGlobal'] ?? true;
    } else {
      _iconController.text = 'star'; // Default icon
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveBenefit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'icon': _iconController.text.trim(),
        'iconUrl': _iconUrlController.text.trim(),
        'isGlobal': _isGlobal,
      };

      if (widget.benefitDoc == null) {
        // Add new
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('member_benefits').add(data);
      } else {
        // Update existing
        await widget.benefitDoc!.reference.update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.benefitDoc == null ? 'Benefit created successfully' : 'Benefit updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving benefit: $e'),
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
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.benefitDoc == null ? 'Add New Benefit' : 'Edit Benefit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Benefit Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(
                  labelText: 'Material Icon Name (e.g. star, local_taxi)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  helperText: 'Used as fallback if no Image URL is provided.',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iconUrlController,
                decoration: const InputDecoration(
                  labelText: 'Color Icon Image URL (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  helperText: 'Paste a link to a PNG/SVG image for a full-color icon.',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Global Benefit (Available to all)'),
                subtitle: const Text('If off, this benefit must be manually granted to specific members.'),
                value: _isGlobal,
                onChanged: (val) => setState(() => _isGlobal = val),
                activeColor: AdminColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveBenefit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.benefitDoc == null ? 'Create' : 'Save Changes'),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

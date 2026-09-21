import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/admin_image_cropper_dialog.dart';

class AdminProfileImageUpdater extends StatefulWidget {
  final Map<String, dynamic> driver;
  final String initials;

  const AdminProfileImageUpdater({
    Key? key,
    required this.driver,
    required this.initials,
  }) : super(key: key);

  @override
  State<AdminProfileImageUpdater> createState() => _AdminProfileImageUpdaterState();
}

class _AdminProfileImageUpdaterState extends State<AdminProfileImageUpdater> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    // 1. Pick file using file_picker to support jpeg, jpg, png robustly
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
      return;
    }

    final Uint8List pickedBytes = result.files.first.bytes!;

    // 2. Open Cropper Dialog
    final Uint8List? croppedBytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminImageCropperDialog(imageBytes: pickedBytes),
    );

    if (croppedBytes == null) return; // User canceled crop

    setState(() {
      _isUploading = true;
    });

    try {
      final String memNo = widget.driver['membershipNo'] ?? widget.driver['doc_id'] ?? 'unknown';
      final String docId = widget.driver['doc_id'] ?? memNo;

      // 3. Upload to Firebase Storage
      final String path = 'profile_images/$memNo.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(path);
      
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/png'); // crop returns png bytes
      await ref.putData(croppedBytes, metadata);
      
      final String downloadUrl = await ref.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance.collection('member').doc(docId).update({
        'profileImageUrl': downloadUrl,
        'isProfileImageLocked': true, // Lock the image from member edits
      });

      widget.driver['profileImageUrl'] = downloadUrl;
      widget.driver['isProfileImageLocked'] = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated and locked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _unlockImage() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Profile Image?'),
        content: const Text('This will allow the member to change their profile image again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final String memNo = widget.driver['membershipNo'] ?? widget.driver['doc_id'] ?? 'unknown';
      final String docId = widget.driver['doc_id'] ?? memNo;

      await FirebaseFirestore.instance.collection('member').doc(docId).update({
        'isProfileImageLocked': false,
      });

      widget.driver['isProfileImageLocked'] = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image unlocked.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlock image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.driver['profileImageUrl'] != null &&
        widget.driver['profileImageUrl'].toString().isNotEmpty;
    final isLocked = widget.driver['isProfileImageLocked'] == true;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade50,
            border: Border.all(
              color: isLocked ? Colors.orange.shade300 : Colors.white, 
              width: 3
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : hasImage
                    ? CachedNetworkImage(
                        imageUrl: widget.driver['profileImageUrl'].toString(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            widget.initials,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.initials,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
          ),
        ),
        // Edit Button
        Positioned(
          bottom: -4,
          right: -4,
          child: InkWell(
            onTap: _isUploading ? null : (isLocked ? _unlockImage : _pickAndUploadImage),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isLocked ? Colors.orange.shade700 : const Color(0xFF1E3A8A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.camera_alt_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

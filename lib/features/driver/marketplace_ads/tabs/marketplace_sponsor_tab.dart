import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MarketplaceSponsorTab extends StatefulWidget {
  const MarketplaceSponsorTab({super.key});

  @override
  State<MarketplaceSponsorTab> createState() => _MarketplaceSponsorTabState();
}

class _MarketplaceSponsorTabState extends State<MarketplaceSponsorTab> {
  dynamic _mediaFile; // can be XFile or CroppedFile
  String _mediaType = 'image'; // 'image' or 'video'
  bool _isLoading = false;

  Future<void> _pickMedia(String type) async {
    final picker = ImagePicker();
    dynamic picked;
    if (type == 'image') {
      picked = await picker.pickImage(source: ImageSource.gallery);
    } else {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    }

    if (picked != null) {
      setState(() {
        _mediaFile = picked;
        _mediaType = type;
      });
    }
  }

  Future<void> _uploadSponsorAd() async {
    if (_mediaFile == null) return;
    setState(() => _isLoading = true);

    try {
      final ext = _mediaType == 'video' ? 'mp4' : 'jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('marketplace_sponsor_ads')
          .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(await _mediaFile!.readAsBytes());
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('marketplace_sponsor_ads')
          .add({
            'type': _mediaType,
            'mediaUrl': url,
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() => _mediaFile = null);
    } catch (e) {
      debugPrint("Error uploading sponsor ad: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteAd(String id) {
    FirebaseFirestore.instance
        .collection('marketplace_sponsor_ads')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: _mediaFile != null
                        ? (_mediaType == 'image'
                              ? (kIsWeb
                                    ? Image.network(
                                        _mediaFile!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_mediaFile!.path),
                                        fit: BoxFit.cover,
                                      ))
                              : const Center(
                                  child: Icon(Icons.videocam, size: 40),
                                ))
                        : const Center(
                            child: Text(
                              "No Media",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text("Select Image Ad"),
                        onPressed: () => _pickMedia('image'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.videocam),
                        label: const Text("Select Video Ad"),
                        onPressed: () => _pickMedia('video'),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 20,
                      ),
                    ),
                    onPressed: _isLoading ? null : _uploadSponsorAd,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Upload Sponsor Ad"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('marketplace_sponsor_ads')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Center(child: Text("No sponsor ads found."));

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isVideo = data['type'] == 'video';
                    final mediaUrl = data['mediaUrl'] ?? '';

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          isVideo
                              ? Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_fill,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Image.network(mediaUrl, fit: BoxFit.cover),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () => _deleteAd(docs[index].id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

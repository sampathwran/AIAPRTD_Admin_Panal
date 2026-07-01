import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_request_provider.dart';

class VehiclePhotosView extends StatelessWidget {
  final Map<String, dynamic> photos;
  final String requestId;

  const VehiclePhotosView({super.key, required this.photos, required this.requestId});

  @override
  Widget build(BuildContext context) {
    // Screen width එක අනුව crossAxisCount එක dynamic කරනවා (Responsive)
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (screenWidth < 600) {
      crossAxisCount = 1; // Mobile වලදී පේළියට 1යි
    } else if (screenWidth < 900) {
      crossAxisCount = 2; // Tablets වලදී පේළියට 2යි
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: screenWidth < 600 ? 1.1 : 0.8, // Screen එක අනුව ratio එක adjust කරනවා
      ),
      itemBuilder: (context, index) {
        final entry = photos.entries.elementAt(index);
        final String label = entry.key;
        final Map<String, dynamic> photoData = entry.value as Map<String, dynamic>;
        final String status = photoData['status'] ?? 'pending';
        final String imageUrl = photoData['url'] ?? '';

        Color statusColor = Colors.orange;
        if (status == 'approved') statusColor = Colors.green;
        if (status == 'rejected') statusColor = Colors.red;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section with Fullscreen Preview Button
              Expanded(
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                      ),
                    ),
                    // Click to Zoom Overlay Button
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showFullImagePreview(context, imageUrl, label),
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                              child: const Icon(Icons.fullscreen_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info & Actions Section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatLabel(label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff1B2735)),
                    ),
                    const SizedBox(height: 8),

                    // Actions Setup
                    status == 'pending'
                        ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.cancel_rounded, size: 14),
                            label: const Text("Reject", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _showRejectDialog(context, label),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 14),
                            label: const Text("Approve", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => Provider.of<VehicleRequestProvider>(context, listen: false)
                                .approveVehiclePhoto(requestId, label),
                          ),
                        ),
                      ],
                    )
                        : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Label එක camelCase හෝ snake_case තිබ්බොත් ලස්සනට සාමාන්‍ය වචන වලට හරවනවා
  String _formatLabel(String key) {
    if (key.isEmpty) return "";
    final result = key.replaceAll(RegExp(r'(_|- )'), ' ');
    return result[0].toUpperCase() + result.substring(1);
  }

  // පින්තූරය ලොකුවට Zoom කරලා බලන්න දාපු Dialog Preview එක
  void _showFullImagePreview(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String label) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Reject ${_formatLabel(label)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: "Reason for rejection",
            hintText: "e.g., Image is blurry",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Provider.of<VehicleRequestProvider>(context, listen: false)
                    .rejectVehiclePhoto(requestId, label, reasonController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm Reject"),
          )
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:crop_image/crop_image.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';

class AdminImageCropperDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const AdminImageCropperDialog({Key? key, required this.imageBytes}) : super(key: key);

  @override
  State<AdminImageCropperDialog> createState() => _AdminImageCropperDialogState();
}

class _AdminImageCropperDialogState extends State<AdminImageCropperDialog> {
  final _controller = CropController(
    aspectRatio: 1.0,
    defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

  bool _isProcessing = false;

  Future<void> _cropAndSubmit() async {
    setState(() => _isProcessing = true);
    try {
      final ui.Image bitmap = await _controller.croppedBitmap();
      final ByteData? byteData = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List croppedBytes = byteData.buffer.asUint8List();
        if (mounted) Navigator.pop(context, croppedBytes);
      } else {
        if (mounted) Navigator.pop(context, null);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Crop Profile Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your mouse wheel to zoom in/out, and click & drag to pan the image.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade900,
                ),
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final double delta = pointerSignal.scrollDelta.dy;
                      // Determine zoom direction
                      double zoomFactor = delta > 0 ? 0.9 : 1.1;
                      
                      // Calculate new rect based on zoom
                      final Rect currentCrop = _controller.crop;
                      
                      // Calculate the center of the crop
                      final double centerX = currentCrop.center.dx;
                      final double centerY = currentCrop.center.dy;
                      
                      // Calculate new width and height
                      double newWidth = currentCrop.width / zoomFactor;
                      double newHeight = currentCrop.height / zoomFactor;
                      
                      // Clamp to 1.0 (max width/height)
                      if (newWidth > 1.0) newWidth = 1.0;
                      if (newHeight > 1.0) newHeight = 1.0;
                      
                      // If it hit the bounds, adjust center if needed, but simple clamping is fine
                      
                      // Calculate new LTRB
                      double left = centerX - (newWidth / 2);
                      double top = centerY - (newHeight / 2);
                      double right = centerX + (newWidth / 2);
                      double bottom = centerY + (newHeight / 2);
                      
                      // Clamp boundaries
                      if (left < 0.0) {
                        right -= left;
                        left = 0.0;
                        if (right > 1.0) right = 1.0;
                      }
                      if (top < 0.0) {
                        bottom -= top;
                        top = 0.0;
                        if (bottom > 1.0) bottom = 1.0;
                      }
                      if (right > 1.0) {
                        left -= (right - 1.0);
                        right = 1.0;
                        if (left < 0.0) left = 0.0;
                      }
                      if (bottom > 1.0) {
                        top -= (bottom - 1.0);
                        bottom = 1.0;
                        if (top < 0.0) top = 0.0;
                      }
                      
                      setState(() {
                        _controller.crop = Rect.fromLTRB(left, top, right, bottom);
                      });
                    }
                  },
                  child: CropImage(
                    controller: _controller,
                    image: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _cropAndSubmit,
                  icon: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text('Submit & Lock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

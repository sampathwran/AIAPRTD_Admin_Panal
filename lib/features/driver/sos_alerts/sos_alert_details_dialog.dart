import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

class SosAlertDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> alertData;

  const SosAlertDetailsDialog({super.key, required this.alertData});

  @override
  State<SosAlertDetailsDialog> createState() => _SosAlertDetailsDialogState();
}

class _SosAlertDetailsDialogState extends State<SosAlertDetailsDialog> {
  GoogleMapController? _mapController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(String url) async {
    if (_isPlaying && _currentlyPlayingUrl == url) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentlyPlayingUrl = null;
      });
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isPlaying = true;
        _currentlyPlayingUrl = url;
      });
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingUrl = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.alertData;
    final bool isActive = data['status'] == 'active';
    
    GeoPoint? startLoc = data['startLocation'];
    GeoPoint? currLoc = data['currentLocation'];
    
    LatLng? initialPos;
    if (currLoc != null) {
      initialPos = LatLng(currLoc.latitude, currLoc.longitude);
    } else if (startLoc != null) {
      initialPos = LatLng(startLoc.latitude, startLoc.longitude);
    }

    Set<Marker> markers = {};
    if (initialPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: initialPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: '${data['memberName']}', snippet: 'Driver Location'),
        )
      );
    }

    List<dynamic> responders = data['responders'] ?? [];
    List<dynamic> audioUrls = data['voiceRecordingUrls'] ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency_share_rounded, color: AdminColors.danger, size: 32),
                    const SizedBox(width: 16),
                    Text(
                      'SOS Emergency Details',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.ink),
                    ),
                    const SizedBox(width: 16),
                    AdminStatusPill(
                      label: isActive ? 'ACTIVE' : 'RESOLVED',
                      color: isActive ? AdminColors.danger : AdminColors.success,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 32, color: AdminColors.line),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Details & Audio
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Driver Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.person, 'Name', data['memberName'] ?? 'N/A'),
                        _buildInfoRow(Icons.badge, 'Member ID', data['memberId'] ?? 'N/A'),
                        _buildInfoRow(Icons.phone, 'Phone', data['memberPhone'] ?? 'N/A'),
                        
                        const SizedBox(height: 24),
                        const Text('Responders (Udauwata Giyapu Members)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: responders.isEmpty 
                              ? const Text('No responders yet.', style: TextStyle(color: AdminColors.muted))
                              : ListView.builder(
                                  itemCount: responders.length,
                                  itemBuilder: (context, index) {
                                    final responder = responders[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.check_circle_outline, color: AdminColors.success),
                                      title: Text(responder['helperName'] ?? 'Unknown'),
                                      subtitle: Text(responder['helperPhone'] ?? ''),
                                    );
                                  },
                                ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Text('Voice Recordings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        if (audioUrls.isEmpty)
                          const Text('No audio recorded.', style: TextStyle(color: AdminColors.muted))
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              itemCount: audioUrls.length,
                              itemBuilder: (context, index) {
                                final url = audioUrls[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    _isPlaying && _currentlyPlayingUrl == url ? Icons.volume_up : Icons.mic,
                                    color: AdminColors.primary,
                                  ),
                                  title: Text('Recording Chunk ${index + 1}'),
                                  trailing: IconButton(
                                    icon: Icon(
                                      _isPlaying && _currentlyPlayingUrl == url ? Icons.stop_circle : Icons.play_circle_fill,
                                      color: _isPlaying && _currentlyPlayingUrl == url ? AdminColors.danger : AdminColors.primary,
                                    ),
                                    onPressed: () => _playAudio(url),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column: Map
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AdminColors.line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: initialPos == null 
                            ? const Center(child: Text("Location not available"))
                            : GoogleMap(
                                initialCameraPosition: CameraPosition(target: initialPos, zoom: 15),
                                markers: markers,
                                onMapCreated: (controller) => _mapController = controller,
                              ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AdminColors.muted),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AdminColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminColors.ink)),
        ],
      ),
    );
  }
}

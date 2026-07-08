import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingTimeline extends StatelessWidget {
  final Map<String, dynamic> data;

  const BookingTimeline({super.key, required this.data});

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('hh:mm a').format(time.toLocal());
  }

  String _formatDate(DateTime? time) {
    if (time == null) return '';
    return DateFormat('dd MMM yyyy').format(time.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final requestedAt = _parseDate(data['createdAt']);
    final acceptedAt = _parseDate(data['acceptedAt'] ?? data['acceptedTime']);
    final arrivedAt = _parseDate(data['arrivedAt']);
    final startedAt = _parseDate(data['startedAt'] ?? data['tripStartTime']);
    final completedAt = _parseDate(data['completedAt'] ?? data['tripEndTime']);
    final cancelledAt = _parseDate(data['cancelledAt']);

    final status = (data['status'] ?? '').toString().toLowerCase();

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: const Text(
              'Trip Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTimelineItem(
                  title: 'Requested',
                  time: requestedAt,
                  icon: Icons.touch_app,
                  isFirst: true,
                  isDone: requestedAt != null,
                ),
                _buildTimelineItem(
                  title: 'Accepted',
                  time: acceptedAt,
                  icon: Icons.thumb_up,
                  isDone: acceptedAt != null,
                ),
                _buildTimelineItem(
                  title: 'Arrived at Pickup',
                  time: arrivedAt,
                  icon: Icons.location_on,
                  isDone: arrivedAt != null,
                ),
                _buildTimelineItem(
                  title: 'Trip Started',
                  time: startedAt,
                  icon: Icons.directions_car,
                  isDone: startedAt != null,
                ),
                if (status == 'cancelled' || cancelledAt != null)
                  _buildTimelineItem(
                    title: 'Cancelled',
                    time: cancelledAt ?? (status == 'cancelled' ? DateTime.now() : null), // Fallback
                    icon: Icons.cancel,
                    isDone: true,
                    isLast: true,
                    color: Colors.red,
                  )
                else
                  _buildTimelineItem(
                    title: 'Completed',
                    time: completedAt,
                    icon: Icons.flag,
                    isDone: completedAt != null || status == 'completed',
                    isLast: true,
                    color: Colors.green,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required DateTime? time,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
    bool isDone = false,
    Color? color,
  }) {
    final activeColor = color ?? Colors.blue;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicator column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 16,
                  color: isFirst ? Colors.transparent : (isDone ? activeColor : Colors.grey.shade300),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? activeColor : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: isDone ? Colors.white : Colors.grey.shade500,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : (isDone ? activeColor : Colors.grey.shade300),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                      color: isDone ? Colors.black87 : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(time),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

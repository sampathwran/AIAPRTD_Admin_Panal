import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_detail_dialog.dart';

class AdminBookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  
  const AdminBookingCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    String tripId = data['tripId'] ?? data['bookingId'] ?? 'N/A';
    String memberId = data['memberId'] ?? 'Unknown Member';
    String memberPhone = data['memberPhone'] ?? '';
    String tripType = data['tripType'] ?? 'One way';
    String status = data['status'] ?? 'Unknown';
    String startAddress = data['startAddress'] ?? (data['pickupLocation'] != null ? data['pickupLocation']['address'] : null) ?? 'N/A';
    String endAddress = data['endAddress'] ?? (data['dropLocation'] != null ? data['dropLocation']['address'] : null) ?? 'N/A';
    
    double fare = 0.0;
    var rawFare = data['totalFare'] ?? data['estimateFare'];
    if (rawFare is num) {
      fare = rawFare.toDouble();
    } else if (rawFare is String) {
      fare = double.tryParse(rawFare) ?? 0.0;
    }
    
    String vehicleCategory = data['vehicleCategory'] ?? (data['vehicle'] != null ? data['vehicle']['name'] : null) ?? 'Mini';
    
    DateTime? pickupTime;
    if (data['pickupTime'] != null) {
      pickupTime = DateTime.tryParse(data['pickupTime'].toString());
    }

    // Determine status color
    Color statusColor = Colors.grey;
    if (status.toLowerCase() == 'pending') statusColor = Colors.orange;
    if (status.toLowerCase() == 'ongoing' || status.toLowerCase() == 'accepted' || status.toLowerCase() == 'ongoing pickup' || status.toLowerCase() == 'ongoing drop') statusColor = Colors.blue;
    if (status.toLowerCase() == 'completed' || status.toLowerCase() == 'collected') statusColor = Colors.green;
    if (status.toLowerCase() == 'cancelled') statusColor = Colors.red;

    const textColor = Colors.black87;
    final secondaryTextColor = Colors.grey.shade700;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => BookingDetailDialog(bookingData: data),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Trip ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tripId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          
          if (memberId.isNotEmpty || memberPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  "$memberId ${memberPhone.isNotEmpty ? '($memberPhone)' : ''}",
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Date & Vehicle Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pickupTime != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(pickupTime) : 'N/A',
                        style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.directions_car, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "$vehicleCategory ($tripType)",
                        style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey.shade300),
          ),
          
          // Locations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, color: Colors.blue, size: 12),
                  Container(height: 20, width: 2, color: Colors.grey.shade300),
                  const Icon(Icons.location_on, color: Colors.red, size: 14),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startAddress,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      endAddress,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Fare
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Fare", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("LKR ${fare.toStringAsFixed(2)}", style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

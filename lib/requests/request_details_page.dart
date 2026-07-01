import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_request_provider.dart';
import 'vehicle_photos_view.dart';
import 'document_review_view.dart';

class RequestDetailsPage extends StatelessWidget {
  final String requestId;
  const RequestDetailsPage({super.key, required this.requestId});

  // =========================================================================
  // ✏️ Brand, Model, Year වෙනස් කරන්න පුළුවන් Dialog Box එක
  // =========================================================================
  Future<void> _showEditDetailsDialog(BuildContext context, String requestId, Map<String, dynamic> currentDetails) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return _EditDetailsDialogContent(
          requestId: requestId,
          currentDetails: currentDetails,
          parentContext: context,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Review Vehicle Request",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1B2735)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xff1B2735), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('vehicles').doc(requestId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Request data not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final Map<String, dynamic> details = data['details'] ?? {};

          String? currentCategory = data['selectedCategory'];
          if (currentCategory != null) {
            if (currentCategory == "6 Seater Van") currentCategory = "6 Seater";
            if (currentCategory == "9 Seater Van") currentCategory = "9 Seater";
            if (currentCategory == "14 Seater Van") currentCategory = "14 Seater";
          }

          final String membershipNo = data['membershipNo'] ?? '';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Vehicle Specifications Section with EDIT Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("Vehicle Specifications", Icons.info_outline_rounded),
                          InkWell(
                            onTap: () => _showEditDetailsDialog(context, requestId, details),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text("Edit", style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Card(
                        margin: const EdgeInsets.only(top: 8, bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildDetailBlock("Brand", details['brand'] ?? "N/A", Icons.stars_rounded)),
                                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                                  Expanded(child: _buildDetailBlock("Model", details['model'] ?? "N/A", Icons.model_training_rounded)),
                                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                                  Expanded(child: _buildDetailBlock("Year", details['year'] ?? "N/A", Icons.calendar_today_rounded)),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Divider(height: 1),
                              const SizedBox(height: 18),

                              const Text("Assign Pricing Category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: currentCategory,
                                    hint: const Text("Choose Dynamic Category...", style: TextStyle(fontSize: 13)),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xff1B2735)),
                                    items: [
                                      {"value": "Budget", "label": "Budget", "icon": Icons.attach_money, "color": Colors.green},
                                      {"value": "Mini", "label": "Mini", "icon": Icons.directions_car, "color": Colors.blue},
                                      {"value": "Sedan", "label": "Sedan", "icon": Icons.local_taxi, "color": Colors.orange},
                                      {"value": "6 Seater", "label": "6 Seater Van", "icon": Icons.airport_shuttle, "color": Colors.purple},
                                      {"value": "9 Seater", "label": "9 Seater Van", "icon": Icons.directions_bus, "color": Colors.deepPurple},
                                      {"value": "14 Seater", "label": "14 Seater Van", "icon": Icons.bus_alert, "color": Colors.red},
                                    ].map((cat) => DropdownMenuItem<String>(
                                      value: cat["value"] as String,
                                      child: Row(
                                        children: [
                                          Icon(cat["icon"] as IconData, color: cat["color"] as Color, size: 18),
                                          const SizedBox(width: 10),
                                          Text(cat["label"] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    )).toList(),
                                    onChanged: (val) async {
                                      if (val != null) {
                                        await Provider.of<VehicleRequestProvider>(context, listen: false)
                                            .updateVehicleCategory(requestId, val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (membershipNo.isNotEmpty) ...[
                        _buildSectionTitle("Member Request History", Icons.history_rounded),
                        _buildHistorySnapshot(membershipNo),
                        const SizedBox(height: 12),
                      ],

                      _buildSectionTitle("Vehicle Inspection Photos", Icons.camera_alt_rounded),
                      const SizedBox(height: 8),
                      VehiclePhotosView(photos: data['vehiclePhotos'] ?? {}, requestId: requestId),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Compliance & Official Documents", Icons.folder_shared_rounded),
                      const SizedBox(height: 8),
                      DocumentReviewView(documents: data['documents'] ?? [], requestId: requestId),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Bottom Approval Button Action Container
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1B2735),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: const Text(
                      "Final Approve Request",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    onPressed: () async {
                      if (currentCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Please select a pricing category first!"),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                            )
                        );
                        return;
                      }

                      final provider = Provider.of<VehicleRequestProvider>(context, listen: false);
                      bool success = await provider.approveRequest(requestId);

                      if (!context.mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Vehicle Request Approved & Activated Successfully!"),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            )
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to approve request. Please try again."),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            )
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildDetailBlock(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xff1B2735).withValues(alpha: 0.5)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff1B2735)),
        ),
      ],
    );
  }

  Widget _buildHistorySnapshot(String membershipNo) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('membershipNo', isEqualTo: membershipNo)
          .snapshots(),
      builder: (context, snapshot) {
        int approvedChanges = 0;
        int totalSubmitted = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalSubmitted = docs.length;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'approved') {
              approvedChanges++;
            }
          }
        }

        return Card(
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          elevation: 0,
          color: const Color(0xff1B2735).withValues(alpha: 0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: const Color(0xff1B2735).withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHistoryStatItem("Total Requests", totalSubmitted.toString(), Colors.blueGrey),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildHistoryStatItem("Approved Changes", approvedChanges.toString(), Colors.green),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// =========================================================================
// 🔲 Dialog එක ඇතුලේ ටෙක්ස්ට් කන්ට්‍රෝලර්ස් ඩිස්පෝස් වෙන්න වෙනම ස්ටේට්ෆුල් එකක්
// =========================================================================
class _EditDetailsDialogContent extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> currentDetails;
  final BuildContext parentContext;

  const _EditDetailsDialogContent({
    required this.requestId,
    required this.currentDetails,
    required this.parentContext,
  });

  @override
  State<_EditDetailsDialogContent> createState() => _EditDetailsDialogContentState();
}

class _EditDetailsDialogContentState extends State<_EditDetailsDialogContent> {
  late TextEditingController brandController;
  late TextEditingController modelController;
  late TextEditingController yearController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    brandController = TextEditingController(text: widget.currentDetails['brand'] ?? '');
    modelController = TextEditingController(text: widget.currentDetails['model'] ?? '');
    yearController = TextEditingController(text: widget.currentDetails['year'] ?? '');
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Edit Vehicle Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: brandController,
            decoration: InputDecoration(
              labelText: "Vehicle Brand (e.g., Toyota)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: modelController,
            decoration: InputDecoration(
              labelText: "Vehicle Model (e.g., Prius)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: yearController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Manufacture Year (e.g., 2018)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: isSaving ? null : () async {
            setState(() => isSaving = true);
            try {
              await FirebaseFirestore.instance.collection('vehicles').doc(widget.requestId).update({
                'details.brand': brandController.text.trim(),
                'details.model': modelController.text.trim(),
                'details.year': yearController.text.trim(),
              });

              if (context.mounted) Navigator.pop(context);

              if (widget.parentContext.mounted) {
                ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                  const SnackBar(content: Text("Vehicle details updated successfully! ✅"), backgroundColor: Colors.green),
                );
              }
            } catch (e) {
              setState(() => isSaving = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red),
                );
              }
            }
          },
          child: isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Save Changes", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
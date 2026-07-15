import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/vehicle_request_provider.dart';

class DocumentReviewView extends StatelessWidget {
  final List<dynamic> documents;
  final String requestId;
  const DocumentReviewView({
    super.key,
    required this.documents,
    required this.requestId,
  });

  final List<String> reasons = const [
    "Wrong document",
    "Expired document",
    "Not clear document",
    "None",
  ];

  @override
  Widget build(BuildContext context) {
    final titles = [
      "Revenue License",
      "Insurance Policy",
      "Registration Doc",
      "Driving License (Front)",
      "Driving License (Back)",
    ];
    final icons = [
      Icons.receipt_long_rounded,
      Icons.gavel_rounded,
      Icons.assignment_rounded,
      Icons.badge_rounded,
      Icons.credit_card_rounded,
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index] as Map<String, dynamic>;
        final title = titles.length > index
            ? titles[index]
            : "Doc ${index + 1}";
        final icon = icons.length > index
            ? icons[index]
            : Icons.description_rounded;

        final currentStatus = doc['status'] ?? 'pending';
        Color statusColor = Colors.orange;
        if (currentStatus == 'approved') statusColor = Colors.green;
        if (currentStatus == 'rejected') statusColor = Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(icon, color: statusColor),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xff1B2735),
              ),
            ),
            subtitle: Text(
              currentStatus.toString().toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1B2735),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.rate_review_rounded, size: 14),
              label: const Text(
                "Review",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _openDialog(context, title, doc, index),
            ),
          ),
        );
      },
    );
  }

  void _openDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> doc,
    int index,
  ) {
    final Map<String, TextEditingController> controllers = {};
    String? selectedReason;
    List<String> selectedLicenseTypes = [];
    final provider = Provider.of<VehicleRequestProvider>(
      context,
      listen: false,
    );

    final Map<String, dynamic>? dataToLoad = doc['reviewData'] ?? doc['data'];

    if (dataToLoad != null && dataToLoad is Map) {
      dataToLoad.forEach((key, value) {
        if (key == 'LicenseTypes' && value is List) {
          selectedLicenseTypes = List<String>.from(value);
        } else {
          controllers[key] = TextEditingController(
            text: value?.toString() ?? '',
          );
        }
      });
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final screenSize = MediaQuery.of(context).size;
          final isMobile = screenSize.width < 768;

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: isMobile ? screenSize.width : 1100,
              height: isMobile ? screenSize.height * 0.85 : 750,
              padding: const EdgeInsets.all(16),
              child: isMobile
                  ? Column(
                      children: [
                        Expanded(flex: 2, child: _buildImageSide(doc)),
                        const Divider(height: 24),
                        Expanded(
                          flex: 3,
                          child: _buildFormSide(
                            context,
                            title,
                            controllers,
                            selectedLicenseTypes,
                            setDialogState,
                            provider,
                            index,
                            selectedReason,
                            (v) => selectedReason = v,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 6, child: _buildImageSide(doc)),
                        const VerticalDivider(width: 24),
                        Expanded(
                          flex: 5,
                          child: _buildFormSide(
                            context,
                            title,
                            controllers,
                            selectedLicenseTypes,
                            setDialogState,
                            provider,
                            index,
                            selectedReason,
                            (v) => selectedReason = v,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSide(Map<String, dynamic> doc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                doc['url'] ?? '',
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Failed to load image",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    "Pinch to Zoom",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSide(
    BuildContext context,
    String title,
    Map<String, TextEditingController> controllers,
    List<String> selectedLicenses,
    StateSetter setDialogState,
    VehicleRequestProvider provider,
    int index,
    String? selectedReason,
    ValueChanged<String?> onReasonChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff1B2735),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: _buildForm(
              title,
              controllers,
              selectedLicenses,
              setDialogState,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedReason,
          decoration: InputDecoration(
            labelText: "Reject Reason (Required if Rejecting)",
            labelStyle: const TextStyle(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: reasons
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(r, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => setDialogState(() => onReasonChanged(v)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text(
                  "Approve",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  // 💡 1. Security Checks for Registration Doc
                  if (title == "Registration Doc") {
                    final plateNo =
                        controllers["Plate Number"]?.text
                            .trim()
                            .toUpperCase() ??
                        '';
                    final engineNo =
                        controllers["Engine Number"]?.text
                            .trim()
                            .toUpperCase() ??
                        '';
                    final chassisNo =
                        controllers["Chassis Number"]?.text
                            .trim()
                            .toUpperCase() ??
                        '';

                    if (plateNo.isEmpty ||
                        engineNo.isEmpty ||
                        chassisNo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Security Error: Plate, Engine, and Chassis numbers are required!",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    String? duplicateFoundMessage =
                        await _checkDuplicateVehicleData(
                          plateNo,
                          engineNo,
                          chassisNo,
                          '',
                        );

                    if (!context.mounted) return;
                    Navigator.pop(context); // Remove loading

                    if (duplicateFoundMessage != null) {
                      _showFraudAlertDialog(context, duplicateFoundMessage);
                      return;
                    }
                  }

                  // 💡 2. SECURITY CHECK: Driving License (Front) - Check License Number
                  if (title == "Driving License (Front)") {
                    final licenseNo =
                        controllers["License Number"]?.text
                            .trim()
                            .toUpperCase() ??
                        '';

                    if (licenseNo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Security Error: License Number is required!",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    // License Number එක විතරක් check කරන්න parameters පාස් කරනවා
                    String? duplicateLicenseMessage =
                        await _checkDuplicateVehicleData('', '', '', licenseNo);

                    if (!context.mounted) return;
                    Navigator.pop(context); // Remove loading

                    if (duplicateLicenseMessage != null) {
                      _showFraudAlertDialog(context, duplicateLicenseMessage);
                      return;
                    }
                  }

                  // Driving License (Back) - Check Expiry
                  if (title == "Driving License (Back)") {
                    final expiryDate =
                        controllers["Expiry Date"]?.text.trim() ?? '';
                    if (expiryDate.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error: Expiry Date is required!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }

                  Map<String, dynamic> data = controllers.map(
                    (k, v) => MapEntry(k, v.text.trim()),
                  );
                  if (title == "Driving License (Back)")
                    data['LicenseTypes'] = selectedLicenses;

                  await provider.updateDocumentStatus(
                    requestId,
                    index,
                    "approved",
                    data,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.cancel_rounded, size: 16),
                label: const Text(
                  "Reject",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: selectedReason == null
                    ? null
                    : () async {
                        await provider.updateDocumentStatus(
                          requestId,
                          index,
                          "rejected",
                          {"reason": selectedReason},
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 💡 Upgraded Security Engine: Handles both Vehicle Data and Driving License checking
  Future<String?> _checkDuplicateVehicleData(
    String plate,
    String engine,
    String chassis,
    String licenseNo,
  ) async {
    final CollectionReference vehicles = FirebaseFirestore.instance.collection(
      'vehicles',
    );

    final dataCheck = await vehicles
        .where(FieldPath.documentId, isNotEqualTo: requestId)
        .get();

    if (dataCheck.docs.isNotEmpty) {
      for (var doc in dataCheck.docs) {
        final vehicleData = doc.data() as Map<String, dynamic>;
        final List<dynamic> docsList = vehicleData['documents'] ?? [];

        for (var d in docsList) {
          if (d['data'] != null) {
            final savedData = d['data'] as Map<String, dynamic>;
            final memberId = vehicleData['membershipNo'] ?? 'Unknown Member';

            // Checking License Number Identity Theft
            if (licenseNo.isNotEmpty) {
              final savedLicense =
                  savedData['License Number']
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  '';
              if (savedLicense == licenseNo) {
                return "Driving License Number ($licenseNo) is already registered under Member ID: $memberId";
              }
            }

            // Checking Vehicle Document Frauds
            if (plate.isNotEmpty || engine.isNotEmpty || chassis.isNotEmpty) {
              final savedPlate =
                  savedData['Plate Number']?.toString().trim().toUpperCase() ??
                  '';
              final savedEngine =
                  savedData['Engine Number']?.toString().trim().toUpperCase() ??
                  '';
              final savedChassis =
                  savedData['Chassis Number']
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  '';

              if (savedPlate == plate) {
                return "Plate Number ($plate) is already registered under Member ID: $memberId";
              }
              if (savedEngine == engine) {
                return "Engine Number ($engine) is already registered under Member ID: $memberId";
              }
              if (savedChassis == chassis) {
                return "Chassis Number ($chassis) is already registered under Member ID: $memberId";
              }
            }
          }
        }
      }
    }
    return null;
  }

  void _showFraudAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 46),
        title: const Text(
          "SECURITY FRAUD ALERT",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          "$message\n\nYou cannot approve this document as it violates our unique identity policy. Please reject this request immediately.",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1B2735),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "I Understand",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    String title,
    Map<String, TextEditingController> controllers,
    List<String> selectedLicenses,
    StateSetter setDialogState,
  ) {
    if (title == "Registration Doc") {
      final fields = [
        "Owner Name",
        "Owner Address",
        "Plate Number",
        "Engine Number",
        "Chassis Number",
        "Reg Book No",
        "Seating Capacity",
        "Fuel Type",
        "Color",
        "Make",
        "Model",
        "Cylinder Capacity",
        "Country of Origin",
        "Manufacture Year",
        "Register Year",
      ];

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: fields.map((f) {
          final width = controllers.isNotEmpty ? 230.0 : 210.0;
          return SizedBox(
            width: width,
            child: TextField(
              controller: controllers.putIfAbsent(
                f,
                () => TextEditingController(),
              ),
              style: const TextStyle(fontSize: 13),
              textCapitalization:
                  (f == "Plate Number" ||
                      f == "Engine Number" ||
                      f == "Chassis Number")
                  ? TextCapitalization.characters
                  : TextCapitalization.none,
              decoration: InputDecoration(
                labelText: f,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else if (title == "Driving License (Front)") {
      return TextField(
        controller: controllers.putIfAbsent(
          "License Number",
          () => TextEditingController(),
        ),
        style: const TextStyle(fontSize: 13),
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: "Driving License Number",
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else if (title == "Driving License (Back)") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controllers.putIfAbsent(
              "Expiry Date",
              () => TextEditingController(),
            ),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: "Expiry Date",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Permitted Vehicle Categories:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: ["A1", "A", "B1", "B", "C1", "C", "CE", "D", "D1"]
                .map(
                  (t) => FilterChip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                    selected: selectedLicenses.contains(t),
                    selectedColor: const Color(0xff1B2735).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xff1B2735),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onSelected: (s) => setDialogState(
                      () => s
                          ? selectedLicenses.add(t)
                          : selectedLicenses.remove(t),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    } else {
      return TextField(
        controller: controllers.putIfAbsent(
          "Expiry Date",
          () => TextEditingController(),
        ),
        decoration: InputDecoration(
          labelText: "Expiry Date",
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

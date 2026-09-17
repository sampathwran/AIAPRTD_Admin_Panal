import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/member_pdf_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/download_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/edit_driver_profile_dialog.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/messaging_hub/send_whatsapp_dialog.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/messaging_hub/inactive_warning_dialog.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/admin_profile_image_updater.dart';
class DriverProfileDialog extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverProfileDialog({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        final statusResult = calculateMemberStatus(driver);
        final bool isActive = statusResult['isActive'] == true;
        final String inactiveReason = statusResult['reason'] ?? '';
        final String statusText = isActive
            ? 'ACTIVE MEMBER'
            : (inactiveReason.isNotEmpty
                  ? 'INACTIVE: $inactiveReason'
                  : 'INACTIVE MEMBER');
        final Color statusColor = isActive
            ? Colors.green.shade700
            : Colors.red.shade700;
        final Color statusBg = isActive ? Colors.green.shade50 : Colors.red.shade50;

        return SelectionArea(
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          height: 650,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              _buildHeader(
                context,
                statusText,
                statusColor,
                statusBg,
                isActive,
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Tabs Section
              Expanded(
                child: DefaultTabController(
                  length: 5,
                  child: Column(
                    children: [
                      const TabBar(
                        isScrollable: true,
                        labelColor: Color(0xFF1E3A8A),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF1E3A8A),
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: 'Personal Details'),
                          Tab(text: 'Vehicle Details'),
                          Tab(text: 'Membership Fee'),
                          Tab(text: 'Transaction History'),
                          Tab(text: 'Bank Details'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPersonalDetailsTab(),
                            _buildVehicleDetailsTab(),
                            _buildMembershipFeeTab(),
                            _buildTransactionHistoryTab(),
                            _buildBankDetailsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String statusText,
    Color statusColor,
    Color statusBg,
    bool isActive,
  ) {
    final String initials =
        ((driver['firstName'] ?? '').toString().trim().isNotEmpty
                ? (driver['firstName'] ?? '').toString().trim().substring(0, 1)
                : ((driver['fullName'] ?? '').toString().trim().isNotEmpty
                      ? (driver['fullName'] ?? '').toString().trim().substring(
                          0,
                          1,
                        )
                      : 'D'))
            .toUpperCase();

    final hasImage =
        driver['profileImageUrl'] != null &&
        driver['profileImageUrl'].toString().isNotEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminProfileImageUpdater(
                    driver: driver,
                    initials: initials,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 140,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        final urlStr = driver['profileImageUrl'].toString();
                        if (urlStr.isEmpty) return;
                        
                        try {
                          final response = await http.get(Uri.parse(urlStr));
                          if (response.statusCode == 200) {
                            final String memNo = driver['membershipNo'] ?? driver['doc_id'] ?? 'member';
                            await downloadFile(response.bodyBytes, 'profile_$memNo.jpg');
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download image')));
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                      icon: const Icon(Icons.download, size: 14),
                      label: const Text('Download', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['fullName'] ?? 'Unknown Member',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      driver['membershipNo'] ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    if (driver['cancellationWarningSentAt'] != null)
                      Builder(
                        builder: (context) {
                          final Timestamp warningTimestamp = driver['cancellationWarningSentAt'];
                          final DateTime sentDate = warningTimestamp.toDate();
                          final DateTime expiryDate = sentDate.add(const Duration(days: 90));
                          final int daysLeft = expiryDate.difference(DateTime.now()).inDays;
                          final String formattedDate = DateFormat('yyyy-MM-dd').format(sentDate);
                          final bool isExpired = daysLeft <= 0;
                          
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isExpired ? Colors.red.shade50 : Colors.orange.shade50,
                              border: Border.all(color: isExpired ? Colors.red.shade200 : Colors.orange.shade200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isExpired ? Icons.cancel : Icons.warning_amber_rounded, color: isExpired ? Colors.red : Colors.orange, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  isExpired 
                                  ? 'Warning Expired! (Sent $formattedDate)' 
                                  : 'Warning Sent: $formattedDate ($daysLeft days remaining)',
                                  style: TextStyle(color: isExpired ? Colors.red.shade800 : Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _promptDeleteMember(context, driver),
                          icon: const Icon(Icons.delete_forever, size: 14, color: Colors.red),
                          label: const Text(
                            'Delete Member',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EditDriverProfileDialog(
                                driver: driver,
                                onUpdated: () {},
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 14, color: Colors.blue),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => showSendWhatsAppDialog(context, driver),
                          icon: const Icon(Icons.message_rounded, size: 14, color: Colors.white),
                          label: const Text(
                            'WhatsApp',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        if (!isActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await showInactiveWarningDialog(context, driver);
                              },
                              icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                              label: const Text(
                                'Send Warning',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackInitial(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.blue.shade800,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCards() {
    final driverId = driver['membershipNo'] ?? driver['uid'] ?? '';
    if (driverId.toString().isEmpty) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('members')
          .doc(driverId.toString())
          .snapshots(),
      builder: (context, snapshot) {
        double appUsageCharge = 0.0;
        double savingsBalance = 0.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          appUsageCharge =
              double.tryParse(
                data['appUsageChargeBalance']?.toString() ?? '0',
              ) ??
              0.0;
          savingsBalance =
              double.tryParse(data['savingsBalance']?.toString() ?? '0') ?? 0.0;
        } else {
          // Fallback to static data if stream hasn't loaded yet
          appUsageCharge =
              double.tryParse(
                driver['appUsageChargeBalance']?.toString() ?? '0',
              ) ??
              0.0;
          savingsBalance =
              double.tryParse(driver['savingsBalance']?.toString() ?? '0') ??
              0.0;
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'App Usage Charge',
                'Rs. ${appUsageCharge.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Savings Balance',
                'Rs. ${savingsBalance.toStringAsFixed(2)}',
                Icons.savings,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            _InfoItem('Join Date', driver['joinDate']),
            _InfoItem('NIC Number', driver['nic']),
            _InfoItem('Mobile', driver['mobile']),
            _InfoItem('Email', driver['user_email']),
            _InfoItem('Gender', driver['gender']),
            _InfoItem('Date of Birth', driver['dob']),
            _InfoItem('Religion', driver['religion']),
            _InfoItem('Address', driver['address']),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Account & App Details'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            _InfoItem('Profile Status', driver['profile_status']),
            _InfoItem('Online Status', driver['onlineStatus']),
            _InfoItem('Total Accepted', driver['totalAcceptedCount']),
            _InfoItem(
              'Rating',
              '${driver['rating'] ?? 0} (${driver['ratingCount'] ?? 0} reviews)',
            ),
            _InfoItem('KYC Approval', driver['kycApprovalStatus']),
            _InfoItem('Face KYC Status', driver['faceKycStatus']),
            _InfoItem('Bank Update', driver['bankUpdateStatus']),
            _InfoItem('Auth UID', driver['auth_uid']),
          ]),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsTab() {
    final membershipNo = driver['membershipNo']?.toString();
    if (membershipNo == null || membershipNo.isEmpty) {
      return const Center(
        child: Text(
          'Membership Number is missing.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .doc(membershipNo)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          );
        }

        final List<Map<String, dynamic>> dbVehicles = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          dbVehicles.add(snapshot.data!.data() as Map<String, dynamic>);
        } else {
          // Fallback to driver object
          final currentVehicle =
              driver['currentVehicle'] as Map<String, dynamic>?;
          if (currentVehicle != null) {
            dbVehicles.add(currentVehicle);
          }
        }

        // Add history from driver object
        final vehicleHistory = driver['vehicleHistory'] as List<dynamic>? ?? [];
        for (var v in vehicleHistory) {
          if (v is Map<String, dynamic>) {
            dbVehicles.add(v);
          }
        }

        if (dbVehicles.isEmpty) {
          return const Center(
            child: Text(
              'No vehicle details available.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...dbVehicles.asMap().entries.map((entry) {
                final index = entry.key;
                final v = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        index == 0
                            ? 'Current Vehicle'
                            : 'Vehicle History ${index}',
                      ),
                      const SizedBox(height: 16),
                      _buildVehicleSection(v, isCurrent: index == 0),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleSection(
    Map<String, dynamic> v, {
    bool isCurrent = false,
  }) {
    final details = v['details'] as Map<String, dynamic>? ?? {};
    final docs = v['documents'] as List<dynamic>? ?? [];
    final photos = v['vehiclePhotos'] as Map<String, dynamic>? ?? {};

    // Vehicle basic details
    final brand = details['brand'] ?? '-';
    final model = details['model'] ?? '-';
    final category = v['selectedCategory'] ?? v['category'] ?? '-';
    final status = v['status'] ?? '-';

    String? approvedAtStr;
    if (v['approvedAt'] != null) {
      approvedAtStr = v['approvedAt'].toString();
    }

    final List<_InfoItem> gridItems = [
      _InfoItem('Brand / Model', '$brand $model'),
      _InfoItem('Category', category),
      _InfoItem('Approval Status', status.toString().toUpperCase()),
    ];

    if (approvedAtStr != null) {
      gridItems.add(_InfoItem('Approved At', approvedAtStr));
    }

    // Extract all dynamic details from reviewData inside documents
    for (var d in docs) {
      if (d is Map<String, dynamic> && d['reviewData'] != null) {
        final review = d['reviewData'] as Map<String, dynamic>;
        review.forEach((key, value) {
          if (value == null || value.toString().isEmpty) return;

          String displayValue = value.toString();
          if (value is List) {
            displayValue = value.join(', ');
          }

          // Avoid duplicates
          final exists = gridItems.any(
            (item) => item.label.toLowerCase() == key.toLowerCase(),
          );
          if (!exists) {
            gridItems.add(_InfoItem(key, displayValue));
          }
        });
      }
    }

    // Add all dynamically from details
    details.forEach((key, value) {
      if (key == 'brand' || key == 'model') return;
      if (value == null || value.toString().isEmpty) return;

      // Convert camelCase to Title Case
      final formattedKey = key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
      final title = formattedKey.isNotEmpty
          ? formattedKey[0].toUpperCase() + formattedKey.substring(1)
          : key;

      final exists = gridItems.any(
        (item) => item.label.toLowerCase() == title.toLowerCase(),
      );
      if (!exists) {
        gridItems.add(_InfoItem(title, value.toString()));
      }
    });

    // Add all dynamically from root (excluding complex objects and already shown ones)
    final excludeKeys = [
      'details',
      'documents',
      'vehiclePhotos',
      'selectedCategory',
      'category',
      'status',
      'approvedAt',
      'createdAt',
      'updatedAt',
      'rateProfileRef',
      'ratesLastSynced',
      'membershipNo',
    ];
    v.forEach((key, value) {
      if (excludeKeys.contains(key)) return;
      if (value is Map || value is List) return; // Skip complex objects

      final formattedKey = key.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
      final title = formattedKey.isNotEmpty
          ? formattedKey[0].toUpperCase() + formattedKey.substring(1)
          : key;
      gridItems.add(_InfoItem(title, value.toString()));
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.blue.shade50.withValues(alpha: 0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoGrid(gridItems),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Vehicle Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: photos.entries.map((e) {
                final photoData = e.value as Map<String, dynamic>? ?? {};
                final url = photoData['url']?.toString() ?? '';
                if (url.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 120,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 90,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembershipFeeTab() {
    final membershipNo = driver['membershipNo'];
    if (membershipNo == null || membershipNo.toString().isEmpty) {
      return const Center(
        child: Text('No Membership Number found for this driver.'),
      );
    }

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('app_membership_fee')
            .doc(membershipNo)
            .get(),
        FirebaseFirestore.instance
            .collection('web_sync_membership_fee')
            .doc(membershipNo)
            .get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading fee details: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final appDoc = snapshot.data![0];
        final webDoc = snapshot.data![1];

        final appData = appDoc.exists
            ? (appDoc.data() as Map<String, dynamic>? ?? {})
            : {};
        final webData = webDoc.exists
            ? (webDoc.data() as Map<String, dynamic>? ?? {})
            : {};

        final appHistory = appData['payment_history'] as List<dynamic>? ?? [];
        final appPending = appData['pending_payments'] as List<dynamic>? ?? [];

        final webHistoryRaw =
            webData['payment_history'] as List<dynamic>? ?? [];

        final webPending = webHistoryRaw.where((p) {
          if (p is Map<String, dynamic>) {
            return (p['status'] ?? '').toString().toLowerCase() == 'pending';
          }
          return false;
        }).toList();

        final webApproved = webHistoryRaw.where((p) {
          if (p is Map<String, dynamic>) {
            return (p['status'] ?? '').toString().toLowerCase() != 'pending';
          }
          return true; // fallback to include if unknown
        }).toList();

        final allPendingRaw = [...appPending, ...webPending];
        final allHistoryRaw = [...appHistory, ...webApproved];

        List<Map<String, dynamic>> _deduplicatePayments(List<dynamic> records) {
          final sorted = List<Map<String, dynamic>>.from(
            records.whereType<Map<String, dynamic>>(),
          );
          // Sort by date descending so we keep the newest record if there are duplicates
          sorted.sort((a, b) {
            final dateA = (a['date'] ?? '').toString();
            final dateB = (b['date'] ?? '').toString();
            return dateB.compareTo(dateA);
          });

          final Set<String> seen = {};
          final List<Map<String, dynamic>> result = [];

          for (var p in sorted) {
            final rMonth = (p['month'] ?? '').toString().trim().toLowerCase();
            String rYear = (p['year'] ?? '').toString().trim();
            if (rYear.isEmpty) {
              final dateStr = (p['date'] ?? '').toString().trim();
              if (dateStr.length >= 4) {
                rYear = dateStr.substring(0, 4);
              }
            }

            final key = '${rMonth}_$rYear';
            if (rMonth.isNotEmpty) {
              if (!seen.contains(key)) {
                seen.add(key);
                result.add(p);
              }
            } else {
              result.add(p); // Fallback for invalid records
            }
          }
          return result;
        }

        final allPending = _deduplicatePayments(allPendingRaw);
        final allHistory = _deduplicatePayments(allHistoryRaw);

        return StatefulBuilder(
          builder: (context, setState) {
            // --- CALC UNPAID MONTHS ---
            final joinDateStr = driver['joinDate']?.toString() ?? '';
            DateTime? joinDate;
            try {
              if (joinDateStr.isNotEmpty)
                joinDate = DateTime.parse(joinDateStr);
            } catch (_) {}

            int totalMonths = 0;
            int paidMonths = 0;
            int arrearsMonths = 0;
            final List<Map<String, String>> unpaidMonthsList = [];

            if (joinDate != null) {
              DateTime now = DateTime.now();
              int currentYear = now.year;
              int currentMonth = now.month;

              // Grace period: Until the 5th of the month, the current month is not considered in arrears
              if (now.day <= 5) {
                currentMonth -= 1;
                if (currentMonth == 0) {
                  currentMonth = 12;
                  currentYear -= 1;
                }
              }

              DateTime currentDate = DateTime(joinDate.year, joinDate.month);
              final end = DateTime(currentYear, currentMonth);
              final DateFormat monthFormat = DateFormat('MMMM');

              // Collect all approved paid months into a set for fast lookup
              final Set<String> paidMonthYearSet = {};
              for (var record in allHistory) {
                if (record is Map<String, dynamic>) {
                  final rMonth = (record['month'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
                  String rYear = (record['year'] ?? '').toString().trim();

                  if (rYear.isEmpty) {
                    final dateStr = (record['date'] ?? '').toString().trim();
                    if (dateStr.length >= 4) {
                      rYear = dateStr.substring(0, 4);
                    }
                  }

                  if (rMonth.isNotEmpty && rYear.isNotEmpty) {
                    paidMonthYearSet.add('${rMonth}_$rYear');
                  }
                }
              }

              paidMonths = paidMonthYearSet.length;

              while (!currentDate.isAfter(end)) {
                totalMonths++;
                final String mName = monthFormat.format(currentDate);
                final String yName = currentDate.year.toString();
                final String key = '${mName.toLowerCase()}_$yName';

                if (!paidMonthYearSet.contains(key)) {
                  unpaidMonthsList.add({'month': mName, 'year': yName});
                }

                currentDate = DateTime(currentDate.year, currentDate.month + 1);
              }

              arrearsMonths = unpaidMonthsList.length;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildSectionTitle('Membership Fee Summary'),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (joinDate != null)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Joined: ${DateFormat('yyyy-MM-dd').format(joinDate!)}',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: joinDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (selectedDate != null) {
                                final isoString = selectedDate.toIso8601String();
                                try {
                                  // Save to member collection
                                  await FirebaseFirestore.instance
                                      .collection('member')
                                      .doc(driver['membershipNo'] ?? driver['doc_id'] ?? driver['uid'])
                                      .set({'joinDate': isoString}, SetOptions(merge: true));

                                  // Also save to vehicles collection just in case
                                  await FirebaseFirestore.instance
                                      .collection('vehicles')
                                      .doc(driver['membershipNo'] ?? driver['doc_id'] ?? driver['uid'])
                                      .set({'joinDate': isoString}, SetOptions(merge: true));

                                  setState(() {
                                    driver['joinDate'] = isoString;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Join Date updated successfully!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error updating join date: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: Text(
                              joinDate == null
                                  ? 'Set Join Date'
                                  : 'Edit Join Date',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => _showAddManualPaymentDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add Fee',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (joinDate == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cannot calculate arrears because Join Date is missing. Please update the member profile.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildFeeSummaryCards(
                      totalMonths,
                      paidMonths,
                      arrearsMonths,
                    ),

                  const SizedBox(height: 32),

                  if (unpaidMonthsList.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Unpaid Months List (${unpaidMonthsList.length})',
                    ),
                    const SizedBox(height: 16),
                    _buildUnpaidMonthsTable(
                      unpaidMonthsList.reversed.toList(),
                    ), // Z-A order (newest first)
                    const SizedBox(height: 32),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionTitle('Pending Payments (${allPending.length})'),
                  const SizedBox(height: 16),
                  if (allPending.isEmpty)
                    const Text(
                      'No pending payments.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    _buildPaymentTable(allPending),

                  const SizedBox(height: 32),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Payment History (${allHistory.length})'),
                  const SizedBox(height: 16),
                  if (allHistory.isEmpty)
                    const Text(
                      'No payment history available.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    _buildPaymentTable(allHistory),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeeSummaryCards(
    int totalMonths,
    int paidMonths,
    int arrearsMonths,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Months',
            totalMonths.toString(),
            Icons.calendar_month,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Paid Months',
            paidMonths.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Arrears Months',
            arrearsMonths.toString(),
            Icons.error_outline,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color.shade800,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidMonthsTable(List<Map<String, String>> unpaidMonths) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 50,
          columns: const [
            DataColumn(
              label: Text(
                'Month/Year',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
          rows: unpaidMonths.map((m) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${m['month']} ${m['year']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'UNPAID / PENDING',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  int _monthToInt(String month) {
    switch (month.toLowerCase().trim()) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      case 'december':
        return 12;
      default:
        return 0;
    }
  }

  Widget _buildPaymentTable(List<dynamic> payments) {
    // Sort payments by target month/year descending (newest month first)
    final sortedPayments = List<Map<String, dynamic>>.from(
      payments.whereType<Map<String, dynamic>>(),
    );
    sortedPayments.sort((a, b) {
      String yearA = (a['year'] ?? '').toString().trim();
      if (yearA.isEmpty) {
        final d = (a['date'] ?? '').toString().trim();
        if (d.length >= 4) yearA = d.substring(0, 4);
      }

      String yearB = (b['year'] ?? '').toString().trim();
      if (yearB.isEmpty) {
        final d = (b['date'] ?? '').toString().trim();
        if (d.length >= 4) yearB = d.substring(0, 4);
      }

      int yA = int.tryParse(yearA) ?? 0;
      int yB = int.tryParse(yearB) ?? 0;

      if (yA != yB) {
        return yB.compareTo(yA);
      }

      int mA = _monthToInt((a['month'] ?? '').toString());
      int mB = _monthToInt((b['month'] ?? '').toString());

      return mB.compareTo(mA);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          dataRowMinHeight: 45,
          dataRowMaxHeight: 65,
          columns: const [
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Month/Year',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Amount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Reason',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Slip',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: sortedPayments.map((p) {
            final month = p['month'] ?? '-';
            final year = p['year'] ?? '';
            final amount = p['amount'] ?? '0';
            final status = (p['status'] ?? '-').toString().toLowerCase();
            final slipUrl = p['slipUrl']?.toString() ?? '';

            Color statusColor = Colors.grey;
            if (status == 'approved')
              statusColor = Colors.green;
            else if (status == 'pending')
              statusColor = Colors.orange;
            else if (status == 'rejected')
              statusColor = Colors.red;

            return DataRow(
              cells: [
                DataCell(Text(p['date'] ?? '-')),
                DataCell(Text('$month $year'.trim())),
                DataCell(
                  Text(
                    'Rs. $amount',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['type'] ?? '-',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        p['source'] ?? '-',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    p['reason'] ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  slipUrl.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.image, color: Colors.blue),
                          onPressed: () {
                            // Can show dialog with image if needed
                          },
                          tooltip: 'View Slip',
                        )
                      : const Text('-', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionHistoryTab() {
    final driverId = driver['membershipNo'] ?? driver['uid'] ?? '';
    if (driverId.toString().isEmpty) {
      return const Center(child: Text('No Driver ID found.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildFinancialSummaryCards(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('finance_transactions')
                .where('driverId', isEqualTo: driverId.toString())
                .orderBy('timestamp', descending: true)
                .limit(100)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading transactions: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Transaction History found.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Once data is saved, it will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(
                          'Recent Transactions (${docs.length})',
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            MemberPdfGenerator.downloadCertifiedIncomeReport(
                              driver,
                              docs,
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text(
                            'Download Income Report',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.blue.shade50,
                          ),
                          dataRowMinHeight: 45,
                          dataRowMaxHeight: 65,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Date & Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Type',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Trip Ref',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Union Charge',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total Commission',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Driver Earned',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            // Safely parse timestamp
                            String dateTimeStr = '-';
                            if (data['timestamp'] != null) {
                              if (data['timestamp'] is Timestamp) {
                                dateTimeStr = DateFormat('yyyy-MMM-dd hh:mm a')
                                    .format(
                                      (data['timestamp'] as Timestamp).toDate(),
                                    );
                              } else {
                                dateTimeStr = data['timestamp'].toString();
                              }
                            }

                            final type = (data['type'] ?? 'Unknown').toString();
                            final tripId = (data['tripId'] ?? '-').toString();

                            // Parse amounts based on finance_transactions schema
                            final totalFare =
                                double.tryParse(
                                  data['totalFare']?.toString() ?? '0',
                                ) ??
                                0.0;
                            final driverCommission =
                                double.tryParse(
                                  data['driverCommission']?.toString() ?? '0',
                                ) ??
                                0.0;
                            final unionUsageCharge =
                                double.tryParse(
                                  data['unionUsageCharge']?.toString() ?? '0',
                                ) ??
                                0.0;
                            final amount =
                                double.tryParse(
                                  data['amount']?.toString() ?? '0',
                                ) ??
                                0.0; // for auto_settlement

                            double displayCommission = driverCommission > 0
                                ? driverCommission
                                : amount;
                            double driverEarned = totalFare > 0
                                ? totalFare - displayCommission
                                : 0.0;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    dateTimeStr,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    tripId,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    unionUsageCharge > 0
                                        ? 'Rs. ${unionUsageCharge.toStringAsFixed(2)}'
                                        : '-',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    displayCommission > 0
                                        ? 'Rs. ${displayCommission.toStringAsFixed(2)}'
                                        : '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    driverEarned > 0
                                        ? 'Rs. ${driverEarned.toStringAsFixed(2)}'
                                        : '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBankDetailsTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('member')
          .doc(driver['membershipNo']?.toString() ?? '')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String bankName = '-';
        String accHolder = '-';
        String accNumber = '-';
        String branchName = '-';
        String branchCode = '-';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          bankName =
              data['bankName']?.toString() ??
              driver['bankName']?.toString() ??
              '-';
          accHolder =
              data['accountHolderName']?.toString() ??
              driver['accountHolderName']?.toString() ??
              '-';
          accNumber =
              data['accountNumber']?.toString() ??
              driver['accountNumber']?.toString() ??
              '-';
          branchName =
              data['branchName']?.toString() ??
              driver['branchName']?.toString() ??
              '-';
          branchCode =
              data['branchCode']?.toString() ??
              driver['branchCode']?.toString() ??
              '-';
        } else {
          // Fallback to driver data
          bankName = driver['bankName']?.toString() ?? '-';
          accHolder = driver['accountHolderName']?.toString() ?? '-';
          accNumber = driver['accountNumber']?.toString() ?? '-';
          branchName = driver['branchName']?.toString() ?? '-';
          branchCode = driver['branchCode']?.toString() ?? '-';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Bank Account Details'),
              const SizedBox(height: 16),
              _buildInfoGrid([
                _InfoItem('Bank Name', bankName),
                _InfoItem('Account Holder', accHolder),
                _InfoItem('Account Number', accNumber),
                _InfoItem('Branch Name', branchName),
                _InfoItem('Branch Code', branchCode),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: items.map((item) {
        return SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                item.value?.toString().isNotEmpty == true
                    ? item.value.toString()
                    : '-',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _promptDeleteMember(BuildContext context, Map<String, dynamic> member) {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false;
    String errorMsg = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('CRITICAL: Delete Member', style: TextStyle(color: Colors.red)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to completely remove ${member['membershipNo']} from the system? This action CANNOT be undone.'),
                  const SizedBox(height: 16),
                  const Text('Enter Admin Password to confirm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Password',
                    ),
                  ),
                  if (errorMsg.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(errorMsg, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          if (passwordController.text != '885313') {
                            setDialogState(() => errorMsg = 'Incorrect password.');
                            return;
                          }
                          
                          setDialogState(() {
                            isDeleting = true;
                            errorMsg = '';
                          });

                          try {
                            String membershipNo = member['membershipNo'];
                            var firestore = FirebaseFirestore.instance;
                            
                            // 1. Delete from 'member' collection
                            await firestore.collection('member').doc(membershipNo).delete();
                            var memberDocs = await firestore.collection('member').where('membershipNo', isEqualTo: membershipNo).get();
                            for (var doc in memberDocs.docs) {
                              await doc.reference.delete();
                            }
                            
                            // 2. Delete from 'web_sync_member'
                            var webSyncDocs = await firestore.collection('web_sync_member').where('membershipNo', isEqualTo: membershipNo).get();
                            for (var doc in webSyncDocs.docs) {
                              await doc.reference.delete();
                            }
                            await firestore.collection('web_sync_member').doc(membershipNo).delete();
                            
                            // 3. Delete from fees
                            await firestore.collection('web_sync_membership_fee').doc(membershipNo).delete();
                            await firestore.collection('app_membership_fee').doc(membershipNo).delete();
                            
                            // 4. Delete from WordPress via API
                            try {
                              final response = await http.post(
                                Uri.parse('https://aiaprtd.lk/wp-json/aiaprtd/v1/delete-member'),
                                body: {
                                  'membership_no': membershipNo,
                                  'secure_token': 'AIA_SUPER_SECRET_2026',
                                },
                              );
                              if (response.statusCode != 200) {
                                debugPrint('WP Delete Failed: ${response.body}');
                              }
                            } catch (wpError) {
                              debugPrint('WP Delete Error: $wpError');
                            }
                            
                            if (context.mounted) {
                              Navigator.pop(dialogContext); // Close warning dialog
                              Navigator.pop(context); // Close profile dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Member successfully deleted from the system.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isDeleting = false;
                              errorMsg = 'Error: $e';
                            });
                          }
                        },
                  child: isDeleting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Permanently Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddManualPaymentDialog(BuildContext context) async {
    final membershipNo = driver['membershipNo']?.toString() ?? '';
    if (membershipNo.isEmpty) return;

    final TextEditingController amountController = TextEditingController(text: '500');
    final List<String> allMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    Map<String, bool> selectedMonths = {
      for (var m in allMonths) m: false
    };
    // Default tick the current month
    String currentMonthName = allMonths[DateTime.now().month - 1];
    selectedMonths[currentMonthName] = true;

    final List<String> years = [for (int y = 2023; y <= 2030; y++) y.toString()];
    String selectedYear = DateTime.now().year.toString();

    final List<String> methods = ['Cash', 'Card', 'Bank Transfer', 'Free Membership Fee'];
    String selectedMethod = 'Cash';

    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Fee'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedYear,
                            decoration: const InputDecoration(labelText: 'à¶…à·€à·”à¶»à·”à¶¯à·Šà¶¯ (Year)', border: OutlineInputBorder()),
                            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(color: Colors.black)))).toList(),
                            onChanged: (val) => setState(() => selectedYear = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedMethod,
                            decoration: const InputDecoration(labelText: 'à¶œà·™à·€à·“à¶¸à·Š à¶šà·Šâ€à¶»à¶¸à¶º', border: OutlineInputBorder()),
                            items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.black)))).toList(),
                            onChanged: (val) => setState(() => selectedMethod = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('à¶…à¶¯à·à·… à¶¸à·à·ƒ (Select Months):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 0,
                      runSpacing: 0,
                      children: allMonths.map((m) {
                        return SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: selectedMonths[m],
                                onChanged: (val) {
                                  setState(() => selectedMonths[m] = val ?? false);
                                },
                              ),
                              Text(m, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'à¶¸à·à·ƒà·’à¶š à¶œà·à¶« (Amount per month)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                onPressed: isSaving ? null : () async {
                  final amount = amountController.text.trim();
                  if (amount.isEmpty) return;
                  
                  final tickedMonths = selectedMonths.entries.where((e) => e.value).map((e) => e.key).toList();
                  if (tickedMonths.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('à¶šà¶»à·”à¶«à·à¶šà¶» à¶…à·€à¶¸ à·€à·à¶ºà·™à¶±à·Š à¶‘à¶šà·Š à¶¸à·à·ƒà¶ºà¶šà·Š à·„à· à¶­à·à¶»à¶±à·Šà¶±!'), backgroundColor: Colors.orange));
                    return;
                  }

                  setState(() => isSaving = true);
                  
                  try {
                    List<Map<String, dynamic>> newPayments = [];
                    for (int i = 0; i < tickedMonths.length; i++) {
                      newPayments.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString() + '_' + i.toString(),
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'month': tickedMonths[i],
                        'year': selectedYear,
                        'amount': amount,
                        'status': 'APPROVED',
                        'type': selectedMethod,
                        'source': 'Admin',
                        'timestamp': Timestamp.now(), // Fixed Firebase array error
                      });
                    }

                    await FirebaseFirestore.instance.collection('app_membership_fee').doc(membershipNo).set({
                      'payment_history': FieldValue.arrayUnion(newPayments),
                      'membershipNo': membershipNo,
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee Added Successfully! Close and reopen this profile to see it.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Payment'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final dynamic value;

  _InfoItem(this.label, this.value);
}

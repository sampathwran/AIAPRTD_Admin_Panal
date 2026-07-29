import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DriverProfileDialog extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverProfileDialog({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final statusResult = calculateMemberStatus(driver);
    final bool isActive = statusResult['isActive'] == true;
    final String inactiveReason = statusResult['reason'] ?? '';
    final String statusText = isActive
        ? 'ACTIVE MEMBER'
        : (inactiveReason.isNotEmpty
            ? 'INACTIVE: $inactiveReason'
            : 'INACTIVE MEMBER');
    final Color statusColor = isActive ? Colors.green.shade700 : Colors.red.shade700;
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
            _buildHeader(context, statusText, statusColor, statusBg, isActive),
            
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Tabs Section
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Color(0xFF1E3A8A),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF1E3A8A),
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: 'Personal Details'),
                        Tab(text: 'Vehicle Details'),
                        Tab(text: 'Membership Fee'),
                        Tab(text: 'Transaction History'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPersonalDetailsTab(),
                          _buildVehicleDetailsTab(),
                          _buildMembershipFeeTab(),
                          _buildTransactionHistoryTab(),
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
  }

  Widget _buildHeader(BuildContext context, String statusText, Color statusColor, Color statusBg, bool isActive) {
    final String initials = ((driver['firstName'] ?? '').toString().trim().isNotEmpty 
        ? (driver['firstName'] ?? '').toString().trim().substring(0, 1) 
        : ((driver['fullName'] ?? '').toString().trim().isNotEmpty 
            ? (driver['fullName'] ?? '').toString().trim().substring(0, 1) 
            : 'D')).toUpperCase();

    final hasImage = driver['profileImageUrl'] != null && driver['profileImageUrl'].toString().isNotEmpty;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipOval(
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: driver['profileImageUrl'].toString(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => _buildFallbackInitial(initials),
                        )
                      : _buildFallbackInitial(initials),
                ),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
            splashRadius: 24,
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
      stream: FirebaseFirestore.instance.collection('members').doc(driverId.toString()).snapshots(),
      builder: (context, snapshot) {
        double appUsageCharge = 0.0;
        double savingsBalance = 0.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          appUsageCharge = double.tryParse(data['appUsageChargeBalance']?.toString() ?? '0') ?? 0.0;
          savingsBalance = double.tryParse(data['savingsBalance']?.toString() ?? '0') ?? 0.0;
        } else {
          // Fallback to static data if stream hasn't loaded yet
          appUsageCharge = double.tryParse(driver['appUsageChargeBalance']?.toString() ?? '0') ?? 0.0;
          savingsBalance = double.tryParse(driver['savingsBalance']?.toString() ?? '0') ?? 0.0;
        }

        return Row(
          children: [
            Expanded(child: _buildSummaryCard('App Usage Charge', 'Rs. ${appUsageCharge.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Savings Balance', 'Rs. ${savingsBalance.toStringAsFixed(2)}', Icons.savings, Colors.green)),
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
            _InfoItem('Rating', '${driver['rating'] ?? 0} (${driver['ratingCount'] ?? 0} reviews)'),
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
    final currentVehicle = driver['currentVehicle'] as Map<String, dynamic>?;
    final vehicleHistory = driver['vehicleHistory'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Current Vehicle'),
          const SizedBox(height: 16),
          if (currentVehicle != null)
            _buildVehicleSection(currentVehicle, isCurrent: true)
          else
            const Text('No current vehicle details available.', style: TextStyle(color: Colors.grey)),
          
          if (vehicleHistory.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 24),
            _buildSectionTitle('Vehicle History (${vehicleHistory.length})'),
            const SizedBox(height: 16),
            ...vehicleHistory.map((v) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildVehicleSection(v as Map<String, dynamic>),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleSection(Map<String, dynamic> v, {bool isCurrent = false}) {
    final details = v['details'] as Map<String, dynamic>? ?? {};
    final docs = v['documents'] as List<dynamic>? ?? [];
    final photos = v['vehiclePhotos'] as Map<String, dynamic>? ?? {};
    
    // License info is usually doc 3, but let's search just in case
    Map<String, dynamic>? licenseData;
    for (var d in docs) {
      if (d is Map<String, dynamic> && d['reviewData'] != null) {
        final review = d['reviewData'] as Map<String, dynamic>;
        if (review.containsKey('License Number')) {
          licenseData = review;
          break;
        }
      }
    }

    // Vehicle basic details
    final brand = details['brand'] ?? '-';
    final model = details['model'] ?? '-';
    final year = details['year'] ?? '-';
    final category = v['selectedCategory'] ?? '-';
    final status = v['status'] ?? '-';
    
    String? approvedAtStr;
    if (v['approvedAt'] != null) {
      // It's likely a Timestamp, so we convert it simply by toString
      approvedAtStr = v['approvedAt'].toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.blue.shade50.withValues(alpha: 0.3) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrent ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoGrid([
            _InfoItem('Brand / Model', '$brand $model'),
            _InfoItem('Manufacture Year', year),
            _InfoItem('Category', category),
            _InfoItem('Approval Status', status.toString().toUpperCase()),
            if (approvedAtStr != null) _InfoItem('Approved At', approvedAtStr),
            if (licenseData != null) _InfoItem('Driving License', licenseData['License Number']),
            if (licenseData != null) _InfoItem('License Expiry', licenseData['Expiry Date']),
            if (licenseData != null && licenseData['LicenseTypes'] != null) 
               _InfoItem('License Types', (licenseData['LicenseTypes'] as List).join(', ')),
          ]),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Vehicle Photos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
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
                          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(e.key, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMembershipFeeTab() {
    final membershipNo = driver['membershipNo'];
    if (membershipNo == null || membershipNo.toString().isEmpty) {
      return const Center(child: Text('No Membership Number found for this driver.'));
    }

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('app_membership_fee').doc(membershipNo).get(),
        FirebaseFirestore.instance.collection('web_sync_membership_fee').doc(membershipNo).get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading fee details: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final appDoc = snapshot.data![0];
        final webDoc = snapshot.data![1];

        if (!appDoc.exists && !webDoc.exists) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No Membership Fee records found.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final appData = appDoc.exists ? (appDoc.data() as Map<String, dynamic>? ?? {}) : {};
        final webData = webDoc.exists ? (webDoc.data() as Map<String, dynamic>? ?? {}) : {};

        final appHistory = appData['payment_history'] as List<dynamic>? ?? [];
        final appPending = appData['pending_payments'] as List<dynamic>? ?? [];

        final webHistoryRaw = webData['payment_history'] as List<dynamic>? ?? [];
        
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
          final sorted = List<Map<String, dynamic>>.from(records.whereType<Map<String, dynamic>>());
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

        // --- CALC UNPAID MONTHS ---
        final joinDateStr = driver['joinDate']?.toString() ?? '';
        DateTime? joinDate;
        try {
          if (joinDateStr.isNotEmpty) joinDate = DateTime.parse(joinDateStr);
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
              final rMonth = (record['month'] ?? '').toString().trim().toLowerCase();
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
              _buildSectionTitle('Membership Fee Summary'),
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
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(child: Text('Cannot calculate arrears because Join Date is missing. Please update the member profile.', style: TextStyle(color: Colors.orange))),
                    ],
                  ),
                )
              else
                _buildFeeSummaryCards(totalMonths, paidMonths, arrearsMonths),

              const SizedBox(height: 32),

              if (unpaidMonthsList.isNotEmpty) ...[
                _buildSectionTitle('Unpaid Months List (${unpaidMonthsList.length})'),
                const SizedBox(height: 16),
                _buildUnpaidMonthsTable(unpaidMonthsList.reversed.toList()), // Z-A order (newest first)
                const SizedBox(height: 32),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 32),
              ],

              _buildSectionTitle('Pending Payments (${allPending.length})'),
              const SizedBox(height: 16),
              if (allPending.isEmpty)
                const Text('No pending payments.', style: TextStyle(color: Colors.grey))
              else
                _buildPaymentTable(allPending),

              const SizedBox(height: 32),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 32),

              _buildSectionTitle('Payment History (${allHistory.length})'),
              const SizedBox(height: 16),
              if (allHistory.isEmpty)
                const Text('No payment history available.', style: TextStyle(color: Colors.grey))
              else
                _buildPaymentTable(allHistory),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeeSummaryCards(int totalMonths, int paidMonths, int arrearsMonths) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Total Months', totalMonths.toString(), Icons.calendar_month, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Paid Months', paidMonths.toString(), Icons.check_circle, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Arrears Months', arrearsMonths.toString(), Icons.error_outline, Colors.red)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.shade600, size: 24),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(color: color.shade800, fontSize: 32, fontWeight: FontWeight.bold)),
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
            DataColumn(label: Text('Month/Year', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
          ],
          rows: unpaidMonths.map((m) {
            return DataRow(
              cells: [
                DataCell(Text('${m['month']} ${m['year']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: const Text('UNPAID / PENDING', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
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
      case 'january': return 1;
      case 'february': return 2;
      case 'march': return 3;
      case 'april': return 4;
      case 'may': return 5;
      case 'june': return 6;
      case 'july': return 7;
      case 'august': return 8;
      case 'september': return 9;
      case 'october': return 10;
      case 'november': return 11;
      case 'december': return 12;
      default: return 0;
    }
  }

  Widget _buildPaymentTable(List<dynamic> payments) {
    // Sort payments by target month/year descending (newest month first)
    final sortedPayments = List<Map<String, dynamic>>.from(payments.whereType<Map<String, dynamic>>());
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
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Month/Year', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Slip', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: sortedPayments.map((p) {
            final month = p['month'] ?? '-';
            final year = p['year'] ?? '';
            final amount = p['amount'] ?? '0';
            final status = (p['status'] ?? '-').toString().toLowerCase();
            final slipUrl = p['slipUrl']?.toString() ?? '';

            Color statusColor = Colors.grey;
            if (status == 'approved') statusColor = Colors.green;
            else if (status == 'pending') statusColor = Colors.orange;
            else if (status == 'rejected') statusColor = Colors.red;

            return DataRow(
              cells: [
                DataCell(Text(p['date'] ?? '-')),
                DataCell(Text('$month $year'.trim())),
                DataCell(Text('Rs. $amount', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['type'] ?? '-', style: const TextStyle(fontSize: 12)),
                    Text(p['source'] ?? '-', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                )),
                DataCell(Text(p['reason'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
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
          .collectionGroup('transactions')
          .where('driverId', isEqualTo: driverId.toString())
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading transactions: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No Transaction History found.', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
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
              _buildSectionTitle('Recent Transactions (${docs.length})'),
              const SizedBox(height: 16),
              SingleChildScrollView(
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
                      DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Trip Ref', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Union Charge', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total Commission', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Driver Earned', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      
                      // Safely parse timestamp
                      String dateTimeStr = '-';
                      if (data['timestamp'] != null) {
                        if (data['timestamp'] is Timestamp) {
                          dateTimeStr = DateFormat('yyyy-MMM-dd hh:mm a').format((data['timestamp'] as Timestamp).toDate());
                        } else {
                          dateTimeStr = data['timestamp'].toString();
                        }
                      }

                      final type = (data['type'] ?? 'Unknown').toString();
                      final tripId = (data['tripId'] ?? '-').toString();
                      
                      // Parse amounts based on finance_transactions schema
                      final totalFare = double.tryParse(data['totalFare']?.toString() ?? '0') ?? 0.0;
                      final driverCommission = double.tryParse(data['driverCommission']?.toString() ?? '0') ?? 0.0;
                      final unionUsageCharge = double.tryParse(data['unionUsageCharge']?.toString() ?? '0') ?? 0.0;
                      final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0; // for auto_settlement

                      double displayCommission = driverCommission > 0 ? driverCommission : amount;
                      double driverEarned = totalFare > 0 ? totalFare - displayCommission : 0.0;

                      return DataRow(
                        cells: [
                          DataCell(Text(dateTimeStr, style: const TextStyle(fontSize: 12))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataCell(Text(tripId, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                          DataCell(Text(unionUsageCharge > 0 ? 'Rs. ${unionUsageCharge.toStringAsFixed(2)}' : '-', style: const TextStyle(color: Colors.red))),
                          DataCell(Text(displayCommission > 0 ? 'Rs. ${displayCommission.toStringAsFixed(2)}' : '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                          DataCell(Text(driverEarned > 0 ? 'Rs. ${driverEarned.toStringAsFixed(2)}' : '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
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
                item.value?.toString().isNotEmpty == true ? item.value.toString() : '-',
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
}

class _InfoItem {
  final String label;
  final dynamic value;

  _InfoItem(this.label, this.value);
}

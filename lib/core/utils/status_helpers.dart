// ignore_for_file: spell_check_on_languages

/// 💰 Checks a driver's 'payment_history' array,
/// Logic engine to verify if the membership fee for the current month is paid before the 5th.
Map<String, dynamic> checkMembershipFeeStatus(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) {
    return {
      'isFeePaidValid': true,
      'reason': '',
    };
  }

  if (!data.containsKey('payment_history') || data['payment_history'] == null) {
    return {
      'isFeePaidValid': true,
      'reason': '',
    };
  }

  final DateTime now = DateTime.now();
  final int currentDay = now.day;

  final List<String> monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  final String currentMonthName = monthNames[now.month - 1];
  final String currentYearStr = now.year.toString();

  final List<dynamic> paymentHistory = data['payment_history'] ?? [];
  final List<dynamic> pendingPayments = data['pending_payments'] ?? [];
  final List<dynamic> allPaymentsToCheck = [...paymentHistory, ...pendingPayments];

  bool hasPaidForCurrentMonth = false;

  for (var payment in allPaymentsToCheck) {
    if (payment is Map) {
      List<String> monthsToCheck = [];
      if (payment.containsKey('months') && payment['months'] is List) {
        monthsToCheck = (payment['months'] as List).map((m) => m.toString().trim().toLowerCase()).toList();
      } else {
        String mStr = (payment['month'] ?? '').toString().trim().toLowerCase();
        monthsToCheck = [mStr];
        if (int.tryParse(mStr) != null) {
          int mInt = int.parse(mStr);
          if (mInt >= 1 && mInt <= 12) {
            monthsToCheck.add(monthNames[mInt - 1].toLowerCase());
          }
        }
      }

      final String pYear = (payment['year'] ?? '').toString().trim();
      final String pReason = (payment['reason'] ?? payment['type'] ?? '').toString().trim().toLowerCase();

      bool isMembershipPayment = pReason.isEmpty || 
                                 pReason.contains('membership') || 
                                 pReason.contains('fee') || 
                                 pReason.contains('monthly');

      if (monthsToCheck.contains(currentMonthName.toLowerCase()) &&
          (pYear == currentYearStr || pYear.isEmpty) &&
          isMembershipPayment) {
        hasPaidForCurrentMonth = true;
        break;
      }
    }
  }

  if (currentDay >= 5 && !hasPaidForCurrentMonth) {
    return {
      'isFeePaidValid': false,
      'reason': 'Pending Membership Fee 💰',
    };
  }

  return {
    'isFeePaidValid': true,
    'reason': '',
  };
}

class PersonalKYCChecker {
  static Map<String, dynamic> checkKYCStatus(Map<String, dynamic>? memberData) {
    if (memberData == null || memberData.isEmpty) {
      return {
        'isVerified': false,
        'isFullyVerified': false,
        'isAdminApproved': false,
        'isFaceApproved': false,
        'showPendingScreen': false,
        'reason': "Loading profile data...",
      };
    }

    final bool isDetailsSubmitted =
        memberData['isDetailsSubmitted'] == true ||
            memberData['kycApprovalStatus']?.toString().toLowerCase() == 'pending';

    final String kycApproval =
        memberData['kycApprovalStatus']?.toString().toLowerCase() ?? 'none';

    final String mainStatus =
        memberData['status']?.toString().toLowerCase() ?? 'pending';

    final String faceStatus =
        memberData['faceKycStatus']?.toString().toLowerCase() ?? 'none';

    final bool isAdminApproved =
        kycApproval == 'approved' || mainStatus == 'active' || mainStatus == 'active member';

    final bool isFaceApproved = faceStatus == 'approved';
    final bool isAdminRejected = kycApproval == 'rejected';
    final bool isFaceRejected = faceStatus == 'rejected';
    final bool isRejected = isAdminRejected || isFaceRejected;

    final bool isFullyVerified = isAdminApproved && isFaceApproved;

    final bool showPendingScreen =
        isDetailsSubmitted ||
            kycApproval == 'pending' ||
            faceStatus == 'pending' ||
            isRejected ||
            isFullyVerified;

    String reason;

    if (isRejected) {
      if (isAdminRejected && isFaceRejected) {
        reason = "Personal details and face verification rejected ❌";
      } else if (isAdminRejected) {
        reason = memberData['kycRejectReason']?.toString() ??
            "Personal details rejected by admin ❌";
      } else {
        reason = memberData['faceRejectReason']?.toString() ??
            "Face verification failed. Please scan again ❌";
      }
    } else if (isFullyVerified) {
      reason = "Profile fully verified ✅";
    } else if (!isDetailsSubmitted && kycApproval == 'none') {
      reason = "Please complete your one-time registration and face verification 📋";
    } else if (!isAdminApproved && !isFaceApproved) {
      reason = "Personal details pending admin approval and face scan pending ⏳";
    } else if (!isAdminApproved) {
      reason = "Personal details pending admin approval ⏳";
    } else if (!isFaceApproved) {
      reason = "Face verification pending. Please complete live face scan 📸";
    } else {
      reason = "Verification pending ⏳";
    }

    return {
      'isVerified': isFullyVerified,
      'isFullyVerified': isFullyVerified,
      'isAdminApproved': isAdminApproved,
      'isFaceApproved': isFaceApproved,
      'isRejected': isRejected,
      'isAdminRejected': isAdminRejected,
      'isFaceRejected': isFaceRejected,
      'showPendingScreen': showPendingScreen,
      'reason': reason,
    };
  }
}

const List<String> requiredComplianceDocs = [
  'Revenue License',
  'Insurance Policy',
  'Registration Document',
  'Driving License',
];

Map<String, dynamic> checkMemberSystemStatus(Map<String, dynamic>? memberData) {
  if (memberData == null || memberData.isEmpty) {
    return {
      'isActive': false,
      'reason': 'Vehicle documents not found',
    };
  }

  final dynamic rawDocuments =
      memberData['documents'] ?? memberData['complianceDocuments'];

  if (rawDocuments is List) {
    for (int i = 0; i < requiredComplianceDocs.length; i++) {
      final String requiredDoc = requiredComplianceDocs[i];

      if (i >= rawDocuments.length) {
        return {
          'isActive': false,
          'reason': '$requiredDoc not uploaded',
        };
      }

      final item = rawDocuments[i];

      if (item == null || item is! Map) {
        return {
          'isActive': false,
          'reason': '$requiredDoc not uploaded',
        };
      }

      final String status =
          item['status']?.toString().trim().toLowerCase() ?? 'empty';

      if (status == 'empty') {
        return {
          'isActive': false,
          'reason': '$requiredDoc not uploaded',
        };
      }

      if (status == 'pending') {
        return {
          'isActive': false,
          'reason': '$requiredDoc pending admin approval',
        };
      }

      if (status == 'rejected') {
        return {
          'isActive': false,
          'reason': '$requiredDoc rejected',
        };
      }

      if (status != 'approved') {
        return {
          'isActive': false,
          'reason': '$requiredDoc not approved',
        };
      }

      if (_isDocumentExpired(item)) {
        return {
          'isActive': false,
          'reason': '$requiredDoc is expired',
        };
      }
    }

    return {
      'isActive': true,
      'reason': 'Success',
    };
  }

  if (rawDocuments is Map) {
    for (final String title in requiredComplianceDocs) {
      final dynamic item = rawDocuments[title];

      if (item is! Map) {
        return {
          'isActive': false,
          'reason': '$title not uploaded',
        };
      }

      final String status =
          item['status']?.toString().trim().toLowerCase() ?? 'empty';

      if (status == 'pending') {
        return {
          'isActive': false,
          'reason': '$title pending admin approval',
        };
      }

      if (status == 'rejected') {
        return {
          'isActive': false,
          'reason': '$title rejected',
        };
      }

      if (status != 'approved') {
        return {
          'isActive': false,
          'reason': '$title not approved',
        };
      }

      if (_isDocumentExpired(item)) {
        return {
          'isActive': false,
          'reason': '$title is expired',
        };
      }
    }

    return {
      'isActive': true,
      'reason': 'Success',
    };
  }

  return {
    'isActive': false,
    'reason': 'Vehicle documents not found',
  };
}

bool _isDocumentExpired(Map<dynamic, dynamic> document) {
  final dynamic rawReviewData = document['reviewData'];

  final Map<String, dynamic> reviewData = rawReviewData is Map
      ? Map<String, dynamic>.from(rawReviewData)
      : <String, dynamic>{};

  final String? expiryDate = (reviewData['Expiry Date'] ??
          reviewData['expiryDate'] ??
          reviewData['expiry_date'] ??
          document['Expiry Date'] ??
          document['expiryDate'] ??
          document['expiry_date'])
      ?.toString();

  if (expiryDate == null || expiryDate.trim().isEmpty) {
    return false;
  }

  try {
    final String date = expiryDate.trim();

    final List<String> parts = date.contains('.')
        ? date.split('.')
        : date.contains('/')
            ? date.split('/')
            : date.split('-');

    if (parts.length != 3) {
      return false;
    }

    late DateTime expiry;

    if (parts[0].length == 4) {
      expiry = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else {
      expiry = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return expiry.isBefore(today);
  } catch (_) {
    return false;
  }
}

Map<String, dynamic> calculateMemberStatus(Map<String, dynamic> activeData) {
  // If the Member app has already calculated and synced the profile_status, use it directly!
  if (activeData.containsKey('profile_status')) {
    final bool isActive = activeData['profile_status'] == 'active member';
    
    String reasonStr = '';
    if (activeData['inactive_reasons'] is List) {
       final reasons = List<String>.from(activeData['inactive_reasons']);
       reasonStr = reasons.join(' • ');
    } else {
       reasonStr = activeData['inactiveReason']?.toString() ?? '';
    }

    return {
      'isActive': isActive,
      'reason': reasonStr,
      'source': 'synced_profile_status',
    };
  }

  // Fallback for members who haven't updated their app yet
  List<String> reasons = [];
  bool isActive = true;

  final Map<String, dynamic> feeCheck = checkMembershipFeeStatus(activeData);
  if (feeCheck['isFeePaidValid'] == false) {
    isActive = false;
    reasons.add(feeCheck['reason'] ?? 'Membership fee verification required.');
  }

  final Map<String, dynamic> kycCheck = PersonalKYCChecker.checkKYCStatus(activeData);
  if (kycCheck['isVerified'] == false) {
    isActive = false;
    if (kycCheck['reason'] != null && kycCheck['reason'] != "Verification pending ⏳") {
      reasons.add(kycCheck['reason']);
    } else {
      reasons.add("Personal profile or face verification pending.");
    }
  }

  // Profile image check
  final String profileImageUrl = activeData['profileImageUrl']?.toString() ?? activeData['imageUrl']?.toString() ?? '';
  if (profileImageUrl.isEmpty) {
    isActive = false;
    reasons.add("Profile image is not uploaded.");
  }

  final Map<String, dynamic> vehicleCheck = checkMemberSystemStatus(activeData);
  if (vehicleCheck['isActive'] == false) {
    isActive = false;
    reasons.add(vehicleCheck['reason'] ?? 'Vehicle documents not found');
  }

  // Check admin explicitly blocked
  final String adminApproval = activeData['adminApproval']?.toString().toLowerCase() ?? '';
  final String status = activeData['status']?.toString().toLowerCase() ?? '';
  if (adminApproval == 'rejected' || status == 'blocked' || status == 'rejected') {
    isActive = false;
    reasons.add(activeData['inactiveReason']?.toString() ?? activeData['rejectionReason']?.toString() ?? "Account has been restricted by Admin.");
  }

  return {
    'isActive': isActive,
    'reason': reasons.join(' • '),
    'source': 'legacy_fallback',
  };
}

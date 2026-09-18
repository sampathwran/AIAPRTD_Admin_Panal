import 'dart:io';

void main() {
  final kycFile = File('lib/features/driver/activation_requests/kyc_verification_requests.dart');
  String kycContent = kycFile.readAsStringSync();

  kycContent = kycContent.replaceAll(
    "if (selectedStatus != 'all') {\n      query = query.where('kycApprovalStatus', isEqualTo: selectedStatus);\n    }",
    "if (selectedStatus == 'pending') {\n      query = query.where('kycApprovalStatus', whereIn: ['pending', 'pending_approval']);\n    } else if (selectedStatus != 'all') {\n      query = query.where('kycApprovalStatus', isEqualTo: selectedStatus);\n    }"
  );

  kycFile.writeAsStringSync(kycContent);
  print('Fixed kyc_verification_requests.dart');

  final requestListFile = File('lib/features/driver/activation_requests/request_list.dart');
  String requestListContent = requestListFile.readAsStringSync();

  requestListContent = requestListContent.replaceAll(
    "if (_lastStatus != 'all') {\n      query = query.where('status', isEqualTo: _lastStatus);\n    }",
    "if (_lastStatus == 'pending') {\n      query = query.where('status', whereIn: ['pending', 'pending_approval']);\n    } else if (_lastStatus != 'all') {\n      query = query.where('status', isEqualTo: _lastStatus);\n    }"
  );

  requestListFile.writeAsStringSync(requestListContent);
  print('Fixed request_list.dart');
}

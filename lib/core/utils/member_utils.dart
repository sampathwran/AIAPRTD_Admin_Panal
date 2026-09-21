String getMemberFullName(Map<String, dynamic>? member) {
  if (member == null) return 'Unknown';
  String fullName = member['fullName']?.toString().trim() ?? '';
  if (fullName.isNotEmpty) return fullName;
  String name = member['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  String fName = member['first_name']?.toString().trim() ?? member['firstName']?.toString().trim() ?? '';
  String lName = member['last_name']?.toString().trim() ?? member['lastName']?.toString().trim() ?? '';
  if (fName.isNotEmpty || lName.isNotEmpty) return "$fName $lName".trim();
  return 'Unknown';
}
bool matchesSearchQuery(Map<String, dynamic> member, String queryStr) {
  final query = queryStr.trim().toLowerCase();
  if (query.isEmpty) return true;
  
  final cleanQuery = query.replaceAll(RegExp(r'[^a-z0-9]'), '');

  final membershipNo = (member['membershipNo'] ?? '').toString().toLowerCase();
  final fullName = getMemberFullName(member).toLowerCase();
  final mobile = (member['mobile'] ?? member['phone'] ?? member['phoneNumber'] ?? '').toString().toLowerCase();
  final email = (member['email'] ?? member['user_email'] ?? '').toString().toLowerCase();
  final nic = (member['nic'] ?? '').toString().toLowerCase();
  
  String vehicleNo = '';
  if (member['currentVehicle'] is Map) {
    final cv = member['currentVehicle'] as Map;
    if (cv['details'] is Map && cv['details']['vehicleNumber'] != null) {
      vehicleNo = cv['details']['vehicleNumber'].toString().toLowerCase();
    } else if (cv['vehicleNumber'] != null) {
      vehicleNo = cv['vehicleNumber'].toString().toLowerCase();
    }
  } else {
    vehicleNo = (member['vehicleNumber'] ?? '').toString().toLowerCase();
  }

  String clean(String val) => val.replaceAll(RegExp(r'[^a-z0-9]'), '');
  String digitsOnly(String val) => val.replaceAll(RegExp(r'[^0-9]'), '');

  final altMem1 = (member['membership_no'] ?? '').toString().toLowerCase();
  final altMem2 = (member['member_no'] ?? '').toString().toLowerCase();
  
  final queryDigits = digitsOnly(query);

  bool checkMem(String m) {
    if (m.isEmpty) return false;
    if (m.contains(query)) return true;
    if (clean(m).contains(cleanQuery)) return true;
    if (queryDigits.isNotEmpty && digitsOnly(m).contains(queryDigits)) return true;
    return false;
  }

  return checkMem(membershipNo) ||
      checkMem(altMem1) ||
      checkMem(altMem2) ||
      fullName.contains(query) ||
      mobile.contains(query) ||
      clean(mobile).contains(cleanQuery) ||
      email.contains(query) ||
      nic.contains(query) ||
      clean(nic).contains(cleanQuery) ||
      vehicleNo.contains(query) ||
      clean(vehicleNo).contains(cleanQuery);
}

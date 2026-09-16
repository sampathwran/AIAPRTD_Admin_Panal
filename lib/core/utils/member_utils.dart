String getMemberFullName(Map<String, dynamic>? member) {
  if (member == null) return 'Unknown';
  String fullName = member['fullName']?.toString().trim() ?? '';
  if (fullName.isNotEmpty) return fullName;
  String fName = member['first_name']?.toString().trim() ?? member['firstName']?.toString().trim() ?? '';
  String lName = member['last_name']?.toString().trim() ?? member['lastName']?.toString().trim() ?? '';
  if (fName.isNotEmpty || lName.isNotEmpty) return "$fName $lName".trim();
  return 'Unknown';
}
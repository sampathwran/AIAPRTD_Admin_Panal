void main() {
  String membershipNo = 'aiaprtd-26-0901';
  String query = '0901';
  String cleanQuery = '0901';
  String clean(String val) => val.replaceAll(RegExp(r'[^a-z0-9]'), '');
  
  bool match = membershipNo.contains(query) || clean(membershipNo).contains(cleanQuery);
  print(match);
}

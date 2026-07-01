// 💡 SYSTEM FINAL FLEET RATES FILE
// ඇප් එකේ ක්‍රියාත්මක වෙන නිල ගාස්තු (Rates) තනි තැනක තබා ගැනීම මචං.

class VehicleRates {
  static const List<Map<String, dynamic>> activeRates = [
    {
      'id': 'budget',
      'name': 'Budget (Alto/Nano)',
      'baseFare': 150.0,
      'perKm': 85.0,
      'perMinute': 5.0,
      'minimumDistance': 3.0,
    },
    {
      'id': 'mini',
      'name': 'Mini (Axia/Vitz)',
      'baseFare': 180.0,
      'perKm': 95.0,
      'perMinute': 5.0,
      'minimumDistance': 3.0,
    },
    {
      'id': 'sedan',
      'name': 'Sedan (Fit/Civic)',
      'baseFare': 250.0,
      'perKm': 115.0,
      'perMinute': 6.0,
      'minimumDistance': 3.0,
    },
    {
      'id': '6_seater',
      'name': '6 Seater Van',
      'baseFare': 350.0,
      'perKm': 140.0,
      'perMinute': 8.0,
      'minimumDistance': 5.0,
    },
    {
      'id': '9_seater',
      'name': '9 Seater Van',
      'baseFare': 500.0,
      'perKm': 185.0,
      'perMinute': 10.0,
      'minimumDistance': 5.0,
    },
    {
      'id': '14_seater',
      'name': '14 Seater Van',
      'baseFare': 600.0,
      'perKm': 230.0,
      'perMinute': 12.0,
      'minimumDistance': 5.0,
    },
  ];
}
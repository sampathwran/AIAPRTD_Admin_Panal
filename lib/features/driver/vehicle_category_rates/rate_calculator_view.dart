import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Firebase එකතු කළා

class RateCalculatorView extends StatefulWidget {
  const RateCalculatorView({super.key});

  @override
  State<RateCalculatorView> createState() => _RateCalculatorViewState();
}

class _Base {
  static const double petrol = 445.0;
  static const double diesel = 407.0;
}

class _RateCalculatorViewState extends State<RateCalculatorView> {
  // Global Raw Inputs
  double pPrice = 445,
      dPrice = 407,
      lcFactor = 100,
      dailyExp = 1500,
      deadMileage = 20,
      commPct = 20;

  late TextEditingController _petrolCtrl;
  late TextEditingController _dieselCtrl;
  late TextEditingController _lcFactorCtrl;
  late TextEditingController _dailyExpCtrl;
  late TextEditingController _deadMileCtrl;
  late TextEditingController _commPctCtrl;

  final List<Map<String, dynamic>> fleet = [
    {
      'id': 'budget',
      'name': 'Budget (Alto/Nano)',
      'eff': 20,
      'lease': 8000,
      'ins': 50000,
      'maintenance': 10000,
      'salary': 35,
      'profitMargin': 33.55,
    },
    {
      'id': 'mini',
      'name': 'Mini (Axia/Vitz)',
      'eff': 15,
      'lease': 15000,
      'ins': 80000,
      'maintenance': 15000,
      'salary': 40,
      'profitMargin': 31.00,
    },
    {
      'id': 'sedan',
      'name': 'Sedan (Fit/Civic)',
      'eff': 12,
      'lease': 25000,
      'ins': 150000,
      'maintenance': 20000,
      'salary': 45,
      'profitMargin': 34.08,
    },
    {
      'id': '6_seater',
      'name': '6 Seater Van',
      'eff': 10,
      'lease': 20000,
      'ins': 100000,
      'maintenance': 25000,
      'salary': 50,
      'profitMargin': 29.50,
    },
    {
      'id': '9_seater',
      'name': '9 Seater Van',
      'eff': 8.5,
      'lease': 40000,
      'ins': 180000,
      'maintenance': 35000,
      'salary': 60,
      'profitMargin': 44.12,
    },
    {
      'id': '14_seater',
      'name': '14 Seater Van',
      'eff': 6.5,
      'lease': 50000,
      'ins': 220000,
      'maintenance': 45000,
      'salary': 70,
      'profitMargin': 45.31,
    },
  ];

  @override
  void initState() {
    super.initState();
    _petrolCtrl = TextEditingController(text: pPrice.toString());
    _dieselCtrl = TextEditingController(text: dPrice.toString());
    _lcFactorCtrl = TextEditingController(text: lcFactor.toString());
    _dailyExpCtrl = TextEditingController(text: dailyExp.toString());
    _deadMileCtrl = TextEditingController(text: deadMileage.toString());
    _commPctCtrl = TextEditingController(text: commPct.toString());

    _loadFromFirebase(); // 💡 මුලදීම Firebase එකෙන් කලින් Save කරපුවා ගන්නවා
  }

  // 💡 Firebase එකෙන් කියවන Function එක
  Future<void> _loadFromFirebase() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('calculator')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          pPrice = (data['pPrice'] ?? 445).toDouble();
          dPrice = (data['dPrice'] ?? 407).toDouble();
          lcFactor = (data['lcFactor'] ?? 100).toDouble();
          dailyExp = (data['dailyExp'] ?? 1500).toDouble();
          deadMileage = (data['deadMileage'] ?? 20).toDouble();
          commPct = (data['commPct'] ?? 20).toDouble();

          _petrolCtrl.text = pPrice.toString();
          _dieselCtrl.text = dPrice.toString();
          _lcFactorCtrl.text = lcFactor.toString();
          _dailyExpCtrl.text = dailyExp.toString();
          _deadMileCtrl.text = deadMileage.toString();
          _commPctCtrl.text = commPct.toString();
        });
      }
    } catch (e) {
      debugPrint("Error loading calc data: $e");
    }
  }

  // 💡 Firebase එකට Save කරන Function එක
  Future<void> _saveToFirebase() async {
    try {
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('calculator')
          .set({
            'pPrice': pPrice,
            'dPrice': dPrice,
            'lcFactor': lcFactor,
            'dailyExp': dailyExp,
            'deadMileage': deadMileage,
            'commPct': commPct,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Calculator Settings Saved to Cloud! ☁️"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving calc data: $e");
    }
  }

  @override
  void dispose() {
    _petrolCtrl.dispose();
    _dieselCtrl.dispose();
    _lcFactorCtrl.dispose();
    _dailyExpCtrl.dispose();
    _deadMileCtrl.dispose();
    _commPctCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double pChange = ((pPrice - _Base.petrol) / _Base.petrol) * 100;
    double dChange = ((dPrice - _Base.diesel) / _Base.diesel) * 100;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // 📊 1. FUEL PERCENTAGE INDICATOR PANEL
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPercentIndicator("Petrol Change", pChange),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  _buildPercentIndicator("Diesel Change", dChange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 🎛️ 2. GLOBAL INPUTS PANEL (🎯 SELECTABLE & EDITABLE)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildStableField(
                    "Petrol (Rs)",
                    _petrolCtrl,
                    (v) => setState(() => pPrice = v),
                  ),
                  _buildStableField(
                    "Diesel (Rs)",
                    _dieselCtrl,
                    (v) => setState(() => dPrice = v),
                  ),
                  _buildStableField(
                    "Life Cost %",
                    _lcFactorCtrl,
                    (v) => setState(() => lcFactor = v),
                  ),
                  _buildStableField(
                    "Daily Exp",
                    _dailyExpCtrl,
                    (v) => setState(() => dailyExp = v),
                  ),
                  _buildStableField(
                    "Dead Mile %",
                    _deadMileCtrl,
                    (v) => setState(() => deadMileage = v),
                  ),
                  _buildStableField(
                    "Comm %",
                    _commPctCtrl,
                    (v) => setState(() => commPct = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 💡 3. SAVE BUTTON (අලුතින් දැම්මා)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1B2735),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text(
              "Save Calculator Config to Cloud",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _saveToFirebase,
          ),
          const SizedBox(height: 20),

          // 🚗 4. VEHICLE CARDS FLEET LIST
          ...fleet.map((v) => _buildVehicleCard(v)),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v) {
    double fuel =
        ((v['id'] == '9_seater' || v['id'] == '14_seater' ? dPrice : pPrice) /
        v['eff']);
    double fixedExp = (v['lease'] + (v['ins'] / 12) + v['maintenance']) / 5000;
    double varExp = ((dailyExp * 26) / 5000) + (v['salary'] * (lcFactor / 100));
    double dead = (fuel + (10 * (lcFactor / 100))) * (deadMileage / 100);
    double totalCost = fuel + fixedExp + varExp + dead;

    double finalFare = (totalCost + v['profitMargin']) / (1 - (commPct / 100));
    double commission = finalFare * (commPct / 100);
    double netProfit = finalFare - commission - totalCost;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          v['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          "මගියාගෙන් අය කරන ගාස්තුව: රු. ${finalFare.round()}/km",
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        children: [
          const Divider(height: 1),
          _infoRow("ඉන්ධන පිරිවැය", fuel),
          _infoRow("ස්ථාවර වියදම් (Lease/Ins)", fixedExp),
          _infoRow("නඩත්තු/වැටුප්/දෛනික", varExp),
          _infoRow("Dead Mileage පිරිවැය", dead),
          const Divider(thickness: 1, indent: 16, endIndent: 16),
          _infoRow("සම්පූර්ණ පිරිවැය (Total Cost)", totalCost, isBold: true),
          _infoRow("කොමිස් (Commission)", commission),
          _infoRow(
            "රියදුරුගේ ලාභය (Net Profit)",
            netProfit,
            isBold: true,
            color: Colors.green,
          ),
          const Divider(thickness: 1.5, indent: 16, endIndent: 16),
          _infoRow(
            "මගියාගෙන් අය කළ යුතු මුදල",
            finalFare,
            isBold: true,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    double val, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          Text(
            "රු. ${val.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStableField(
    String label,
    TextEditingController controller,
    Function(double) onChanged,
  ) {
    return SizedBox(
      width: 102,
      height: 42,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
        ),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) {
          double? parsedValue = double.tryParse(v);
          if (parsedValue != null) {
            onChanged(parsedValue);
          }
        },
      ),
    );
  }

  Widget _buildPercentIndicator(String title, double percentage) {
    bool isUp = percentage > 0;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              percentage == 0
                  ? Icons.remove_rounded
                  : (isUp
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded),
              color: percentage == 0
                  ? Colors.grey
                  : (isUp ? Colors.red : Colors.green),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              "${percentage == 0 ? '' : (isUp ? '+' : '')}${percentage.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: percentage == 0
                    ? Colors.grey
                    : (isUp ? Colors.red : Colors.green),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveSystemRatesView extends StatelessWidget {
  const ActiveSystemRatesView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> categoryNames = {
      'budget': 'Budget (Alto/Nano)',
      'mini': 'Mini (Axia/Vitz)',
      'sedan': 'Sedan (Fit/Civic)',
      '6_seater': '6 Seater Van',
      '9_seater': '9 Seater Van',
      '14_seater': '14 Seater Van',
    };

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rates').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xff1B2735)));
        }

        List<Map<String, dynamic>> finalRates = [
          {'id': 'budget', 'name': 'Budget (Alto/Nano)', 'baseFare': 150.0, 'baseDistance': 5.0, 'perKm': 85.0, 'perMinute': 5.0, 'nightPct': 5.0, 'peakPct': 5.0},
          {'id': 'mini', 'name': 'Mini (Axia/Vitz)', 'baseFare': 180.0, 'baseDistance': 5.0, 'perKm': 95.0, 'perMinute': 5.0, 'nightPct': 5.0, 'peakPct': 5.0},
          {'id': 'sedan', 'name': 'Sedan (Fit/Civic)', 'baseFare': 250.0, 'baseDistance': 5.0, 'perKm': 115.0, 'perMinute': 6.0, 'nightPct': 5.0, 'peakPct': 5.0},
          {'id': '6_seater', 'name': '6 Seater Van', 'baseFare': 350.0, 'baseDistance': 5.0, 'perKm': 140.0, 'perMinute': 8.0, 'nightPct': 5.0, 'peakPct': 5.0},
          {'id': '9_seater', 'name': '9 Seater Van', 'baseFare': 500.0, 'baseDistance': 5.0, 'perKm': 185.0, 'perMinute': 10.0, 'nightPct': 5.0, 'peakPct': 5.0},
          {'id': '14_seater', 'name': '14 Seater Van', 'baseFare': 600.0, 'baseDistance': 5.0, 'perKm': 230.0, 'perMinute': 12.0, 'nightPct': 5.0, 'peakPct': 5.0},
        ];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            final dbData = doc.data() as Map<String, dynamic>;
            final String id = doc.id;

            int index = finalRates.indexWhere((element) => element['id'] == id);
            if (index != -1) {
              finalRates[index]['baseFare'] = double.tryParse(dbData['baseFare'].toString()) ?? finalRates[index]['baseFare'];
              finalRates[index]['baseDistance'] = double.tryParse(dbData['baseDistance'].toString()) ?? finalRates[index]['baseDistance'];
              finalRates[index]['perKm'] = double.tryParse(dbData['perKm'].toString()) ?? finalRates[index]['perKm'];
              finalRates[index]['perMinute'] = double.tryParse(dbData['perMinute'].toString()) ?? finalRates[index]['perMinute'];
              finalRates[index]['nightPct'] = double.tryParse(dbData['nightFarePct'].toString()) ?? finalRates[index]['nightPct'];
              finalRates[index]['peakPct'] = double.tryParse(dbData['peakFarePct'].toString()) ?? finalRates[index]['peakPct'];
            }
          }
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(14),
          itemCount: finalRates.length,
          itemBuilder: (context, index) {
            final rateMap = finalRates[index];
            return RateEditCard(
              rateData: rateMap,
              displayName: categoryNames[rateMap['id']] ?? rateMap['name'],
            );
          },
        );
      },
    );
  }
}

class RateEditCard extends StatefulWidget {
  final Map<String, dynamic> rateData;
  final String displayName;
  const RateEditCard({super.key, required this.rateData, required this.displayName});

  @override
  State<RateEditCard> createState() => _RateEditCardState();
}

class _RateEditCardState extends State<RateEditCard> {
  late TextEditingController _baseFareCtrl;
  late TextEditingController _baseDistCtrl;
  late TextEditingController _perKmCtrl;
  late TextEditingController _perMinCtrl;
  late TextEditingController _nightCtrl;
  late TextEditingController _peakCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant RateEditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rateData != widget.rateData) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    _baseFareCtrl = TextEditingController(text: widget.rateData['baseFare'].toString());
    _baseDistCtrl = TextEditingController(text: widget.rateData['baseDistance'].toString());
    _perKmCtrl = TextEditingController(text: widget.rateData['perKm'].toString());
    _perMinCtrl = TextEditingController(text: widget.rateData['perMinute'].toString());
    _nightCtrl = TextEditingController(text: widget.rateData['nightPct'].toString());
    _peakCtrl = TextEditingController(text: widget.rateData['peakPct'].toString());
  }

  void _disposeControllers() {
    _baseFareCtrl.dispose();
    _baseDistCtrl.dispose();
    _perKmCtrl.dispose();
    _perMinCtrl.dispose();
    _nightCtrl.dispose();
    _peakCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1B2735)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    widget.rateData['id'].toString().toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildEditField("Base Fare (Rs)", _baseFareCtrl),
                _buildEditField("Starting KM", _baseDistCtrl),
                _buildEditField("After 1 KM (Rs)", _perKmCtrl),
                _buildEditField("Waiting 1 Min", _perMinCtrl),
                _buildEditField("Night Fare %", _nightCtrl),
                _buildEditField("Peak Time %", _peakCtrl),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1B2735),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text("Update Live Rates", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  double baseFare = double.tryParse(_baseFareCtrl.text) ?? widget.rateData['baseFare'];
                  double baseDistance = double.tryParse(_baseDistCtrl.text) ?? widget.rateData['baseDistance'];
                  double perKm = double.tryParse(_perKmCtrl.text) ?? widget.rateData['perKm'];
                  double perMinute = double.tryParse(_perMinCtrl.text) ?? widget.rateData['perMinute'];
                  double nightFarePct = double.tryParse(_nightCtrl.text) ?? widget.rateData['nightPct'];
                  double peakFarePct = double.tryParse(_peakCtrl.text) ?? widget.rateData['peakPct'];

                  try {
                    // 💡 කෙලින්ම Firebase 'rates' Collection එකට Save කරනවා!
                    // වෙනම Provider එකක් ඕනේ නෑ.
                    await FirebaseFirestore.instance.collection('rates').doc(widget.rateData['id']).set({
                      'id': widget.rateData['id'],
                      'name': widget.rateData['name'],
                      'baseFare': baseFare,
                      'baseDistance': baseDistance,
                      'perKm': perKm,
                      'perMinute': perMinute,
                      'nightFarePct': nightFarePct,
                      'peakFarePct': peakFarePct,
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${widget.displayName} Rates Locked & Active in Cloud! 🚀"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("❌ Firebase Upload Error: $e");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return SizedBox(
      width: 105,
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}
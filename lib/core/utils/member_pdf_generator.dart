import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MemberPdfGenerator {
  static Future<void> downloadMemberProfile(Map<String, dynamic> driver) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(driver),
            pw.SizedBox(height: 20),
            _buildPersonalDetails(driver),
            pw.SizedBox(height: 20),
            _buildVehicleDetails(driver),
            pw.SizedBox(height: 20),
            _buildMembershipFeeDetails(driver),
            pw.SizedBox(height: 20),
            _buildTransactionHistory(driver),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Member_Profile_${driver['membershipNo'] ?? 'Unknown'}.pdf',
    );
  }

  static Future<void> downloadCertifiedIncomeReport(Map<String, dynamic> driver, List<QueryDocumentSnapshot> transactionsDocs) async {
    final pdf = pw.Document();

    final name = driver['fullName']?.toString() ?? driver['firstName']?.toString() ?? 'N/A';
    final mNo = driver['membershipNo']?.toString() ?? 'N/A';
    final nic = driver['nic']?.toString() ?? 'N/A';
    
    final currentVehicle = driver['currentVehicle'] as Map<String, dynamic>? ?? {};
    final vDetails = currentVehicle['details'] as Map<String, dynamic>? ?? {};
    final vNo = vDetails['number']?.toString() ?? 'N/A';
    
    double totalEarned = 0.0;
    final List<List<String>> tableData = [];
    
    for (var doc in transactionsDocs) {
      final data = doc.data() as Map<String, dynamic>;
      
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
      final driverEarned = double.tryParse(data['driverCommission']?.toString() ?? '0') ?? 0.0;
      
      totalEarned += driverEarned;
      
      tableData.add([
        dateTimeStr,
        type,
        tripId,
        'Rs. ${driverEarned.toStringAsFixed(2)}'
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(
               child: pw.Text('All Island AP Route Transport Drivers Union', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
               child: pw.Text('Certified Income Report (Hires)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
               child: pw.Text('Date Generated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Driver Name: $name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Membership No: $mNo'),
                      pw.SizedBox(height: 4),
                      pw.Text('NIC: $nic'),
                      pw.SizedBox(height: 4),
                      pw.Text('Vehicle No: $vNo'),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Earned', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      pw.Text('Rs. ${totalEarned.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ]
                  )
                ]
              )
            ),
            pw.SizedBox(height: 24),
            pw.Text('Transaction Ledger', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Date & Time', 'Type', 'Trip Ref', 'Driver Earned'],
              data: tableData,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Union Seal', style: const pw.TextStyle(fontSize: 10)),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text('This is a computer-generated certified document and does not require physical signature unless requested.', 
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Certified_Income_Report_${driver['membershipNo'] ?? 'Unknown'}.pdf',
    );
  }

  static pw.Widget _buildHeader(Map<String, dynamic> driver) {
    final name = driver['fullName']?.toString() ?? driver['firstName']?.toString() ?? 'N/A';
    final mNo = driver['membershipNo']?.toString() ?? 'N/A';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('AIAPRTD Member Profile', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 8),
        pw.Text(name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('Membership No: $mNo', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  static pw.Widget _buildPersonalDetails(Map<String, dynamic> driver) {
    String joinDateStr = 'N/A';
    if (driver['createdAt'] != null) {
      try {
        final ts = driver['createdAt'] as Timestamp;
        final date = ts.toDate();
        joinDateStr = DateFormat('yyyy-MM-dd').format(date);
      } catch (_) {}
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Details'),
        _buildRow('Join Date', joinDateStr),
        _buildRow('NIC Number', driver['nic']?.toString() ?? 'N/A'),
        _buildRow('Mobile Number', driver['mobile']?.toString() ?? 'N/A'),
        _buildRow('Email', driver['email']?.toString() ?? 'N/A'),
        _buildRow('Gender', driver['gender']?.toString() ?? 'N/A'),
        _buildRow('Date of Birth', driver['dob']?.toString() ?? 'N/A'),
        _buildRow('Address', driver['address']?.toString() ?? 'N/A'),
      ],
    );
  }

  static pw.Widget _buildVehicleDetails(Map<String, dynamic> driver) {
    final currentVehicle = driver['currentVehicle'] as Map<String, dynamic>? ?? {};
    final vDetails = currentVehicle['details'] as Map<String, dynamic>? ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Vehicle Details'),
        _buildRow('Vehicle Category', vDetails['category']?.toString() ?? 'N/A'),
        _buildRow('Vehicle Number', vDetails['number']?.toString() ?? 'N/A'),
        _buildRow('Make & Model', '${vDetails['make'] ?? ''} ${vDetails['model'] ?? ''}'.trim()),
        _buildRow('Color', vDetails['color']?.toString() ?? 'N/A'),
        _buildRow('Fuel Type', vDetails['fuelType']?.toString() ?? 'N/A'),
      ],
    );
  }

  static pw.Widget _buildMembershipFeeDetails(Map<String, dynamic> driver) {
    final paymentHistory = driver['payment_history'] as List<dynamic>? ?? [];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Membership Fee'),
        paymentHistory.isEmpty
            ? pw.Text('No payment history found.', style: const pw.TextStyle(fontSize: 12))
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: paymentHistory.take(5).map((payment) {
                  if (payment is! Map) return pw.SizedBox();
                  final month = payment['month']?.toString() ?? '-';
                  final year = payment['year']?.toString() ?? '-';
                  final status = payment['status']?.toString() ?? 'Unknown';
                  final reason = payment['reason']?.toString() ?? payment['type']?.toString() ?? 'Fee';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('$month $year', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(reason, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(status.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  static pw.Widget _buildTransactionHistory(Map<String, dynamic> driver) {
    final p2p = driver['p2p_transactions'] as List<dynamic>? ?? [];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transaction History (Recent 5)'),
        p2p.isEmpty
            ? pw.Text('No transactions found.', style: const pw.TextStyle(fontSize: 12))
            : pw.Column(
                children: p2p.take(5).map((tx) {
                  if (tx is! Map) return pw.SizedBox();
                  final type = tx['type']?.toString().toUpperCase() ?? 'UNKNOWN';
                  final amount = tx['amount']?.toString() ?? '0';
                  final ref = tx['reference']?.toString() ?? '-';
                  String dt = '-';
                  if (tx['createdAt'] != null) {
                    try {
                      final ts = tx['createdAt'] as Timestamp;
                      dt = DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate());
                    } catch (_) {}
                  }
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(dt, style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(type, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs. $amount', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Ref: $ref', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}

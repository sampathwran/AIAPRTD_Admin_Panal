import 'csv_exporter_stub.dart'
    if (dart.library.html) 'csv_exporter_web.dart' as exporter;

void exportToCsv(String fileName, String csvData) {
  exporter.downloadCsv(fileName, csvData);
}

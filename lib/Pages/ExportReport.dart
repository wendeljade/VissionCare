import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math' show pi, cos, sin;
import '../database/database_helper.dart';
import 'package:open_file/open_file.dart';
import '../utils/date_format_utils.dart';
import '../widgets/language_selector.dart';

class ExportReport extends StatefulWidget {
  const ExportReport({Key? key}) : super(key: key);

  @override
  State<ExportReport> createState() => _ExportReportState();
}

class _ExportReportState extends State<ExportReport> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _lastExportedFilePath;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _openExportedFile() async {
    if (_lastExportedFilePath != null) {
      final file = File(_lastExportedFilePath!);
      if (await file.exists()) {
        final result = await OpenFile.open(_lastExportedFilePath!);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')),
            );
          }
        }
      }
    }
  }

  pw.Widget _buildDistributionChart(Map<String, int> diseaseCount, double total) {
    final List<pw.TableRow> rows = [];
    
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Disease',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Count',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Percentage',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Distribution',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // Add data rows
    diseaseCount.forEach((disease, count) {
      final percentage = (count / total * 100).toStringAsFixed(1);
      final barWidth = (count / total * 50).round(); // Max 50 characters for the bar
      final bar = '█' * barWidth;
      
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(disease),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(count.toString()),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('$percentage%'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(bar),
            ),
          ],
        ),
      );
    });

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: pw.FlexColumnWidth(2), // Disease
        1: pw.FlexColumnWidth(1), // Count
        2: pw.FlexColumnWidth(1), // Percentage
        3: pw.FlexColumnWidth(3), // Distribution bar
      },
      children: rows,
    );
  }

  pw.Widget _buildPieChart(Map<String, int> diseaseCount, double total) {
    // Create a simple visual representation using colored boxes
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: diseaseCount.entries.toList().asMap().entries.map((entry) {
        final disease = entry.value.key;
        final count = entry.value.value;
        final percentage = (count / total * 100).toStringAsFixed(1);
        
        // Use different colors for each disease
        final colors = [
          PdfColors.blue300,
          PdfColors.green300,
          PdfColors.amber300,
          PdfColors.pink300,
          PdfColors.purple300,
          PdfColors.teal300,
          PdfColors.red300,
          PdfColors.indigo300,
        ];
        
        final color = colors[entry.key % colors.length];
        final barWidth = (double.parse(percentage) * 2).round(); // Scale the bar width
        
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                color: color,
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                flex: 3,
                child: pw.Text('$disease: $count ($percentage%)'),
              ),
              pw.Expanded(
                flex: 7,
                child: pw.Container(
                  height: 15,
                  width: barWidth.toDouble(),
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildTrendChart(List<Map<String, dynamic>> diagnoses) {
    // Group diagnoses by date
    final Map<String, Map<String, int>> dateData = {};
  
    // Process last 7 days of data
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MM/dd').format(date);
      dateData[dateStr] = {};
    }
  
    // Count diagnoses by date and disease
    for (final diagnosis in diagnoses) {
      final date = DateTime.parse(diagnosis['date']);
      final dateStr = DateFormat('MM/dd').format(date);
      final disease = diagnosis['disease'] as String;
    
      if (dateData.containsKey(dateStr)) {
        dateData[dateStr]![disease] = (dateData[dateStr]![disease] ?? 0) + 1;
      }
    }
  
    // Create a simpler bar chart using a table with visual bars
    final List<pw.TableRow> rows = [];
  
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Date',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          ...dateData.keys.map((date) => 
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                date,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            )
          ).toList(),
        ],
      ),
    );
  
    // Get all unique diseases
    final allDiseases = <String>{};
    for (final dateEntry in dateData.entries) {
      allDiseases.addAll(dateEntry.value.keys);
    }
  
    // Add data rows for each disease
    for (final disease in allDiseases) {
      final List<pw.Widget> cells = [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(disease),
        ),
      ];
    
      for (final dateStr in dateData.keys) {
        final count = dateData[dateStr]![disease] ?? 0;
        final bar = '█' * count; // Simple visual bar
        
        cells.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('$count $bar'),
          ),
        );
      }
    
      rows.add(pw.TableRow(children: cells));
    }
  
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: rows,
    );
  }

  Future<void> _exportToPDF() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final diagnoses = await _databaseHelper.getDiagnoses();
      final filteredDiagnoses = diagnoses.where((diagnosis) {
        final diagnosisDate = DateTime.parse(diagnosis['date']);
        return diagnosisDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               diagnosisDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      if (filteredDiagnoses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_diagnoses_found'.tr())),
        );
        return;
      }

      // Get the current locale's language code
      final String currentLocale = context.locale.languageCode;

      // Calculate disease distribution
      final Map<String, int> diseaseCount = {};
      for (var diagnosis in filteredDiagnoses) {
        final disease = diagnosis['disease'] as String;
        diseaseCount[disease] = (diseaseCount[disease] ?? 0) + 1;
      }
      final total = filteredDiagnoses.length.toDouble();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Corn Disease Detection Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      DateFormatUtils.formatDate(DateTime.now(), currentLocale, 'MMM d, yyyy'),
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Report Period: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${DateFormatUtils.formatDate(_startDate!, currentLocale, 'MMM d, yyyy')} - ${DateFormatUtils.formatDate(_endDate!, currentLocale, 'MMM d, yyyy')}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Disease Distribution Analysis',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildDistributionChart(diseaseCount, total),
              pw.SizedBox(height: 20),
              pw.Text(
                'Disease Distribution',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildPieChart(diseaseCount, total),
              pw.SizedBox(height: 30),
              pw.Text(
                'Disease Trend (Last 7 Days)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildTrendChart(filteredDiagnoses),
              pw.SizedBox(height: 30),
              pw.Text(
                'Detailed Diagnosis Records',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FlexColumnWidth(2), // Date & Time
                  1: pw.FlexColumnWidth(1.5), // Disease
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date & Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Disease',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...filteredDiagnoses.map((diagnosis) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            DateFormatUtils.formatDate(DateTime.parse(diagnosis['date']), currentLocale, 'MMM d, yyyy - HH:mm'),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(diagnosis['disease']),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Summary Statistics',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Bullet(text: 'Total diagnoses in period: ${filteredDiagnoses.length}'),
              ...diseaseCount.entries.map((entry) => pw.Bullet(
                text: '${entry.key}: ${entry.value} cases (${(entry.value / total * 100).toStringAsFixed(1)}%)',
              )),
            ];
          },
        ),
      );

      // Save to Downloads directory
      final output = await getExternalStorageDirectory();
      final fileName = 'corn_disease_report_${DateFormatUtils.formatDate(DateTime.now(), currentLocale, 'yyyyMMdd_HHmmss')}.pdf';
      final filePath = '${output?.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _lastExportedFilePath = filePath;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Report Exported Successfully'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File saved as:'),
                  SizedBox(height: 8),
                  Text(
                    fileName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Location:'),
                  SizedBox(height: 8),
                  Text(
                    output?.path ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _openExportedFile();
                    Navigator.of(context).pop();
                  },
                  child: Text('Open'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        title: Text('export_report'.tr()),
        backgroundColor: Colors.green,
        actions: [
          const LanguageSelector(),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_date_range'.tr(),
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: width * 0.04),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('start_date'.tr()),
                      SizedBox(height: width * 0.02),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.03),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(width * 0.02),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate != null
                                    ? DateFormatUtils.formatDate(_startDate!, context.locale.languageCode, 'MMM d, yyyy')
                                    : 'select_date'.tr(),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('end_date'.tr()),
                      SizedBox(height: width * 0.02),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.03),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(width * 0.02),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endDate != null
                                    ? DateFormatUtils.formatDate(_endDate!, context.locale.languageCode, 'MMM d, yyyy')
                                    : 'select_date'.tr(),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: width * 0.06),
            if (_lastExportedFilePath != null)
              Padding(
                padding: EdgeInsets.only(bottom: width * 0.04),
                child: ElevatedButton.icon(
                  onPressed: _openExportedFile,
                  icon: const Icon(Icons.file_open),
                  label: Text('Open Last Exported Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _exportToPDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: width * 0.03,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.02),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'export_to_pdf'.tr(),
                        style: TextStyle(
                          fontSize: width * 0.04,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

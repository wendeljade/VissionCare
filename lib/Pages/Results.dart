import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../database/database_helper.dart';
import 'Dashboard.dart';
import '../widgets/language_selector.dart';  // Import the language selector

class Results extends StatelessWidget {
  final String disease;
  final String date;
  final String imagePath;
  final double? confidence;
  final String? patientName;
  final String? patientId;

  const Results({
    Key? key,
    required this.disease,
    required this.date,
    required this.imagePath,
    this.confidence,
    this.patientName,
    this.patientId,
  }) : super(key: key);

  Future<void> _deleteDiagnosis(BuildContext context) async {
    // ... existing _deleteDiagnosis logic (kept for potential use or cleanup) ...
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    final int confidencePercent = confidence != null ? (confidence! * 100).toInt() : 0;
    
    // Custom Labeling Logic
    String displayDisease = disease;
    if (confidencePercent < 35) {
      displayDisease = 'No Diabetic Retinopathy';
    } else if (confidencePercent >= 35 && confidencePercent <= 69) {
      displayDisease = 'Mild Diabetic Retinopathy';
    } else {
      displayDisease = 'Severe Diabetic Retinopathy';
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF001529), // Match the dark theme
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Warning Icon
                    Icon(
                      confidencePercent < 35 ? Icons.check_circle_outline : Icons.warning_rounded,
                      color: confidencePercent < 35 ? Colors.green : const Color(0xFFFF5252),
                      size: 100,
                    ),
                    const SizedBox(height: 20),

                    // Probability Percentage
                    Text(
                      '$confidencePercent% PROBABILITY',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Disease Name with dynamic color
                    Text(
                      displayDisease.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: confidencePercent < 35 ? Colors.green : const Color(0xFFFF5252),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Urgent Message
                    Text(
                      confidencePercent < 35 
                        ? 'The scan results indicate a low probability of diabetic retinopathy.'
                        : 'Urgent: Please see an Ophthalmologist for verification.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 20),

                    // Patient Information Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'patient_information'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Patient Info Rows
                    _buildInfoRow('Patient', patientName ?? 'N/A'),
                    const SizedBox(height: 15),
                    _buildInfoRow('ID', patientId ?? 'N/A'),

                    const SizedBox(height: 40),

                    // Download Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle PDF Export
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF5ED3F2)),
                            const SizedBox(width: 10),
                            Text(
                              'export_to_pdf'.tr().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Back to Dashboard Link
                    TextButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const Dashboard()),
                        (route) => false,
                      ),
                      child: const Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          color: Color(0xFF5ED3F2),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

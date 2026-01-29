import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:easy_localization/easy_localization.dart';
import '../database/database_helper.dart';
import 'Dashboard.dart';
import '../utils/disease_utils.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'dart:ui' as ui show TextDirection;
import '../widgets/language_selector.dart';  // Import the language selector

class Results extends StatelessWidget {
  final String disease;
  final String date;
  final String imagePath;
  final double? confidence;

  const Results({
    Key? key,
    required this.disease,
    required this.date,
    required this.imagePath,
    this.confidence,
  }) : super(key: key);

  Future<void> _deleteDiagnosis(BuildContext context) async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('confirm_delete'.tr()),
          content: Text('delete_diagnosis_confirmation'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(
                'delete'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Delete the image file if it exists
        if (imagePath.isNotEmpty) {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        }

        // Get the diagnosis ID based on date and disease
        final diagnoses = await dbHelper.getDiagnoses();
        final diagnosis = diagnoses.firstWhere(
          (d) => d['date'] == date && d['disease'] == disease,
          orElse: () => {'id': -1},
        );

        if (diagnosis['id'] != -1) {
          await dbHelper.deleteDiagnosis(diagnosis['id']);
        }

        // Navigate back to Dashboard
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error_deleting_diagnosis'.tr())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EFE8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          ),
        ),
        title: Text('result'.tr()),
        centerTitle: true,
        actions: [
          // Add language selector to the app bar
          const LanguageSelector(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disease Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: imagePath.isNotEmpty
                    ? Image.file(
                        File(imagePath),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Text(
                                'Image not available',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Text(
                            'No image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              ),

              // Disease Title and Type
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'maize',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Disease Description
                    _buildDiseaseDescription(),

                    const SizedBox(height: 20),
                    
                    // Confidence Indicator
                    _buildConfidenceIndicator(),
                    
                    const SizedBox(height: 20),

                    // Prevention Tips
                    _buildPreventionTips(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreventionTips() {
    // Get the disease key for translation
    final String diseaseKey = getDiseaseKey(disease);
    
    // For healthy plants, use specific healthy maintenance tips
    if (diseaseKey == 'healthy') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'healthy_leaf_prevention'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildPreventionTip(
            'healthy_nutrition_title',
            'healthy_nutrition_desc',
            fallbackTitle: "1. Maintain Proper Nutrition",
            fallbackDesc: "Ensure balanced fertilization with appropriate levels of nitrogen, phosphorus, and potassium for optimal plant health."
          ),
          _buildPreventionTip(
            'healthy_irrigation_title',
            'healthy_irrigation_desc',
            fallbackTitle: "2. Proper Irrigation",
            fallbackDesc: "Maintain consistent soil moisture without overwatering, which can stress plants and create conditions for disease."
          ),
          _buildPreventionTip(
            'healthy_monitoring_title',
            'healthy_monitoring_desc',
            fallbackTitle: "3. Regular Monitoring",
            fallbackDesc: "Continue inspecting plants regularly to catch any early signs of disease or pest problems."
          ),
        ],
      );
    }
    
    // Build prevention tips based on disease
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'disease_prevention'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        // Use if-else ladder for disease-specific tips
        if (diseaseKey == 'common_rust') ...[
          _buildPreventionTip(
            'resistant_varieties_title',
            'resistant_varieties_desc',
            fallbackTitle: "1. Choose Resistant Varieties",
            fallbackDesc: "Use rust-resistant maize varieties to lower the risk of severe infection and boost natural plant defense."
          ),
          _buildPreventionTip(
            'crop_rotation_title',
            'crop_rotation_desc',
            fallbackTitle: "2. Rotate Crops",
            fallbackDesc: "Rotate maize with non-host crops like soybeans to disrupt the disease life cycle and reduce spore buildup."
          ),
          _buildPreventionTip(
            'plant_spacing_title',
            'plant_spacing_desc',
            fallbackTitle: "3. Optimize Plant Spacing",
            fallbackDesc: "Plant corn with adequate spacing to allow air circulation throughout the crop, reducing leaf moisture and the likelihood of fungal infection."
          ),
          _buildPreventionTip(
            'regular_monitoring_title',
            'regular_monitoring_desc',
            fallbackTitle: "4. Monitor Regularly",
            fallbackDesc: "Regularly observe plants, especially during humid conditions, to catch early signs of disease."
          ),
          _buildPreventionTip(
            'fungicide_application_title',
            'fungicide_application_desc',
            fallbackTitle: "5. Apply Fungicides",
            fallbackDesc: "The use of appropriate fungicides at the early stage of infection can help prevent the spread of rust. Make sure to follow proper spraying methods and recommended dosage."
          ),
        ] else if (diseaseKey == 'gray_leaf_spot') ...[
          _buildPreventionTip(
            'gls_resistant_varieties_title',
            'gls_resistant_varieties_desc',
            fallbackTitle: "1. Choose Resistant Varieties",
            fallbackDesc: "Use corn varieties resistant to Gray Leaf Spot to reduce the risk of infection."
          ),
          _buildPreventionTip(
            'gls_crop_rotation_title',
            'gls_crop_rotation_desc',
            fallbackTitle: "2. Crop Rotation",
            fallbackDesc: "Rotate with non-host crops for 1-2 years, as the pathogen survives in corn residue."
          ),
          _buildPreventionTip(
            'gls_field_sanitation_title',
            'gls_field_sanitation_desc',
            fallbackTitle: "3. Field Sanitation",
            fallbackDesc: "Remove and destroy crop residue after harvest to reduce spore buildup for the next season."
          ),
          _buildPreventionTip(
            'gls_fungicide_title',
            'gls_fungicide_desc',
            fallbackTitle: "4. Apply Fungicides",
            fallbackDesc: "For gray leaf spot control in corn, fungicide applications, particularly strobilurin and triazole-based products, are effective when applied during tasseling to early silking stage (VT-R1) or in response to disease presence."
          ),
        ] else if (diseaseKey == 'northern_leaf_blight') ...[
          _buildPreventionTip(
            'nlb_resistant_varieties_title',
            'nlb_resistant_varieties_desc',
            fallbackTitle: "1. Resistant Hybrids",
            fallbackDesc: "Plant corn hybrids with resistance to northern leaf blight."
          ),
          _buildPreventionTip(
            'nlb_crop_rotation_title',
            'nlb_crop_rotation_desc',
            fallbackTitle: "2. Crop Rotation",
            fallbackDesc: "Implement 1-2 year rotation with non-host crops to reduce pathogen survival."
          ),
          _buildPreventionTip(
            'nlb_field_sanitation_title',
            'nlb_field_sanitation_desc',
            fallbackTitle: "3. Field Sanitation",
            fallbackDesc: "Tillage or burying crop residue can help reduce infection levels by reducing primary inoculum."
          ),
          _buildPreventionTip(
            'nlb_avoid_continuous_title',
            'nlb_avoid_continuous_desc',
            fallbackTitle: "4. Avoid Continuous Corn",
            fallbackDesc: "Continuous corn planting and conservation tillage practices can increase the risk of NLB."
          ),
          _buildPreventionTip(
            'nlb_fungicide_title',
            'nlb_fungicide_desc',
            fallbackTitle: "5. Apply Fungicides",
            fallbackDesc: "Fungicide sprays can be effective when applied at early stages of infection, especially in high-risk fields."
          ),
          _buildPreventionTip(
            'nlb_plant_spacing_title',
            'nlb_plant_spacing_desc',
            fallbackTitle: "6. Plant Spacing",
            fallbackDesc: "Maintain adequate plant spacing to promote air circulation and reduce humidity around plants."
          ),
          _buildPreventionTip(
            'nlb_soil_drainage_title',
            'nlb_soil_drainage_desc',
            fallbackTitle: "7. Soil Drainage",
            fallbackDesc: "Ensure good field drainage to prevent water pooling, which can promote disease spread."
          ),
          _buildPreventionTip(
            'nlb_planting_date_title',
            'nlb_planting_date_desc',
            fallbackTitle: "8. Planting Date",
            fallbackDesc: "Adjust planting dates to avoid periods of high disease pressure. Early planting in some regions can help the crop mature before severe NLB pressure."
          ),
        ] else ...[
          _buildPreventionTip(
            'healthy_nutrition_title',
            'healthy_nutrition_desc',
            fallbackTitle: "1. Maintain Proper Nutrition",
            fallbackDesc: "Ensure balanced fertilization with appropriate levels of nitrogen, phosphorus, and potassium for optimal plant health."
          ),
          _buildPreventionTip(
            'healthy_irrigation_title',
            'healthy_irrigation_desc',
            fallbackTitle: "2. Proper Irrigation",
            fallbackDesc: "Maintain consistent soil moisture without overwatering, which can weaken plants and create conditions for disease."
          ),
          _buildPreventionTip(
            'healthy_monitoring_title',
            'healthy_monitoring_desc',
            fallbackTitle: "3. Regular Monitoring",
            fallbackDesc: "Continue to inspect plants regularly for any early signs of disease or pest problems."
          ),
        ],
      ],
    );
  }

  Widget _buildPreventionTip(String title, String description, {String? fallbackTitle, String? fallbackDesc}) {
    // Try to get translation first
    String translatedTitle = title.tr();
    String translatedDescription = description.tr();

    // Check if translation exists by seeing if the result is different from the key
    // If the translation is not found, tr() returns the key itself
    bool titleTranslationExists = translatedTitle != title;
    bool descTranslationExists = translatedDescription != description;

    // Use translation if it exists, otherwise use fallback
    String finalTitle = titleTranslationExists ? translatedTitle : (fallbackTitle ?? title);
    String finalDescription = descTranslationExists ? translatedDescription : (fallbackDesc ?? description);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            finalTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            finalDescription,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseDescription() {
    // Get the disease key for translation
    final String diseaseKey = getDiseaseKey(disease);
    
    // Use existing translation keys from the translation files
    String translatedDescription;
    
    if (diseaseKey == 'healthy') {
      translatedDescription = 'healthy_leaf_description'.tr();
      // Check if translation exists
      if (translatedDescription == 'healthy_leaf_description') {
        translatedDescription = 'This corn leaf appears healthy with no visible signs of disease. Healthy corn leaves are typically uniform green in color, have smooth surfaces, and show no discoloration, spots, lesions, or abnormal growth patterns.';
      }
    } else if (diseaseKey == 'common_rust') {
      translatedDescription = 'common_rust_description'.tr();
      if (translatedDescription == 'common_rust_description') {
        translatedDescription = 'Common rust in maize, caused by Puccinia sorghi, shows as reddish-brown pustules on leaves, affecting photosynthesis and yield, especially in cool, moist climates.';
      }
    } else if (diseaseKey == 'northern_leaf_blight') {
      translatedDescription = 'northern_leaf_blight_description'.tr();
      if (translatedDescription == 'northern_leaf_blight_description') {
        translatedDescription = 'Northern Leaf Blight, caused by Exserohilum turcicum, appears as long, cigar-shaped gray-green lesions that turn brown. It develops in humid conditions and temperatures of 18-27°C.';
      }
    } else if (diseaseKey == 'gray_leaf_spot') {
      translatedDescription = 'gray_leaf_spot_description'.tr();
      if (translatedDescription == 'gray_leaf_spot_description') {
        translatedDescription = 'Gray Leaf Spot, caused by Cercospora zeae-maydis, appears as rectangular gray-brown lesions on leaves. It thrives in warm, humid conditions, affecting photosynthesis and reducing yield.';
      }
    } else {
      translatedDescription = 'This appears to be $disease. For detailed information, please consult agricultural extension services.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'disease_description'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translatedDescription,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator() {
    // Check if confidence is null and provide a default value
    // For saved diagnoses without confidence, show N/A instead of 0%
    if (confidence == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Center(
            child: const Text(
              'Confidence Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: const Center(
                child: Text(
                  'N/A',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
    
    // Convert confidence to percentage
    final confidenceValue = confidence!;
    final confidencePercent = (confidenceValue * 100).toInt();
    
    // Determine color based on confidence level
    Color confidenceColor;
    if (confidencePercent >= 80) {
      confidenceColor = Colors.green;
    } else if (confidencePercent >= 60) {
      confidenceColor = Colors.lightGreen;
    } else if (confidencePercent >= 40) {
      confidenceColor = Colors.yellow;
    } else {
      confidenceColor = Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Center(
          child: const Text(
            'Confidence Level',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pie chart
                CustomPaint(
                  size: const Size(150, 150),
                  painter: ConfidencePieChart(
                    confidence: confidenceValue,
                    confidenceColor: confidenceColor,
                  ),
                ),
                // Confidence percentage text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$confidencePercent%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: confidenceColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getConfidenceDescription(confidencePercent),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Helper method to get confidence description
  String _getConfidenceDescription(int confidencePercent) {
    if (confidencePercent >= 80) {
      return 'High Confidence';
    } else if (confidencePercent >= 60) {
      return 'Medium Confidence';
    } else if (confidencePercent >= 40) {
      return 'Low Confidence';
    } else {
      return 'Very Low Confidence';
    }
  }

  // Helper method to get standardized disease key
  String getDiseaseKey(String diseaseName) {
    final String normalizedDisease = diseaseName.toLowerCase().trim();
    
    if (normalizedDisease.contains('gray') && normalizedDisease.contains('leaf') && normalizedDisease.contains('spot')) {
      return 'gray_leaf_spot';
    } else if (normalizedDisease.contains('common') && normalizedDisease.contains('rust')) {
      return 'common_rust';
    } else if (normalizedDisease.contains('northern') && normalizedDisease.contains('leaf') && normalizedDisease.contains('blight')) {
      return 'northern_leaf_blight';
    } else if (normalizedDisease.contains('healthy')) {
      return 'healthy';
    }
    
    // Default: convert spaces to underscores
    return normalizedDisease.replaceAll(' ', '_');
  }
}

// Add this new class for the pie chart
class ConfidencePieChart extends CustomPainter {
  final double confidence;
  final Color confidenceColor;

  ConfidencePieChart({
    required this.confidence,
    required this.confidenceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Background circle (remaining percentage)
    final backgroundPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Confidence arc (filled percentage)
    final confidencePaint = Paint()
      ..color = confidenceColor
      ..style = PaintingStyle.fill;
    
    // Draw the confidence arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from the top
      2 * math.pi * confidence, // Arc angle based on confidence
      true, // Use center
      confidencePaint,
    );
    
    // Draw center circle (to create donut effect)
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(ConfidencePieChart oldDelegate) {
    return oldDelegate.confidence != confidence || 
           oldDelegate.confidenceColor != confidenceColor;
  }
}

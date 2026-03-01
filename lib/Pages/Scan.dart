import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import './Dashboard.dart';
import './Results.dart';
import './Diagnoses.dart';
import '../database/database_helper.dart';
import '../services/model_service.dart';
import '../widgets/language_selector.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final ModelService _modelService = ModelService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    await _modelService.initialize();
  }

  Future<void> _processImage(File imageFile, BuildContext context) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Process with model
      final results = await _modelService.detectDisease(imageFile);
      final double confidence = results['confidence'] ?? 0.0;

      if (context.mounted) {
        final dbHelper = DatabaseHelper();
        final imagePath = await dbHelper.saveImage(imageFile);
        
        // Always pass confidence to database
        await dbHelper.insertDiagnosis(
          results['disease'], 
          imagePath,
          confidence
        );

        setState(() {
          _isProcessing = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Results(
              disease: results['disease'],
              date: DateTime.now().toIso8601String(),
              imagePath: imagePath,
              confidence: confidence,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            duration: Duration(seconds: 10),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _processImage(_selectedImage!, context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _processImage(_selectedImage!, context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width * 0.05;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 180, 235, 245), // very light blue
              Color(0xFFBEE9F7),                  // light sky blue
              Color(0xFF90DBF4),                  // soft blue
              Color(0xFF48CAE4),                  // light blue
              Color(0xFF00B4D8),                  // cyan blue
              Color(0xFF0096C7),                  // medium blue
              Color(0xFF0077B6),                  // strong blue
              Color(0xFF023E8A),                  // deep blue
              Color(0xFF03045E),                  // dark navy
              Color(0xFF020024),                  // very dark blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Dashboard()),
                      ),
                    ),
                    const LanguageSelector(), // Add language selector here
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 40, bottom: 40),
                        child: Image.asset(
                          'assets/images/Logo.png',
                          width: 280,
                          height: 280,
                        ),
                      ),

                      // Pick Gallery Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          onPressed: () => _pickImageFromGallery(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library, color: Colors.black),
                              SizedBox(width: 8),
                              Text(
                                'pick_from_gallery'.tr(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pick Camera Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          onPressed: () => _pickImageFromCamera(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.black),
                              SizedBox(width: 8),
                              Text(
                                'take_photo'.tr(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

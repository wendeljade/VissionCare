import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../database/database_helper.dart';  // Updated import path
import 'Results.dart';
import 'Dashboard.dart';
import 'Scan.dart';
import 'ExportReport.dart';
import '../widgets/language_selector.dart';

class Diagnoses extends StatefulWidget {
  const Diagnoses({Key? key}) : super(key: key);

  @override
  State<Diagnoses> createState() => _DiagnosesState();
}

class _DiagnosesState extends State<Diagnoses> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteDiagnosis(Map<String, dynamic> diagnosis) async {
    try {
      // Delete the image file if it exists
      if (diagnosis['imagePath'] != null && diagnosis['imagePath'].isNotEmpty) {
        final file = File(diagnosis['imagePath']);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete from database
      await _databaseHelper.deleteDiagnosis(diagnosis['id']);
      
      // Refresh the state
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_deleting_diagnosis'.tr())),
        );
      }
    }
  }

  Widget _buildSearchBar(double width) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.02),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: width * 0.045,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search diseases'.tr(),
          hintStyle: TextStyle(
            fontSize: width * 0.045,
            color: Colors.grey.withOpacity(0.6),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.02),
            child: Icon(
              Icons.search,
              color: Colors.grey.withOpacity(0.6),
              size: width * 0.06,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.withOpacity(0.6),
                    size: width * 0.06,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: width * 0.02,
            vertical: width * 0.035,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisList(double width) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getDiagnoses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: width * 0.2),
                Icon(
                  Icons.history,
                  size: width * 0.15,
                  color: Colors.grey[400],
                ),
                SizedBox(height: width * 0.04),
                Text(
                  'No diagnoses yet'.tr(),
                  style: TextStyle(
                    fontSize: width * 0.04,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: width * 0.02),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Scan()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.06,
                      vertical: width * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                    ),
                  ),
                  child: Text(
                    'scan_now'.tr(),
                    style: TextStyle(
                      fontSize: width * 0.035,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Filter diagnoses based on search query
        final filteredDiagnoses = snapshot.data!.where((diagnosis) {
          return diagnosis['disease'].toString().toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredDiagnoses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: width * 0.2),
                Icon(
                  Icons.search_off,
                  size: width * 0.15,
                  color: Colors.grey[400],
                ),
                SizedBox(height: width * 0.04),
                Text(
                  'no_matching_diagnoses'.tr(),
                  style: TextStyle(
                    fontSize: width * 0.04,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: EdgeInsets.all(width * 0.04),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDiagnoses.length,
            itemBuilder: (context, index) {
              final diagnosis = filteredDiagnoses[index];
              return Container(
                margin: EdgeInsets.only(bottom: width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(width * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8.0,
                      spreadRadius: 1.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    // Extract confidence value, defaulting to null if not present
                    final confidence = diagnosis['confidence'] != null 
                        ? (diagnosis['confidence'] as num).toDouble() 
                        : null;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Results(
                          disease: diagnosis['disease'],
                          date: diagnosis['date'],
                          imagePath: diagnosis['imagePath'] ?? '',
                          confidence: confidence,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black54,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'confirm_delete'.tr(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'delete_diagnosis_confirmation'.tr(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                      ),
                                      child: Text(
                                        'cancel'.tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteDiagnosis(diagnosis);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'delete'.tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Section
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(width * 0.04),
                          topRight: Radius.circular(width * 0.04),
                        ),
                        child: Container(
                          height: width * 0.5,
                          child: diagnosis['imagePath'] != null &&
                                  diagnosis['imagePath'].isNotEmpty
                              ? Image.file(
                                  File(diagnosis['imagePath']),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    print("Image error: $error");
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: width * 0.15,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: width * 0.15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                      ),
                      // Content Section
                      Container(
                        padding: EdgeInsets.all(width * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diagnosis['disease'] ?? 'Unknown Disease',
                              style: TextStyle(
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: width * 0.02),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: width * 0.04,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: width * 0.02),
                                Text(
                                  diagnosis['date'] != null
                                      ? DateFormat('MMM d, yyyy - HH:mm')
                                          .format(DateTime.parse(diagnosis['date']))
                                      : 'No date available',
                                  style: TextStyle(
                                    fontSize: width * 0.035,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(double width) {
    return BottomNavigationBar(
      currentIndex: 2, // Set to 2 for Diagnoses page
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Scan()),
          );
        }
      },
      elevation: 10,
      selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: width * 0.025,
      unselectedFontSize: width * 0.025,
      iconSize: width * 0.05,
      items: [
        _buildNavigationBarItem('Home', 'home', width),
        _buildNavigationBarItem('ScanNavBar', 'scan', width),
        _buildNavigationBarItem('DiagnosIcon', 'diagnose', width),
      ],
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
      String iconName, String label, double width) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        'assets/images/$iconName.png',
        height: width * 0.05,
        width: width * 0.05,
      ),
      label: label.tr(),
      activeIcon: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF45DFB1),
          borderRadius: BorderRadius.circular(width * 0.025),
        ),
        padding: EdgeInsets.all(width * 0.02),
        child: Image.asset(
          'assets/images/$iconName.png',
          height: width * 0.05,
          width: width * 0.05,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        title: Text('recent_results'.tr()),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          const LanguageSelector(),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportReport()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(width),
            _buildDiagnosisList(width),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(width),
    );
  }
}

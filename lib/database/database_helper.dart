import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'diagnoses.db');
    
    // Delete the database to force recreation
    // Comment this out after testing
    // await deleteDatabase(path);
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    print("Creating database version $version");
    await db.execute('''
      CREATE TABLE diagnoses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        disease TEXT NOT NULL,
        date TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        confidence REAL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from $oldVersion to $newVersion");
    
    if (oldVersion < 2) {
      try {
        // Check if confidence column already exists
        var columns = await db.rawQuery('PRAGMA table_info(diagnoses)');
        bool hasConfidence = columns.any((column) => column['name'] == 'confidence');
        
        if (!hasConfidence) {
          print("Adding confidence column to diagnoses table");
          await db.execute('ALTER TABLE diagnoses ADD COLUMN confidence REAL');
        } else {
          print("Confidence column already exists");
        }
      } catch (e) {
        print("Error during database upgrade: $e");
        
        // If altering fails, recreate the table with the new schema
        print("Attempting to recreate table with new schema");
        await db.transaction((txn) async {
          // Create a temporary table with the new schema
          await txn.execute('''
            CREATE TABLE diagnoses_temp (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              disease TEXT NOT NULL,
              date TEXT NOT NULL,
              imagePath TEXT NOT NULL,
              confidence REAL
            )
          ''');
          
          // Copy data from old table to new table
          await txn.execute('''
            INSERT INTO diagnoses_temp (id, disease, date, imagePath)
            SELECT id, disease, date, imagePath FROM diagnoses
          ''');
          
          // Drop the old table
          await txn.execute('DROP TABLE diagnoses');
          
          // Rename the new table to the original name
          await txn.execute('ALTER TABLE diagnoses_temp RENAME TO diagnoses');
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getDiagnoses() async {
    final db = await database;
    return await db.query('diagnoses', orderBy: 'date DESC');
  }

  // Create a method to update the database schema
  Future<void> ensureConfidenceColumn() async {
    final db = await database;
    try {
      // Check if confidence column exists
      var columns = await db.rawQuery('PRAGMA table_info(diagnoses)');
      bool hasConfidence = columns.any((column) => column['name'] == 'confidence');
      
      if (!hasConfidence) {
        print("Adding confidence column to diagnoses table");
        await db.execute('ALTER TABLE diagnoses ADD COLUMN confidence REAL');
      }
    } catch (e) {
      print("Error ensuring confidence column: $e");
    }
  }

  // Update the insertDiagnosis method to store confidence properly
  Future<int> insertDiagnosis(String disease, String imagePath, double confidence) async {
    final db = await database;
    
    // Ensure the confidence column exists
    await ensureConfidenceColumn();
    
    return await db.insert(
      'diagnoses',
      {
        'disease': disease,
        'date': DateTime.now().toIso8601String(),
        'imagePath': imagePath,
        'confidence': confidence,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> saveImage(File image) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String path = join(documentsDirectory.path, fileName);
    await image.copy(path);
    return path;
  }

  Future<void> deleteDiagnosis(int id) async {
    final db = await database;
    await db.delete(
      'diagnoses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

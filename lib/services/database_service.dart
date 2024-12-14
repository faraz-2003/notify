// lib/services/database_service.dart

import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shop_item.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Database name and table constants
  static const String _databaseName = 'shopping_reminder.db';
  static const String _tableName = 'shop_items';

  /// Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initializeDatabase() async {
    // Get the database path
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  /// Create the database tables
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id TEXT PRIMARY KEY,
        itemName TEXT NOT NULL,
        shopName TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        isPurchased INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Insert a new shop item
  Future<void> insertShopItem(ShopItem item) async {
    final Database db = await database;
    await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all shop items
  Future<List<ShopItem>> getAllShopItems() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List.generate(maps.length, (index) => ShopItem.fromMap(maps[index]));
  }

  /// Get unpurchased shop items
  Future<List<ShopItem>> getUnpurchasedItems() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isPurchased = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (index) => ShopItem.fromMap(maps[index]));
  }

  /// Update a shop item
  Future<void> updateShopItem(ShopItem item) async {
    final Database db = await database;
    await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a shop item
  Future<void> deleteShopItem(String id) async {
    final Database db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark item as purchased
  Future<void> markAsPurchased(String id, bool isPurchased) async {
    final Database db = await database;
    await db.update(
      _tableName,
      {'isPurchased': isPurchased ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get items near a location
  Future<List<ShopItem>> getNearbyItems(double latitude, double longitude, double radiusInKm) async {
    final Database db = await database;
    // Basic proximity query (not exact but efficient for initial filtering)
    final latRange = radiusInKm / 111.0; // Rough conversion to degrees
    final lonRange = radiusInKm / (111.0 * cos(latitude * pi / 180));

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '''
        latitude BETWEEN ? AND ? AND 
        longitude BETWEEN ? AND ? AND 
        isPurchased = ?
      ''',
      whereArgs: [
        latitude - latRange,
        latitude + latRange,
        longitude - lonRange,
        longitude + lonRange,
        0,
      ],
    );

    return List.generate(maps.length, (index) => ShopItem.fromMap(maps[index]));
  }

  /// Close the database
  Future<void> close() async {
    final Database db = await database;
    db.close();
  }
}
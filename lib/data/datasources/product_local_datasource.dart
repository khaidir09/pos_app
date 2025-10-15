import 'package:flutter/widgets.dart';
import 'package:flutter_pos_app/data/models/response/product_response_model.dart';
import 'package:flutter_pos_app/presentation/order/models/order_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../presentation/home/models/draft_order_item.dart';
import '../../presentation/home/models/order_item.dart';
import '../../presentation/order/models/draft_order_model.dart';
import '../models/request/order_request_model.dart';
import '../models/response/category_response_model.dart';

class ProductLocalDatasource {
  ProductLocalDatasource._init();

  static final ProductLocalDatasource instance = ProductLocalDatasource._init();

  final String tableProducts = 'products';

  static Database? _database;

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = dbPath + filePath;

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        // Backup data lama
        final List<Map<String, dynamic>> oldOrders = await db.query('orders');

        // Drop table lama
        await db.execute('DROP TABLE IF EXISTS orders');

        // Buat ulang table dengan struktur baru
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT UNIQUE,
            nominal INTEGER,
            payment_method TEXT,
            total_item INTEGER,
            id_kasir INTEGER,
            nama_kasir TEXT,
            transaction_time TEXT,
            is_sync INTEGER DEFAULT 0,
            shop_id INTEGER DEFAULT 0
          )
        ''');

        // Restore data lama dengan menambahkan transaction_id default
        for (var order in oldOrders) {
          final newOrder = Map<String, dynamic>.from(order);
          newOrder['transaction_id'] = 'TRX-MIGRATED-${order['id']}';
          await db.insert('orders', newOrder);
        }
      } catch (e) {
        print('Migration error: $e');
        // Jika gagal migrasi, buat table baru
        await db.execute('''
          CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT UNIQUE,
            nominal INTEGER,
            payment_method TEXT,
            total_item INTEGER,
            id_kasir INTEGER,
            nama_kasir TEXT,
            transaction_time TEXT,
            is_sync INTEGER DEFAULT 0,
            shop_id INTEGER DEFAULT 0
          )
        ''');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProducts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        name TEXT,
        price INTEGER,
        stock INTEGER,
        image TEXT,
        category TEXT,
        category_id INTEGER,
        is_best_seller INTEGER,
        is_sync INTEGER DEFAULT 0,
        shop_id INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT UNIQUE,
        nominal INTEGER,
        payment_method TEXT,
        total_item INTEGER,
        id_kasir INTEGER,
        nama_kasir TEXT,
        transaction_time TEXT,
        is_sync INTEGER DEFAULT 0,
        shop_id INTEGER DEFAULT 0
      )
    ''');

    //categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        name TEXT,
        shop_id INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_order INTEGER,
        id_product INTEGER,
        quantity INTEGER,
        price INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE draft_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_item INTEGER,
        nominal INTEGER,
        transaction_time TEXT,
        table_number INTEGER,
        draft_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE draft_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_draft_order INTEGER,
        id_product INTEGER,
        quantity INTEGER,
        price INTEGER
      )
    ''');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('pos13.db');
    return _database!;
  }

  //insert all categories
  Future<void> insertAllCategories(List<Category> categories,
      {required int shopId}) async {
    final db = await instance.database;
    for (var category in categories) {
      final data = category.toMap();
      data['shop_id'] = shopId;
      await db.insert('categories', data);
    }
  }

  //delete all categories
  Future<void> removeAllCategories() async {
    final db = await instance.database;
    await db.delete('categories');
  }

  //get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');

    return result.map((e) => Category.fromLocal(e)).toList();
  }

  //save order
  Future<int> saveOrder(OrderModel order) async {
    final db = await instance.database;

    try {
      // Check if transaction_id already exists
      final existing = await db.query(
        'orders',
        where: 'transaction_id = ?',
        whereArgs: [order.transactionId],
      );

      print('=== SAVING ORDER TO DATABASE ===');
      print('Transaction ID: ${order.transactionId}');

      if (existing.isNotEmpty) {
        print('Order already exists with ID: ${existing.first['id']}');
        return existing.first['id'] as int;
      }

      // Insert new order
      final orderMap = order.toMapForLocal();
      final id = await db.insert('orders', orderMap);

      print('New order saved with ID: $id');
      print('Order details: ${orderMap.toString()}');

      // Insert order items
      for (var orderItem in order.orders) {
        final itemId =
            await db.insert('order_items', orderItem.toMapForLocal(id));
        print('Saved order item with ID: $itemId');
      }
      print('=== ORDER SAVED SUCCESSFULLY ===');
      return id;
    } catch (e) {
      print('Save order error: $e');
      rethrow;
    }
  }

  //save draft order
  Future<int> saveDraftOrder(DraftOrderModel order) async {
    final db = await instance.database;
    int id = await db.insert('draft_orders', order.toMapForLocal());
    for (var orderItem in order.orders) {
      await db.insert('draft_order_items', orderItem.toMapForLocal(id));
    }
    return id;
  }

  //get all draft order
  Future<List<DraftOrderModel>> getAllDraftOrder() async {
    final db = await instance.database;
    final result = await db.query('draft_orders', orderBy: 'id ASC');

    List<DraftOrderModel> results = await Future.wait(result.map((item) async {
      // Your asynchronous operation here
      final draftOrderItem =
          await getDraftOrderItemByOrderId(item['id'] as int);
      return DraftOrderModel.newFromLocalMap(item, draftOrderItem);
    }));
    return results;
  }

  //get draft order item by id order
  Future<List<DraftOrderItem>> getDraftOrderItemByOrderId(int idOrder) async {
    final db = await instance.database;
    final result =
        await db.query('draft_order_items', where: 'id_draft_order = $idOrder');

    List<DraftOrderItem> results = await Future.wait(result.map((item) async {
      // Your asynchronous operation here
      final product = await getProductById(item['id_product'] as int);
      return DraftOrderItem(
          product: product!, quantity: item['quantity'] as int);
    }));
    return results;
  }

  //remove draft order by id
  Future<void> removeDraftOrderById(int id) async {
    final db = await instance.database;
    await db.delete('draft_orders', where: 'id = ?', whereArgs: [id]);
    await db.delete('draft_order_items',
        where: 'id_draft_order = ?', whereArgs: [id]);
  }

  //get order by isSync = 0
  Future<List<OrderModel>> getOrderByIsSync() async {
    final db = await instance.database;
    final result = await db.query('orders', where: 'is_sync = 0');

    return result.map((e) => OrderModel.fromLocalMap(e)).toList();
  }

  //get order item by id order
  Future<List<OrderItemModel>> getOrderItemByOrderIdLocal(int idOrder) async {
    final db = await instance.database;
    final result = await db.query('order_items', where: 'id_order = $idOrder');

    return result.map((e) => OrderItem.fromMapLocal(e)).toList();
  }

  //update isSync order by id
  Future<int> updateIsSyncOrderById(int id) async {
    final db = await instance.database;
    return await db.update('orders', {'is_sync': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  //get all orders
  Future<List<OrderModel>> getAllOrder() async {
    final db = await instance.database;
    final result = await db.query('orders', orderBy: 'id DESC');

    List<OrderModel> results = await Future.wait(result.map((item) async {
      // Your asynchronous operation here
      final orderItem = await getOrderItemByOrderId(item['id'] as int);
      return OrderModel.newFromLocalMap(item, orderItem);
    }));
    return results;
    // return result.map((e) {
    //   return OrderModel.fromLocalMap(e);
    // }).toList();
  }

  //get order item by id order
  Future<List<OrderItem>> getOrderItemByOrderId(int idOrder) async {
    final db = await instance.database;
    final result = await db
        .query('order_items', where: 'id_order = ?', whereArgs: [idOrder]);

    List<OrderItem> results = [];

    for (var item in result) {
      final product = await getProductById(item['id_product'] as int);

      // Jika product tidak ditemukan, lewati item ini
      if (product == null) {
        debugPrint(
            '⚠️ Produk dengan ID ${item['id_product']} tidak ditemukan!');
        continue;
      }

      results.add(OrderItem(
        product: product,
        quantity: item['quantity'] as int,
      ));
    }

    return results;
  }

  //remove all data product
  Future<void> removeAllProduct() async {
    final db = await instance.database;
    await db.delete(tableProducts);
  }

  //insert data product from list product
  Future<void> insertAllProduct(List<Product> products,
      {required int shopId}) async {
    final db = await instance.database;
    for (var product in products) {
      final data = product.toLocalMap();
      data['shop_id'] = shopId;
      await db.insert(tableProducts, data);
    }
  }

  //isert data product
  Future<Product> insertProduct(Product product) async {
    final db = await instance.database;
    int id = await db.insert(tableProducts, product.toMap());
    return product.copyWith(id: id);
  }

  //get all data product
  Future<List<Product>> getAllProduct(int shopId) async {
    final db = await instance.database;
    final result =
        await db.query(tableProducts, where: 'shop_id = ?', whereArgs: [shopId]);

    return result.map((e) => Product.fromMap(e)).toList();
  }

  //get product by id
  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final result =
        await db.query(tableProducts, where: 'product_id = ?', whereArgs: [id]);

    if (result.isEmpty) {
      return null;
    }

    return Product.fromMap(result.first);
  }
}

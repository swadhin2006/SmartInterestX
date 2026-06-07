import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_model.dart';
import '../models/transaction_model.dart';
import '../models/payment_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_interest_x.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        email TEXT,
        type TEXT NOT NULL DEFAULT 'borrower',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        contactId TEXT NOT NULL,
        contactName TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        interestRate REAL NOT NULL,
        interestType INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        dueDate TEXT,
        notes TEXT,
        status INTEGER NOT NULL,
        amountPaid REAL NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (contactId) REFERENCES contacts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        transactionId TEXT NOT NULL,
        amount REAL NOT NULL,
        mode INTEGER NOT NULL,
        paymentDate TEXT NOT NULL,
        proofImagePath TEXT,
        notes TEXT,
        FOREIGN KEY (transactionId) REFERENCES transactions(id)
      )
    ''');
  }

  // ─── CONTACTS ────────────────────────────────────────────────────────────────

  Future<void> insertContact(Contact contact) async {
    final db = await database;
    await db.insert('contacts', contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final maps = await db.query('contacts', orderBy: 'name ASC');
    return maps.map((m) => Contact.fromMap(m)).toList();
  }

  Future<Contact?> getContactById(String id) async {
    final db = await database;
    final maps = await db.query('contacts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Contact.fromMap(maps.first);
  }

  Future<void> updateContact(Contact contact) async {
    final db = await database;
    await db.update('contacts', contact.toMap(),
        where: 'id = ?', whereArgs: [contact.id]);
  }

  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────────

  Future<void> insertTransaction(LoanTransaction tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LoanTransaction>> getAllTransactions() async {
    final db = await database;
    final maps =
        await db.query('transactions', orderBy: 'createdAt DESC');
    return maps.map((m) => LoanTransaction.fromMap(m)).toList();
  }

  Future<List<LoanTransaction>> getTransactionsByContact(
      String contactId) async {
    final db = await database;
    final maps = await db.query('transactions',
        where: 'contactId = ?',
        whereArgs: [contactId],
        orderBy: 'createdAt DESC');
    return maps.map((m) => LoanTransaction.fromMap(m)).toList();
  }

  Future<void> updateTransaction(LoanTransaction tx) async {
    final db = await database;
    await db.update('transactions', tx.toMap(),
        where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await db.delete('payments', where: 'transactionId = ?', whereArgs: [id]);
  }

  // ─── PAYMENTS ─────────────────────────────────────────────────────────────────

  Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Payment>> getPaymentsByTransaction(String transactionId) async {
    final db = await database;
    final maps = await db.query('payments',
        where: 'transactionId = ?',
        whereArgs: [transactionId],
        orderBy: 'paymentDate DESC');
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<void> deletePayment(String id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ─── EXPORT ───────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllTransactionsRaw() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'createdAt DESC');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

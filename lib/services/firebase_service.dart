import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';
import '../models/transaction_model.dart';
import '../models/payment_model.dart';

/// FirebaseService handles all Firestore cloud sync & backup.
/// Structure:
///   users/{uid}/contacts/{contactId}
///   users/{uid}/transactions/{transactionId}
///   users/{uid}/payments/{paymentId}
class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  bool get isLoggedIn => _auth.currentUser != null;

  // ─── Collection References ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      _db.collection('users').doc(_uid).collection('contacts');

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection('users').doc(_uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _db.collection('users').doc(_uid).collection('payments');

  // ─── CONTACTS ─────────────────────────────────────────────────────────────

  Future<void> syncContact(Contact contact) async {
    if (_uid == null) return;
    await _contactsRef.doc(contact.id).set({
      'id': contact.id,
      'name': contact.name,
      'mobile': contact.mobile,
      'email': contact.email,
      'createdAt': contact.createdAt.toIso8601String(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteContactFromCloud(String contactId) async {
    if (_uid == null) return;
    await _contactsRef.doc(contactId).delete();
  }

  Future<List<Contact>> fetchContacts() async {
    if (_uid == null) return [];
    final snap = await _contactsRef.orderBy('name').get();
    return snap.docs.map((d) => Contact.fromMap(d.data())).toList();
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────

  Future<void> syncTransaction(LoanTransaction tx) async {
    if (_uid == null) return;
    await _transactionsRef.doc(tx.id).set({
      ...tx.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTransactionFromCloud(String txId) async {
    if (_uid == null) return;
    await _transactionsRef.doc(txId).delete();
  }

  Future<List<LoanTransaction>> fetchTransactions() async {
    if (_uid == null) return [];
    final snap =
        await _transactionsRef.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => LoanTransaction.fromMap(d.data()))
        .toList();
  }

  // ─── PAYMENTS ─────────────────────────────────────────────────────────────

  Future<void> syncPayment(Payment payment) async {
    if (_uid == null) return;
    await _paymentsRef.doc(payment.id).set({
      ...payment.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Payment>> fetchPayments(String transactionId) async {
    if (_uid == null) return [];
    final snap = await _paymentsRef
        .where('transactionId', isEqualTo: transactionId)
        .orderBy('paymentDate', descending: true)
        .get();
    return snap.docs.map((d) => Payment.fromMap(d.data())).toList();
  }

  // ─── FULL BACKUP ──────────────────────────────────────────────────────────

  /// Backup all local data to Firestore in batches
  Future<void> backupAll({
    required List<Contact> contacts,
    required List<LoanTransaction> transactions,
  }) async {
    if (_uid == null) return;

    // Contacts batch
    final batch1 = _db.batch();
    for (final c in contacts) {
      batch1.set(_contactsRef.doc(c.id), {
        ...c.toMap(),
        'syncedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch1.commit();

    // Transactions batch (Firestore limit = 500 per batch)
    for (var i = 0; i < transactions.length; i += 400) {
      final chunk = transactions.sublist(
          i, i + 400 > transactions.length ? transactions.length : i + 400);
      final batch2 = _db.batch();
      for (final tx in chunk) {
        batch2.set(_transactionsRef.doc(tx.id), {
          ...tx.toMap(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch2.commit();
    }
  }

  // ─── RESTORE ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> restoreAll() async {
    final contacts = await fetchContacts();
    final transactions = await fetchTransactions();
    return {
      'contacts': contacts,
      'transactions': transactions,
    };
  }

  // ─── USER INFO ────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

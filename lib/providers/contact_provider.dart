import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/contact_model.dart';
import '../db/database_helper.dart';
import '../services/firebase_service.dart';

// Roadmap Section 6.1: ContactProvider
class ContactProvider with ChangeNotifier {
  List<Contact> _contacts = [];

  List<Contact> get allContacts => _contacts;

  List<Contact> get borrowers =>
      _contacts.where((c) => c.type == 'borrower').toList();

  List<Contact> get lenders =>
      _contacts.where((c) => c.type == 'lender').toList();

  Future<void> loadContacts() async {
    _contacts = await DatabaseHelper.instance.getAllContacts();
    notifyListeners();
  }

  void addContact({
    required String name,
    required String mobile,
    String? email,
    String type = 'borrower',
  }) async {
    final contact = Contact(
      id: const Uuid().v4(),
      name: name,
      mobile: mobile,
      email: email,
      type: type,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertContact(contact);
    _contacts.add(contact);
    notifyListeners();
    // Cloud sync
    if (FirebaseService.instance.isLoggedIn) {
      FirebaseService.instance.syncContact(contact).catchError((_) {});
    }
  }

  void updateContact(Contact contact) async {
    await DatabaseHelper.instance.updateContact(contact);
    final idx = _contacts.indexWhere((c) => c.id == contact.id);
    if (idx != -1) _contacts[idx] = contact;
    notifyListeners();
    if (FirebaseService.instance.isLoggedIn) {
      FirebaseService.instance.syncContact(contact).catchError((_) {});
    }
  }

  void deleteContact(String id) async {
    await DatabaseHelper.instance.deleteContact(id);
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
    if (FirebaseService.instance.isLoggedIn) {
      FirebaseService.instance.deleteContactFromCloud(id).catchError((_) {});
    }
  }

  // Roadmap Section 6.1: search method
  List<Contact> search(String query) {
    return _contacts
        .where((c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.mobile.contains(query))
        .toList();
  }

  Contact? getById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> backupToCloud() async {
    if (!FirebaseService.instance.isLoggedIn) return;
    for (final c in _contacts) {
      await FirebaseService.instance.syncContact(c);
    }
  }

  Future<void> restoreFromCloud() async {
    if (!FirebaseService.instance.isLoggedIn) return;
    final cloudContacts = await FirebaseService.instance.fetchContacts();
    for (final c in cloudContacts) {
      await DatabaseHelper.instance.insertContact(c);
    }
    _contacts = await DatabaseHelper.instance.getAllContacts();
    notifyListeners();
  }
}

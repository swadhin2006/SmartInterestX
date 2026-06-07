import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/contact_model.dart';

// Module 2 — Contact List Screen
// Roadmap Section 6.3: ListView.builder + SearchBar + Dismissible
class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (q) => setState(() => _query = q),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Filterable list
          Expanded(
            child: Consumer<ContactProvider>(
              builder: (context, provider, _) {
                final contacts = _query.isEmpty
                    ? provider.allContacts
                    : provider.search(_query);

                if (contacts.isEmpty) {
                  return const Center(
                    child: Text('No contacts yet. Tap + to add one.'),
                  );
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (ctx, i) {
                    final c = contacts[i];
                    return Dismissible(
                      key: Key(c.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => provider.deleteContact(c.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            c.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(c.name),
                        subtitle: Text(c.mobile),
                        trailing: Chip(
                          label: Text(c.type.toUpperCase()),
                          backgroundColor: c.type == 'borrower'
                              ? Colors.orange[100]
                              : Colors.green[100],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/add-contact',
                          arguments: c,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-contact'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

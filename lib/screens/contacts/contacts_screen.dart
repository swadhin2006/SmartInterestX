import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/contact_model.dart';
import '../../utils/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_list_tile.dart';
import '../transactions/transaction_detail_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: contactProvider.setSearchQuery,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: contactProvider.contacts.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contactProvider.contacts.length,
              itemBuilder: (context, i) {
                final contact = contactProvider.contacts[i];
                return _ContactCard(contact: contact);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No contacts yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tap + to add a borrower or lender',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, [Contact? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final mobileCtrl = TextEditingController(text: existing?.mobile);
    final emailCtrl = TextEditingController(text: existing?.email);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing != null ? 'Edit Contact' : 'Add Contact',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Mobile is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final provider = context.read<ContactProvider>();
                    if (existing != null) {
                      await provider.updateContact(existing.copyWith(
                        name: nameCtrl.text,
                        mobile: mobileCtrl.text,
                        email: emailCtrl.text.isEmpty
                            ? null
                            : emailCtrl.text,
                      ));
                    } else {
                      await provider.addContact(
                        name: nameCtrl.text,
                        mobile: mobileCtrl.text,
                        email: emailCtrl.text.isEmpty
                            ? null
                            : emailCtrl.text,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(existing != null ? 'Update' : 'Add Contact'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final txs = txProvider.getByContact(contact.id);
    final activeCount =
        txs.where((t) => t.status != TransactionStatus.settled).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Text(
            contact.name[0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(contact.mobile,
            style: const TextStyle(color: AppTheme.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activeCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount active',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditDialog(context),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_rounded,
                          size: 16, color: AppTheme.taken),
                      label: const Text('Delete',
                          style: TextStyle(color: AppTheme.taken)),
                    ),
                  ],
                ),
                if (txs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No transactions',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                else
                  ...txs.take(3).map((tx) => TransactionListTile(
                        transaction: tx,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailScreen(
                                transactionId: tx.id),
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    // Reuse the add dialog from ContactsScreen
    final nameCtrl = TextEditingController(text: contact.name);
    final mobileCtrl = TextEditingController(text: contact.mobile);
    final emailCtrl = TextEditingController(text: contact.email ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Contact',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: mobileCtrl,
                decoration:
                    const InputDecoration(labelText: 'Mobile Number *'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailCtrl,
                decoration:
                    const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await context.read<ContactProvider>().updateContact(
                          contact.copyWith(
                            name: nameCtrl.text,
                            mobile: mobileCtrl.text,
                            email: emailCtrl.text.isEmpty
                                ? null
                                : emailCtrl.text,
                          ),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Update Contact'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
            'Delete ${contact.name}? All linked transactions will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.taken),
            onPressed: () async {
              await context
                  .read<ContactProvider>()
                  .deleteContact(contact.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

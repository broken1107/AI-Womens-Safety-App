import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/emergency_contact.dart';
import '../../providers/contact_provider.dart';
import '../../utils/url_actions.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadContacts();
    });
  }

  void _confirmDelete(BuildContext ctx, EmergencyContact contact) {
    final messenger = ScaffoldMessenger.of(ctx);
    final contactProvider = context.read<ContactProvider>();

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Remove ${contact.name} from your trusted emergency circle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await contactProvider.deleteContact(contact.id);
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Contact removed')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();
    final contacts = contactProvider.contacts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.emergencyContacts),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => contactProvider.loadContacts(forceRefresh: true),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (contactProvider.isLoading && contacts.isEmpty) {
            return const LoadingWidget(message: 'Loading your emergency contacts...');
          }

          if (contactProvider.errorMessage != null && contacts.isEmpty) {
            return AppErrorWidget(
              message: contactProvider.errorMessage!,
              onRetry: () => contactProvider.loadContacts(forceRefresh: true),
            );
          }

          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Emergency Contacts Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your family members or close friends. During an SOS, their phones will be alerted with your live GPS location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/contacts/add'),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Add First Contact'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => contactProvider.loadContacts(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: contacts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = contacts[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: c.isPrimary
                            ? AppColors.primaryContainer
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                        child: Text(
                          c.name.isNotEmpty ? c.name.substring(0, 1).toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.isPrimary
                                ? AppColors.primary
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('${c.relationship} • ${c.phone}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Direct Call',
                            icon: const Icon(Icons.call_rounded, color: AppColors.success),
                            onPressed: () => launchPhoneCall(c.phone),
                          ),
                          IconButton(
                            tooltip: 'Send SMS',
                            icon: const Icon(Icons.sms_rounded, color: AppColors.info),
                            onPressed: () => launchSms(
                              c.phone,
                              message: 'Safety Alert: I am sharing my trusted contacts network via Safety Guardian.',
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') {
                                Navigator.of(context).pushNamed('/contacts/edit', arguments: c);
                              } else if (val == 'delete') {
                                _confirmDelete(context, c);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/contacts/add'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Contact'),
      ),
    );
  }
}

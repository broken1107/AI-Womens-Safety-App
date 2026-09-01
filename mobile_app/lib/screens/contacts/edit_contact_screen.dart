import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/emergency_contact.dart';
import '../../providers/contact_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EditContactScreen extends StatefulWidget {
  const EditContactScreen({super.key, this.contact});

  final dynamic contact;

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationController;
  bool _isPrimary = false;
  int _contactId = 0;

  @override
  void initState() {
    super.initState();
    final c = widget.contact is EmergencyContact ? widget.contact as EmergencyContact : null;
    _contactId = c?.id ?? 0;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _relationController = TextEditingController(text: c?.relationship ?? 'Family');
    _isPrimary = c?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<ContactProvider>();
    final success = await provider.updateContact(
      id: _contactId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relationship: _relationController.text.trim(),
      isTrusted: _isPrimary,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact updated successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to update contact')),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to remove this emergency contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ContactProvider>();
      final success = await provider.deleteContact(_contactId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ContactProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Emergency Contact'),
        actions: [
          IconButton(
            tooltip: 'Delete Contact',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: isLoading ? null : _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Contact Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                textInputAction: TextInputAction.next,
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (val) => val == null || val.trim().length < 8 ? 'Valid phone number is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _relationController,
                label: 'Relationship',
                prefixIcon: const Icon(Icons.favorite_outline_rounded),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as Primary Contact'),
                subtitle: const Text('First contact to alert during emergency SOS broadcasts'),
                value: _isPrimary,
                onChanged: isLoading ? null : (val) => setState(() => _isPrimary = val),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Update Contact',
                isLoading: isLoading,
                onPressed: _update,
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

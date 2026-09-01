import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/contact_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController(text: 'Family');
  bool _isPrimary = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<ContactProvider>();
    final success = await provider.addContact(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      relationship: _relationController.text.trim(),
      isTrusted: _isPrimary,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contact added successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to add contact')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ContactProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Contact'),
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
                hint: 'e.g. Mom, Brother, Friend',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                textInputAction: TextInputAction.next,
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'e.g. +91 98765 43210',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (val) => val == null || val.trim().length < 8 ? 'Valid phone number is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _relationController,
                label: 'Relationship',
                hint: 'Parent, Sibling, Friend, Guardian',
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
                label: 'Save Emergency Contact',
                isLoading: isLoading,
                onPressed: _save,
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

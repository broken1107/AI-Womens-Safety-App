import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/incident_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _areaController = TextEditingController(text: 'Downtown');
  String _selectedCategory = 'Harassment';
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Harassment',
    'Stalking',
    'Eve Teasing',
    'Suspicious Activity',
    'Poor Lighting / Dark Zone',
    'Physical Assault',
    'Theft / Snatching',
    'Other Hazard',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().loadIncidents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _imagePath = picked.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access device camera/gallery')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final locationProvider = context.read<LocationProvider>();
    final pos = locationProvider.currentLatLng;
    final incidentProvider = context.read<IncidentProvider>();

    final success = await incidentProvider.submitIncident(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      area: _areaController.text.trim(),
      latitude: pos.latitude,
      longitude: pos.longitude,
      imagePath: _imagePath,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident report submitted successfully')),
      );
      _titleController.clear();
      _descController.clear();
      setState(() => _imagePath = null);
      _tabController.animateTo(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(incidentProvider.errorMessage ?? 'Failed to submit report')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentProvider = context.watch<IncidentProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reportIncident),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_photo_alternate_outlined), text: 'New Report'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Past Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: New Incident Report Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _titleController,
                    label: 'Incident Title',
                    hint: 'e.g. Unlit road near bus terminal',
                    prefixIcon: const Icon(Icons.title_rounded),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Incident Category',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: _areaController,
                    label: 'Vicinity / Area Name',
                    hint: 'e.g. Perundurai Road Corridor',
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    textInputAction: TextInputAction.next,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Area name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: _descController,
                    label: 'Description & Observed Details',
                    hint: 'Describe what occurred, lighting conditions, suspicious individuals, or hazard details...',
                    prefixIcon: const Icon(Icons.description_outlined),
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().length < 5 ? 'Please provide detailed description' : null,
                  ),
                  const SizedBox(height: 14),

                  // Auto GPS info strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF3F5FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'GPS: ${locationProvider.currentAddress}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo Attachment Picker
                  if (_imagePath != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_imagePath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                              onPressed: () => setState(() => _imagePath = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Take Photo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  AppButton(
                    label: 'Submit Incident Report',
                    icon: Icons.send_rounded,
                    isLoading: incidentProvider.isSubmitting,
                    onPressed: _submitReport,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Tab 2: Past Reports History
          Builder(
            builder: (context) {
              if (incidentProvider.isLoading && incidentProvider.incidents.isEmpty) {
                return const LoadingWidget(message: 'Loading your past reports...');
              }

              if (incidentProvider.errorMessage != null && incidentProvider.incidents.isEmpty) {
                return AppErrorWidget(
                  message: incidentProvider.errorMessage!,
                  onRetry: () => incidentProvider.loadIncidents(forceRefresh: true),
                );
              }

              if (incidentProvider.incidents.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Incident Reports Filed',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Reports filed by you will appear here to help strengthen safety surveillance models.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => incidentProvider.loadIncidents(forceRefresh: true),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: incidentProvider.incidents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final report = incidentProvider.incidents[idx];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    report.category.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: report.status == 'RESOLVED'
                                        ? AppColors.riskLowContainer
                                        : AppColors.riskMediumContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    report.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: report.status == 'RESOLVED'
                                          ? AppColors.riskLow
                                          : AppColors.riskMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              report.displayTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.description,
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (report.createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(report.createdAt!),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

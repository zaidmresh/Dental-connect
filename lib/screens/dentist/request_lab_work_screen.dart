import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/file_upload_service.dart';
import '../../services/order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_widgets.dart';

class RequestLabWorkScreen extends StatefulWidget {
  const RequestLabWorkScreen({super.key});

  @override
  State<RequestLabWorkScreen> createState() => _RequestLabWorkScreenState();
}

class _RequestLabWorkScreenState extends State<RequestLabWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final List<String> _fileUrls = [];
  final List<String> _fileNames = [];
  UserModel? _selectedLab;
  bool _isUrgent = false;
  bool _isUploadingFiles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _uploadFiles() async {
    final user = context.read<AuthProvider>().currentUser!;
    setState(() => _isUploadingFiles = true);

    try {
      final uploadedFiles = await FileUploadService().pickAndUploadOrderFiles(
        ownerId: user.id,
        folder: 'lab_request_files',
      );

      if (!mounted) return;
      if (uploadedFiles.isEmpty) {
        setState(() => _isUploadingFiles = false);
        return;
      }

      setState(() {
        for (final file in uploadedFiles) {
          _fileUrls.add(file.url);
          _fileNames.add(file.name);
        }
        _isUploadingFiles = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File attached'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingFiles = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File upload failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser!;
    final order = await context.read<OrderProvider>().createOrder(
          dentistId: user.id,
          dentistName: user.fullName,
          labId: _selectedLab!.id,
          labName: _selectedLab!.clinicOrLabName ?? _selectedLab!.displayName,
          caseDescription: _descriptionController.text.trim(),
          fileUrls: _fileUrls,
          fileNames: _fileNames,
          isUrgent: _isUrgent,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lab request #${order.id} sent'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final labs = context.watch<AuthProvider>().labs;
    if (_selectedLab == null && labs.isNotEmpty) {
      _selectedLab = labs.first;
    }
    final selectedLabId =
        labs.any((lab) => lab.id == _selectedLab?.id) ? _selectedLab?.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Lab Work')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Lab',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedLabId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.science_outlined, color: AppColors.primary),
                  hintText: 'Select lab account',
                ),
                items: labs
                    .map((lab) => DropdownMenuItem(
                          value: lab.id,
                          child: Text(
                            lab.clinicOrLabName ?? lab.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please choose a lab'
                    : null,
                onChanged: (labId) => setState(() {
                  _selectedLab = labs.firstWhere((lab) => lab.id == labId);
                }),
              ),
              if (labs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'No lab accounts found. Register a technician/lab account first.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Work Description',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              AppTextField(
                label: '',
                hint: 'Describe crown, bridge, denture, shade, materials...',
                controller: _descriptionController,
                maxLines: 5,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _uploadFiles,
                icon: const Icon(Icons.attach_file),
                label: Text(_fileNames.isEmpty
                    ? 'Attach Case Files'
                    : '${_fileNames.length} file(s) attached'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isUrgent
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isUrgent ? AppColors.error : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high,
                        color:
                            _isUrgent ? AppColors.error : AppColors.textGrey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mark as urgent',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: _isUrgent,
                      activeThumbColor: AppColors.error,
                      onChanged: (value) => setState(() => _isUrgent = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: labs.isEmpty || _isUploadingFiles ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

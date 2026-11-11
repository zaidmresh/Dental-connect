// lib/screens/dentist/create_order_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_provider.dart';
import '../../services/file_upload_service.dart';
import '../../services/order_provider.dart';
import '../../utils/constants.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_widgets.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  bool _isUrgent = false;
  bool _isUploadingFiles = false;
  final List<String> _fileUrls = [];
  final List<String> _fileNames = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _uploadFiles() async {
    final user = context.read<AuthProvider>().currentUser!;
    setState(() => _isUploadingFiles = true);

    try {
      final uploadedFiles = await FileUploadService().pickAndUploadOrderFiles(
        ownerId: user.id,
        folder: 'order_files',
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
          content: Text('File uploaded successfully'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
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

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser!;
    final orderProvider = context.read<OrderProvider>();

    final order = await orderProvider.createOrder(
      dentistId: user.id,
      dentistName: user.fullName,
      caseDescription: _descController.text,
      fileUrls: _fileUrls,
      fileNames: _fileNames,
      isUrgent: _isUrgent,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.id} submitted successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: LoadingOverlay(
        isLoading: orderProvider.isLoading || _isUploadingFiles,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/logo.jpeg',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                // Upload section
                const Text(
                  'Upload Case',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploadFiles,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.05),
                    ),
                    child: _fileNames.isEmpty
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 60, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('Tap to upload files',
                                  style: TextStyle(color: AppColors.primary)),
                              Text('(X-rays, scans, images)',
                                  style: TextStyle(
                                      color: AppColors.textGrey, fontSize: 12)),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: AppColors.success, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                        '${_fileNames.length} file(s) uploaded',
                                        style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ..._fileNames.map(
                                  (f) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.image,
                                            size: 16, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(f,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textDark)),
                                      ],
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _uploadFiles,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add more'),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                // Description
                const Text(
                  'Case Description',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: '',
                  hint:
                      'Describe the dental case, measurements, materials needed...',
                  controller: _descController,
                  maxLines: 5,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Case description is required'
                      : null,
                ),
                const SizedBox(height: 16),
                // Urgent toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isUrgent
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _isUrgent ? AppColors.error : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high,
                          color:
                              _isUrgent ? AppColors.error : AppColors.textGrey),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mark as Urgent',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('This order requires priority processing',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isUrgent,
                        onChanged: (v) => setState(() => _isUrgent = v),
                        activeThumbColor: AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _submitOrder,
                  child: const Text('Submit Order'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

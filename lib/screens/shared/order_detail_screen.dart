// lib/screens/shared/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../services/auth_provider.dart';
import '../../services/order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_widgets.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _commentController = TextEditingController();
  final _descriptionEditController = TextEditingController();
  bool _isEditingDescription = false;

  @override
  void dispose() {
    _commentController.dispose();
    _descriptionEditController.dispose();
    super.dispose();
  }

  OrderModel? _getOrder(OrderProvider provider) {
    try {
      return provider.allOrders.firstWhere((o) => o.id == widget.orderId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    final user = context.read<AuthProvider>().currentUser!;
    await context
        .read<OrderProvider>()
        .acceptOrder(order.id, user.id, user.clinicOrLabName ?? user.fullName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order accepted!'),
          backgroundColor: AppColors.success));
    }
  }

  Future<void> _rejectOrder(OrderModel order) async {
    await context.read<OrderProvider>().rejectOrder(order.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await orderProvider.cancelOrder(order.id);
      navigator.pop();
    }
  }

  Future<void> _markComplete(OrderModel order) async {
    await context
        .read<OrderProvider>()
        .updateOrderStatus(order.id, OrderStatus.completed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order marked as completed!'),
          backgroundColor: AppColors.success));
    }
  }

  Future<void> _requestRevision(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ask for Revision'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Describe what needs to be revised...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, noteController.text),
              child: const Text('Send')),
        ],
      ),
    );
    if (note != null && note.isNotEmpty && mounted) {
      await orderProvider.requestRevision(order.id, note);
      messenger.showSnackBar(const SnackBar(
          content: Text('Revision requested!'),
          backgroundColor: AppColors.warning));
    }
  }

  Future<void> _setDeliveryDate(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      await orderProvider.setDeliveryDate(order.id, date);
    }
  }

  Future<void> _addComment(OrderModel order) async {
    if (_commentController.text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    await context.read<OrderProvider>().addComment(
        order.id, user.fullName, _commentController.text.trim(), user.role);
    _commentController.clear();
  }

  void _startEditDescription(OrderModel order) {
    _descriptionEditController.text = order.caseDescription;
    setState(() {
      _isEditingDescription = true;
    });
  }

  Future<void> _saveDescription(OrderModel order) async {
    final text = _descriptionEditController.text.trim();
    if (text.isEmpty) return;
    await context.read<OrderProvider>().updateOrderDescription(order.id, text);
    if (mounted) {
      setState(() {
        _isEditingDescription = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order description updated'),
          backgroundColor: AppColors.success));
    }
  }

  void _cancelEditDescription() {
    setState(() {
      _isEditingDescription = false;
    });
  }

  Future<void> _setPriority(OrderModel order, bool isUrgent) async {
    await context.read<OrderProvider>().setPriority(order.id, isUrgent);
  }

  Future<void> _changeStatus(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    OrderStatus selectedStatus = order.status;
    final newStatus = await showDialog<OrderStatus>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Order Status'),
          content: DropdownButtonFormField<OrderStatus>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.update, color: AppColors.primary),
            ),
            items: OrderStatus.values
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedStatus = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedStatus),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (newStatus != null && newStatus != order.status && mounted) {
      await orderProvider.updateOrderStatus(order.id, newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Order status changed to ${newStatus.label}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final order = _getOrder(orderProvider);
    final user = auth.currentUser!;
    final isDentist = user.role == UserRole.dentist;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Detail')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        actions: [
          StatusBadge(status: order.status),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('Order ID', '#${order.id}'),
                    _InfoRow('Dentist', order.dentistName),
                    if (order.labName != null) _InfoRow('Lab', order.labName!),
                    _InfoRow('Created',
                        DateFormat('MMM dd, yyyy').format(order.createdAt)),
                    if (order.updatedAt != null)
                      _InfoRow('Updated',
                          DateFormat('MMM dd, yyyy').format(order.updatedAt!)),
                    if (order.estimatedDeliveryDate != null)
                      _InfoRow(
                          'Est. Delivery',
                          DateFormat('MMM dd, yyyy')
                              .format(order.estimatedDeliveryDate!)),
                    if (order.isUrgent)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.priority_high,
                                color: AppColors.error, size: 18),
                            SizedBox(width: 4),
                            Text('URGENT ORDER',
                                style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Case description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Case Description',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 15)),
                    const SizedBox(height: 8),
                    if (_isEditingDescription)
                      TextField(
                        controller: _descriptionEditController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                            hintText: 'Edit case description'),
                      )
                    else
                      Text(order.caseDescription,
                          style: const TextStyle(color: AppColors.textDark)),
                    if (isDentist && order.canBeModified)
                      const SizedBox(height: 12),
                    if (isDentist && order.canBeModified)
                      Row(
                        children: [
                          if (_isEditingDescription)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _saveDescription(order),
                                child: const Text('Save Description'),
                              ),
                            )
                          else
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _startEditDescription(order),
                                child: const Text('Edit Description'),
                              ),
                            ),
                          if (_isEditingDescription) const SizedBox(width: 8),
                          if (_isEditingDescription)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelEditDescription,
                                child: const Text('Cancel'),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Revision note
            if (order.revisionNote != null) ...[
              const SizedBox(height: 12),
              Card(
                color: AppColors.warning.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.rate_review,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 6),
                        Text('Revision Requested',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning)),
                      ]),
                      const SizedBox(height: 6),
                      Text(order.revisionNote!,
                          style: const TextStyle(color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
            ],
            // Files
            if (order.fileUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attached Files (${order.fileUrls.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 8),
                      ...List.generate(
                        order.fileUrls.length,
                        (index) {
                          var fileName = order.fileUrls[index];
                          if (index < order.fileNames.length) {
                            if (order.fileNames[index].isNotEmpty) {
                              fileName = order.fileNames[index];
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Action buttons
            const SizedBox(height: 16),
            if (isDentist) ...[
              if (order.canBeCancelled)
                OutlinedButton.icon(
                  onPressed: () => _cancelOrder(order),
                  icon:
                      const Icon(Icons.cancel_outlined, color: AppColors.error),
                  label: const Text('Cancel Order',
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.error)),
                ),
              if (order.canBeCancelled) const SizedBox(height: 8),
              if (order.status == OrderStatus.pending && isDentist)
                ElevatedButton.icon(
                  onPressed: () => _setPriority(order, !order.isUrgent),
                  icon: Icon(order.isUrgent ? Icons.flag : Icons.flag_outlined),
                  label: Text(
                      order.isUrgent ? 'Remove Urgent Flag' : 'Mark as Urgent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        order.isUrgent ? AppColors.warning : AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _changeStatus(order),
                icon: const Icon(Icons.update, color: AppColors.primary),
                label: const Text('Change Order Status'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _requestRevision(order),
                icon: const Icon(Icons.rate_review_outlined,
                    color: AppColors.warning),
                label: const Text('Ask for Revision',
                    style: TextStyle(color: AppColors.warning)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.warning),
                ),
              ),
            ] else ...[
              // Technician actions
              if (order.status == OrderStatus.pending) ...[
                ElevatedButton.icon(
                  onPressed: () => _acceptOrder(order),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept Order'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _rejectOrder(order),
                  icon: const Icon(Icons.close, color: AppColors.error),
                  label: const Text('Reject Order',
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.error)),
                ),
              ],
              if (order.status == OrderStatus.accepted ||
                  order.status == OrderStatus.inProgress) ...[
                ElevatedButton.icon(
                  onPressed: () => _markComplete(order),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _setDeliveryDate(order),
                  icon: const Icon(Icons.calendar_today,
                      color: AppColors.primary),
                  label: const Text('Set Delivery Date'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _changeStatus(order),
                icon: const Icon(Icons.update, color: AppColors.primary),
                label: const Text('Change Order Status'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
            // Comments section
            const SizedBox(height: 20),
            const Text('Comments & Feedback',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 16)),
            const SizedBox(height: 8),
            if (order.comments.isEmpty)
              const Text('No comments yet.',
                  style: TextStyle(color: AppColors.textGrey)),
            ...order.comments.map(
              (c) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            c.authorRole == UserRole.dentist
                                ? Icons.local_hospital
                                : Icons.science,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(c.authorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary)),
                          const Spacer(),
                          Text(DateFormat('MMM dd, HH:mm').format(c.timestamp),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textGrey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.text,
                          style: const TextStyle(color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addComment(order),
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style:
                    const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

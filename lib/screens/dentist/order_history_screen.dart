// lib/screens/dentist/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_widgets.dart';
import '../shared/order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final bool filterCompleted;
  final bool filterCancelled;

  const OrderHistoryScreen({
    super.key,
    this.filterCompleted = false,
    this.filterCancelled = false,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final orderProvider = context.watch<OrderProvider>();
    var orders = user.role == UserRole.technician
        ? orderProvider.ordersForTechnician(user.id)
        : orderProvider.ordersForDentist(user.id);

    if (widget.filterCompleted) {
      orders = orders.where((o) => o.status == OrderStatus.completed).toList();
    } else if (widget.filterCancelled) {
      orders = orders.where((o) => o.status == OrderStatus.cancelled).toList();
    }

    if (_query.isNotEmpty) {
      orders = orders
          .where((o) =>
              o.id.toLowerCase().contains(_query.toLowerCase()) ||
              o.caseDescription.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    String title = 'Order History';
    if (widget.filterCompleted) title = 'Completed Orders';
    if (widget.filterCancelled) title = 'Cancelled Orders';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? EmptyState(
                    icon: Icons.history,
                    message: _query.isNotEmpty
                        ? 'No orders match "$_query"'
                        : 'No orders found',
                  )
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (_, i) => OrderCard(
                      order: orders[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailScreen(orderId: orders[i].id)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

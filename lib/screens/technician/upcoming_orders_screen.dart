// lib/screens/technician/upcoming_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/order_provider.dart';
import '../../widgets/app_widgets.dart';
import '../shared/order_detail_screen.dart';

class UpcomingOrdersScreen extends StatelessWidget {
  const UpcomingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final orders =
        context.watch<OrderProvider>().pendingOrdersForTechnician(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Orders')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'No pending orders at the moment.',
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
    );
  }
}

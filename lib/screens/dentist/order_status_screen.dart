// lib/screens/dentist/order_status_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/order_provider.dart';
import '../../widgets/app_widgets.dart';
import '../shared/order_detail_screen.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final orders = context.watch<OrderProvider>().ordersForDentist(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              message: 'No orders found.\nCreate your first order!',
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

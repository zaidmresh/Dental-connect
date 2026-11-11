// lib/screens/shared/search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/order_provider.dart';
import '../../widgets/app_widgets.dart';
import 'order_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final orderProvider = context.watch<OrderProvider>();

    final results = _query.isEmpty
        ? <dynamic>[]
        : orderProvider.searchOrders(_query, user.id, user.role);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search orders...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? const EmptyState(
              icon: Icons.search,
              message: 'Type to search orders by ID, description or status',
            )
          : results.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  message: 'No orders found for "$_query"',
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) => OrderCard(
                    order: results[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailScreen(orderId: results[i].id)),
                    ),
                  ),
                ),
    );
  }
}

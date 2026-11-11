// lib/screens/technician/technician_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_widgets.dart';
import '../auth/login_screen.dart';
import '../dentist/order_history_screen.dart';
import 'upcoming_orders_screen.dart';
import '../shared/order_detail_screen.dart';
import '../shared/search_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final user = auth.currentUser!;
    final pending = orders.pendingOrdersForTechnician(user.id);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Dental Connect'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(context, user.displayName),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/logo.jpeg',
                      width: 50, height: 50, fit: BoxFit.contain),
                  const SizedBox(height: 12),
                  Text('Welcome,',
                      style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 16)),
                  Text(user.displayName,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        '${pending.length} new order${pending.length == 1 ? '' : 's'} waiting',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Quick Actions'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.inbox,
                    label: 'View Upcoming Orders',
                    badge: pending.length,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UpcomingOrdersScreen())),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    icon: Icons.update,
                    label: 'Update Order Status',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UpcomingOrdersScreen())),
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    icon: Icons.history,
                    label: 'Order History',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen())),
                  ),
                ],
              ),
            ),
            // Pending orders
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 8),
              SectionHeader(
                  title: 'New Orders', subtitle: 'Tap to accept or reject'),
              ...pending.take(5).map((o) => OrderCard(
                    order: o,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(orderId: o.id))),
                  )),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String name) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.white,
                  child: Icon(Icons.person, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 8),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Text('Lab Technician',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          ListTile(
              leading: const Icon(Icons.home, color: AppColors.primary),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context)),
          ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary),
              title: const Text('Search'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.inbox, color: AppColors.primary),
              title: const Text('Upcoming Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UpcomingOrdersScreen()));
              }),
          ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: const Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen()));
              }),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              onTap: _logout),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
        if (badge > 0)
          Positioned(
            right: 12,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

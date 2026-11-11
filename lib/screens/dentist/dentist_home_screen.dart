// lib/screens/dentist/dentist_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/order_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_widgets.dart';
import '../auth/login_screen.dart';
import 'create_order_screen.dart';
import 'order_status_screen.dart';
import 'order_history_screen.dart';
import 'request_lab_work_screen.dart';
import '../shared/search_screen.dart';
import '../shared/order_detail_screen.dart';

class DentistHomeScreen extends StatefulWidget {
  const DentistHomeScreen({super.key});

  @override
  State<DentistHomeScreen> createState() => _DentistHomeScreenState();
}

class _DentistHomeScreenState extends State<DentistHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _availabilityController = TextEditingController();

  @override
  void dispose() {
    _availabilityController.dispose();
    super.dispose();
  }

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
    final myOrders = orders.ordersForDentist(user.id);
    final activeOrders = myOrders
        .where((o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.rejected)
        .toList();

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
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    Image.asset(
                      'assets/logo.jpeg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome,',
                      style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 16),
                    ),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Active',
                        value: '${activeOrders.length}',
                        icon: Icons.pending_actions_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'Total',
                        value: '${myOrders.length}',
                        icon: Icons.assignment_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick actions
              const SizedBox(height: 8),
              const SectionHeader(title: 'Quick Actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ActionButton(
                      icon: Icons.science_outlined,
                      label: 'Request Lab Work',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RequestLabWorkScreen())),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Create Order',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateOrderScreen())),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.track_changes,
                      label: 'View Order Status',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OrderStatusScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              SectionHeader(
                title: 'Active Orders',
                subtitle: '${activeOrders.length} in progress',
              ),
              if (activeOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    message: 'No active orders.\nCreate your first order!',
                  ),
                )
              else
                ...activeOrders.take(5).map((order) => OrderCard(
                      order: order,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailScreen(orderId: order.id))),
                    )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateOrderScreen())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Order', style: TextStyle(color: Colors.white)),
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
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
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
                const Text('Dentist',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          _DrawerItem(
              icon: Icons.home,
              label: 'Home',
              onTap: () => Navigator.pop(context)),
          _DrawerItem(
              icon: Icons.search,
              label: 'Search',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()));
              }),
          _DrawerItem(
              icon: Icons.science_outlined,
              label: 'Request Lab Work',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RequestLabWorkScreen()));
              }),
          _DrawerItem(
              icon: Icons.history,
              label: 'Order History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen()));
              }),
          _DrawerItem(
              icon: Icons.check_circle_outline,
              label: 'Completed Orders',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const OrderHistoryScreen(filterCompleted: true)));
              }),
          _DrawerItem(
              icon: Icons.cancel_outlined,
              label: 'Cancelled Orders',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const OrderHistoryScreen(filterCancelled: true)));
              }),
          const Divider(),
          _DrawerItem(
              icon: Icons.logout,
              label: 'Logout',
              color: AppColors.error,
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

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(label, style: TextStyle(color: color ?? AppColors.textDark)),
      onTap: onTap,
    );
  }
}

// lib/widgets/app_widgets.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

// Logo widget
class DentalLogo extends StatelessWidget {
  final double size;
  const DentalLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.medical_services_rounded,
            size: size, color: AppColors.primary),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: 'Dental ',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.bold)),
              TextSpan(
                  text: 'Connect',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

// Status badge
class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color, width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            color: status.color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Order card
class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('#${order.id}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  if (order.isUrgent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('URGENT',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ],
                  const Spacer(),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.caseDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(order.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                  if (order.estimatedDeliveryDate != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.local_shipping,
                        size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd').format(order.estimatedDeliveryDate!),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textGrey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          if (subtitle != null)
            Text(subtitle!,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// Empty state
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppColors.border),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 15),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  const LoadingOverlay(
      {super.key, required this.child, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// Custom text field
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final IconData? prefixIcon;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscure = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary)
            : null,
      ),
    );
  }
}

// lib/services/order_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<OrderModel> _orders = [];
  bool _isLoading = false;

  OrderProvider() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      _orders
        ..clear()
        ..addAll(snapshot.docs.map((doc) => OrderModel.fromJson(doc.data())));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toJson());
    } catch (_) {}
  }

  List<OrderModel> get allOrders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  List<OrderModel> ordersForDentist(String dentistId) =>
      _orders.where((o) => o.dentistId == dentistId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<OrderModel> get pendingOrdersForLab =>
      _orders.where((o) => o.status == OrderStatus.pending).toList()
        ..sort((a, b) {
          if (a.isUrgent && !b.isUrgent) return -1;
          if (!a.isUrgent && b.isUrgent) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

  List<OrderModel> pendingOrdersForTechnician(String labId) => _orders
      .where((o) =>
          o.status == OrderStatus.pending &&
          (o.labId == null || o.labId == labId))
      .toList()
    ..sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

  List<OrderModel> ordersForTechnician(String labId) =>
      _orders.where((o) => o.labId == labId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<OrderModel> searchOrders(String query, String userId, UserRole role) {
    final q = query.toLowerCase();
    final source =
        role == UserRole.dentist ? ordersForDentist(userId) : _orders;
    return source.where((o) {
      return o.id.toLowerCase().contains(q) ||
          o.caseDescription.toLowerCase().contains(q) ||
          o.status.label.toLowerCase().contains(q);
    }).toList();
  }

  Future<OrderModel> createOrder({
    required String dentistId,
    required String dentistName,
    String? labId,
    String? labName,
    required String caseDescription,
    List<String> fileUrls = const [],
    List<String> fileNames = const [],
    bool isUrgent = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final order = OrderModel(
      id: const Uuid().v4().substring(0, 8).toUpperCase(),
      dentistId: dentistId,
      dentistName: dentistName,
      labId: labId,
      labName: labName,
      caseDescription: caseDescription,
      fileUrls: fileUrls,
      fileNames: fileNames,
      isUrgent: isUrgent,
      createdAt: DateTime.now(),
      status: OrderStatus.pending,
    );

    _orders.add(order);
    await _saveOrder(order);
    _isLoading = false;
    notifyListeners();
    return order;
  }

  Future<void> acceptOrder(String orderId, String labId, String labName) async {
    final order = _findOrder(orderId);
    if (order == null) return;
    order.status = OrderStatus.accepted;
    order.updatedAt = DateTime.now();
    // In real app, set labId/labName; here we recreate since fields are final.
    final updatedOrder = OrderModel(
      id: order.id,
      dentistId: order.dentistId,
      dentistName: order.dentistName,
      labId: labId,
      labName: labName,
      caseDescription: order.caseDescription,
      fileUrls: order.fileUrls,
      fileNames: order.fileNames,
      status: OrderStatus.accepted,
      createdAt: order.createdAt,
      updatedAt: DateTime.now(),
      isUrgent: order.isUrgent,
      comments: order.comments,
    );
    _orders[_orders.indexOf(order)] = updatedOrder;
    await _saveOrder(updatedOrder);
    notifyListeners();
  }

  Future<void> rejectOrder(String orderId) async {
    _updateStatus(orderId, OrderStatus.rejected);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    _updateStatus(orderId, status);
  }

  Future<void> cancelOrder(String orderId) async {
    final order = _findOrder(orderId);
    if (order == null || !order.canBeCancelled) return;
    _updateStatus(orderId, OrderStatus.cancelled);
  }

  Future<void> requestRevision(String orderId, String note) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final o = _orders[idx];
    _orders[idx] = OrderModel(
      id: o.id,
      dentistId: o.dentistId,
      dentistName: o.dentistName,
      labId: o.labId,
      labName: o.labName,
      caseDescription: o.caseDescription,
      fileUrls: o.fileUrls,
      fileNames: o.fileNames,
      status: OrderStatus.awaitingRevision,
      createdAt: o.createdAt,
      updatedAt: DateTime.now(),
      estimatedDeliveryDate: o.estimatedDeliveryDate,
      isUrgent: o.isUrgent,
      comments: o.comments,
      revisionNote: note,
    );
    await _saveOrder(_orders[idx]);
    notifyListeners();
  }

  Future<void> updateOrderDescription(
      String orderId, String caseDescription) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final o = _orders[idx];
    if (!o.canBeModified) return;
    _orders[idx] = OrderModel(
      id: o.id,
      dentistId: o.dentistId,
      dentistName: o.dentistName,
      labId: o.labId,
      labName: o.labName,
      caseDescription: caseDescription,
      fileUrls: o.fileUrls,
      fileNames: o.fileNames,
      status: o.status,
      createdAt: o.createdAt,
      updatedAt: DateTime.now(),
      estimatedDeliveryDate: o.estimatedDeliveryDate,
      isUrgent: o.isUrgent,
      comments: o.comments,
      revisionNote: o.revisionNote,
    );
    await _saveOrder(_orders[idx]);
    notifyListeners();
  }

  Future<void> setDeliveryDate(String orderId, DateTime date) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final o = _orders[idx];
    _orders[idx] = OrderModel(
      id: o.id,
      dentistId: o.dentistId,
      dentistName: o.dentistName,
      labId: o.labId,
      labName: o.labName,
      caseDescription: o.caseDescription,
      fileUrls: o.fileUrls,
      fileNames: o.fileNames,
      status: o.status,
      createdAt: o.createdAt,
      updatedAt: DateTime.now(),
      estimatedDeliveryDate: date,
      isUrgent: o.isUrgent,
      comments: o.comments,
      revisionNote: o.revisionNote,
    );
    await _saveOrder(_orders[idx]);
    notifyListeners();
  }

  Future<void> setPriority(String orderId, bool isUrgent) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final o = _orders[idx];
    _orders[idx] = OrderModel(
      id: o.id,
      dentistId: o.dentistId,
      dentistName: o.dentistName,
      labId: o.labId,
      labName: o.labName,
      caseDescription: o.caseDescription,
      fileUrls: o.fileUrls,
      fileNames: o.fileNames,
      status: o.status,
      createdAt: o.createdAt,
      updatedAt: DateTime.now(),
      estimatedDeliveryDate: o.estimatedDeliveryDate,
      isUrgent: isUrgent,
      comments: o.comments,
      revisionNote: o.revisionNote,
    );
    await _saveOrder(_orders[idx]);
    notifyListeners();
  }

  Future<void> addComment(
      String orderId, String authorName, String text, UserRole role) async {
    final order = _findOrder(orderId);
    if (order == null) return;
    final comment = CommentModel(
      id: const Uuid().v4(),
      authorName: authorName,
      text: text,
      timestamp: DateTime.now(),
      authorRole: role,
    );
    final updatedComments = [...order.comments, comment];
    final idx = _orders.indexOf(order);
    _orders[idx] = OrderModel(
      id: order.id,
      dentistId: order.dentistId,
      dentistName: order.dentistName,
      labId: order.labId,
      labName: order.labName,
      caseDescription: order.caseDescription,
      fileUrls: order.fileUrls,
      fileNames: order.fileNames,
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: DateTime.now(),
      estimatedDeliveryDate: order.estimatedDeliveryDate,
      isUrgent: order.isUrgent,
      comments: updatedComments,
      revisionNote: order.revisionNote,
    );
    await _saveOrder(_orders[idx]);
    notifyListeners();
  }

  OrderModel? _findOrder(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  void _updateStatus(String orderId, OrderStatus status) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    _orders[idx].status = status;
    _orders[idx].updatedAt = DateTime.now();
    _saveOrder(_orders[idx]);
    notifyListeners();
  }
}

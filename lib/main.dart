// ============================================================
// PART 1: الثوابت + الاستثناءات + الأدوات + الموديلات
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- الثوابت ----
const String kAppName = 'متجر الموبايلات';
const String kAppVersion = '2.0.0';
const String kCurrency = 'ر.س';

// ---- الاستثناءات ----
class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => 'AppException: $message';
}

class AuthException extends AppException {
  AuthException(String message) : super(message);
}

class StoreException extends AppException {
  StoreException(String message) : super(message);
}

class DatabaseException extends AppException {
  DatabaseException(String message) : super(message);
}

// ---- الأدوات ----
class Utils {
  static String formatCurrency(num amount) {
    return '${NumberFormat('#,##0.00').format(amount)} $kCurrency';
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(9999).toString();
  }

  static bool isEmailValid(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  static bool isPhoneValid(String phone) {
    return RegExp(r'^05\d{8}$').hasMatch(phone);
  }
}

// ---- الموديلات ----

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String role; // 'admin' | 'employee'
  final String? storeId;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.phone,
    required this.role,
    this.storeId,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phone: map['phone'],
      role: map['role'] ?? 'employee',
      storeId: map['storeId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null ? (map['lastLogin'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'role': role,
      'storeId': storeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';
}

class StoreModel {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String ownerId;
  final DateTime createdAt;
  final bool isActive;

  StoreModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    required this.ownerId,
    required this.createdAt,
    this.isActive = true,
  });

  factory StoreModel.fromMap(String id, Map<String, dynamic> map) {
    return StoreModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'],
      phone: map['phone'],
      ownerId: map['ownerId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final num price;
  final int quantity;
  final String? imageUrl;
  final String storeId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.storeId,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'],
      storeId: map['storeId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'storeId': storeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isDeleted': isDeleted,
    };
  }
}

class InvoiceModel {
  final String id;
  final String storeId;
  final String customerName;
  final String? customerPhone;
  final List<InvoiceItem> items;
  final num subtotal;
  final num discount;
  final num total;
  final num paidAmount;
  final num remainingAmount;
  final String paymentMethod; // 'cash' | 'card' | 'bank' | 'credit'
  final DateTime date;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final bool isDeleted;
  final String? deletionRequestedBy;
  final DateTime? deletionRequestedAt;

  InvoiceModel({
    required this.id,
    required this.storeId,
    required this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    required this.date,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.isDeleted = false,
    this.deletionRequestedBy,
    this.deletionRequestedAt,
  });

  factory InvoiceModel.fromMap(String id, Map<String, dynamic> map) {
    return InvoiceModel(
      id: id,
      storeId: map['storeId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'],
      items: (map['items'] as List<dynamic>? ?? []).map((item) => InvoiceItem.fromMap(item)).toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'cash',
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isDeleted: map['isDeleted'] ?? false,
      deletionRequestedBy: map['deletionRequestedBy'],
      deletionRequestedAt: map['deletionRequestedAt'] != null ? (map['deletionRequestedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'paymentMethod': paymentMethod,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
      'deletionRequestedBy': deletionRequestedBy,
      'deletionRequestedAt': deletionRequestedAt != null ? Timestamp.fromDate(deletionRequestedAt!) : null,
    };
  }
}

class InvoiceItem {
  final String productId;
  final String productName;
  final int quantity;
  final num unitPrice;
  final num totalPrice;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

class DailyReportModel {
  final String id;
  final String storeId;
  final DateTime date;
  final int totalInvoices;
  final num totalRevenue;
  final num totalCash;
  final num totalCard;
  final num totalBank;
  final num totalCredit;
  final num totalDiscount;
  final Map<String, int> topProducts;

  DailyReportModel({
    required this.id,
    required this.storeId,
    required this.date,
    required this.totalInvoices,
    required this.totalRevenue,
    required this.totalCash,
    required this.totalCard,
    required this.totalBank,
    required this.totalCredit,
    required this.totalDiscount,
    required this.topProducts,
  });

  factory DailyReportModel.fromMap(String id, Map<String, dynamic> map) {
    return DailyReportModel(
      id: id,
      storeId: map['storeId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      totalInvoices: map['totalInvoices'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      totalCash: (map['totalCash'] ?? 0).toDouble(),
      totalCard: (map['totalCard'] ?? 0).toDouble(),
      totalBank: (map['totalBank'] ?? 0).toDouble(),
      totalCredit: (map['totalCredit'] ?? 0).toDouble(),
      totalDiscount: (map['totalDiscount'] ?? 0).toDouble(),
      topProducts: Map<String, int>.from(map['topProducts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'date': Timestamp.fromDate(date),
      'totalInvoices': totalInvoices,
      'totalRevenue': totalRevenue,
      'totalCash': totalCash,
      'totalCard': totalCard,
      'totalBank': totalBank,
      'totalCredit': totalCredit,
      'totalDiscount': totalDiscount,
      'topProducts': topProducts,
    };
  }
}

class DeletionRequestModel {
  final String id;
  final String storeId;
  final String documentId;
  final String documentType; // 'invoice' | 'product' | 'category'
  final String requestedBy;
  final DateTime requestedAt;
  final String reason;
  final bool isApproved;
  final DateTime? approvedAt;
  final String? approvedBy;

  DeletionRequestModel({
    required this.id,
    required this.storeId,
    required this.documentId,
    required this.documentType,
    required this.requestedBy,
    required this.requestedAt,
    required this.reason,
    this.isApproved = false,
    this.approvedAt,
    this.approvedBy,
  });

  factory DeletionRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return DeletionRequestModel(
      id: id,
      storeId: map['storeId'] ?? '',
      documentId: map['documentId'] ?? '',
      documentType: map['documentType'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
      isApproved: map['isApproved'] ?? false,
      approvedAt: map['approvedAt'] != null ? (map['approvedAt'] as Timestamp).toDate() : null,
      approvedBy: map['approvedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'documentId': documentId,
      'documentType': documentType,
      'requestedBy': requestedBy,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reason': reason,
      'isApproved': isApproved,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
    };
  }
}

// ============================================================
// PART 2: الخدمات (AuthService + StoreService + DatabaseService)
// ============================================================

// ---- AuthService ----
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw AuthException('فشل تسجيل الدخول: $e');
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(displayName);
      
      // Create user document
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: 'admin',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(credential.user!.uid).set(userModel.toMap());
      return credential;
    } catch (e) {
      throw AuthException('فشل التسجيل: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({'role': newRole});
    } catch (e) {
      throw AuthException('فشل تحديث الدور: $e');
    }
  }

  Future<void> updateUserStore(String userId, String? storeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'storeId': storeId});
    } catch (e) {
      throw AuthException('فشل تحديث المتجر: $e');
    }
  }
}

// ---- StoreService ----
class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StoreModel> createStore(String name, String ownerId, {String? address, String? phone}) async {
    try {
      final store = StoreModel(
        id: Utils.generateId(),
        name: name,
        address: address,
        phone: phone,
        ownerId: ownerId,
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      await _firestore.collection('stores').doc(store.id).set(store.toMap());
      return store;
    } catch (e) {
      throw StoreException('فشل إنشاء المتجر: $e');
    }
  }

  Future<StoreModel?> getStore(String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists) {
        return StoreModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw StoreException('فشل جلب المتجر: $e');
    }
  }

  Future<List<StoreModel>> getUserStores(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => StoreModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw StoreException('فشل جلب المتاجر: $e');
    }
  }

  Future<void> updateStore(String storeId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('stores').doc(storeId).update(data);
    } catch (e) {
      throw StoreException('فشل تحديث المتجر: $e');
    }
  }

  Future<void> deleteStore(String storeId) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({'isActive': false});
    } catch (e) {
      throw StoreException('فشل حذف المتجر: $e');
    }
  }
}

// ---- DatabaseService ----
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products
  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).set(product.toMap());
    } catch (e) {
      throw DatabaseException('فشل إضافة المنتج: $e');
    }
  }

  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw DatabaseException('فشل جلب المنتج: $e');
    }
  }

  Future<List<ProductModel>> getProducts(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('storeId', isEqualTo: storeId)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw DatabaseException('فشل جلب المنتجات: $e');
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('products').doc(productId).update(data);
    } catch (e) {
      throw DatabaseException('فشل تحديث المنتج: $e');
    }
  }

  Future<void> softDeleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw DatabaseException('فشل حذف المنتج: $e');
    }
  }

  // Invoices
  Future<void> addInvoice(InvoiceModel invoice) async {
    try {
      await _firestore.collection('invoices').doc(invoice.id).set(invoice.toMap());
    } catch (e) {
      throw DatabaseException('فشل إضافة الفاتورة: $e');
    }
  }

  Future<InvoiceModel?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      if (doc.exists) {
        return InvoiceModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw DatabaseException('فشل جلب الفاتورة: $e');
    }
  }

  Future<List<InvoiceModel>> getInvoices(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('storeId', isEqualTo: storeId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => InvoiceModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw DatabaseException('فشل جلب الفواتير: $e');
    }
  }

  Future<void> softDeleteInvoice(String invoiceId, String userId, String reason) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'isDeleted': true,
        'deletionRequestedBy': userId,
        'deletionRequestedAt': Timestamp.now(),
        'deletionReason': reason,
      });
    } catch (e) {
      throw DatabaseException('فشل طلب حذف الفاتورة: $e');
    }
  }

  // Daily Reports
  Future<void> saveDailyReport(DailyReportModel report) async {
    try {
      await _firestore.collection('dailyReports').doc(report.id).set(report.toMap());
    } catch (e) {
      throw DatabaseException('فشل حفظ التقرير: $e');
    }
  }

  Future<DailyReportModel?> getDailyReport(String storeId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('dailyReports')
          .where('storeId', isEqualTo: storeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return DailyReportModel.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw DatabaseException('فشل جلب التقرير: $e');
    }
  }

  // Deletion Requests
  Future<void> addDeletionRequest(DeletionRequestModel request) async {
    try {
      await _firestore.collection('deletionRequests').doc(request.id).set(request.toMap());
    } catch (e) {
      throw DatabaseException('فشل إضافة طلب الحذف: $e');
    }
  }

  Future<List<DeletionRequestModel>> getDeletionRequests(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('deletionRequests')
          .where('storeId', isEqualTo: storeId)
          .where('isApproved', isEqualTo: false)
          .orderBy('requestedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => DeletionRequestModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw DatabaseException('فشل جلب طلبات الحذف: $e');
    }
  }

  Future<void> approveDeletionRequest(String requestId, String approvedBy) async {
    try {
      final requestDoc = await _firestore.collection('deletionRequests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw DatabaseException('طلب الحذف غير موجود');
      }
      
      final request = DeletionRequestModel.fromMap(requestDoc.id, requestDoc.data()!);
      
      // Mark as approved
      await _firestore.collection('deletionRequests').doc(requestId).update({
        'isApproved': true,
        'approvedAt': Timestamp.now(),
        'approvedBy': approvedBy,
      });
      
      // Actually delete the document from its collection
      if (request.documentType == 'invoice') {
        await _firestore.collection('invoices').doc(request.documentId).delete();
      } else if (request.documentType == 'product') {
        await _firestore.collection('products').doc(request.documentId).delete();
      } else if (request.documentType == 'category') {
        // Categories not implemented yet
      }
    } catch (e) {
      throw DatabaseException('فشل الموافقة على الحذف: $e');
    }
  }

  Future<void> rejectDeletionRequest(String requestId) async {
    try {
      await _firestore.collection('deletionRequests').doc(requestId).update({
        'isApproved': false,
        'approvedAt': Timestamp.now(),
      });
    } catch (e) {
      throw DatabaseException('فشل رفض طلب الحذف: $e');
    }
  }

  // Employees
  Future<void> addEmployee(String storeId, String userId) async {
    try {
      await _firestore.collection('employees').doc(userId).set({
        'storeId': storeId,
        'addedAt': Timestamp.now(),
        'isActive': true,
      });
    } catch (e) {
      throw DatabaseException('فشل إضافة الموظف: $e');
    }
  }

  Future<List<UserModel>> getEmployees(String storeId) async {
    try {
      final employeesSnapshot = await _firestore
          .collection('employees')
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .get();
      
      final List<UserModel> employees = [];
      for (final doc in employeesSnapshot.docs) {
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          employees.add(UserModel.fromMap(userDoc.id, userDoc.data()!));
        }
      }
      return employees;
    } catch (e) {
      throw DatabaseException('فشل جلب الموظفين: $e');
    }
  }

  Future<void> removeEmployee(String userId) async {
    try {
      await _firestore.collection('employees').doc(userId).update({'isActive': false});
    } catch (e) {
      throw DatabaseException('فشل إزالة الموظف: $e');
    }
  }

  Future<bool> isEmployee(String userId, String storeId) async {
    try {
      final doc = await _firestore.collection('employees').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['storeId'] == storeId && data['isActive'] == true;
      }
      return false;
    } catch (e) {
      throw DatabaseException('فشل التحقق من الموظف: $e');
    }
  }
}

// ============================================================
// PART 3: RemoteConfigService + InvoiceRepository (مع تقرير بلا حد أقصى)
// ============================================================

// ---- RemoteConfigService ----
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      
      await _remoteConfig.setDefaults({
        'app_version_min': '1.0.0',
        'app_version_latest': '2.0.0',
        'maintenance_mode': false,
        'maintenance_message': 'جاري الصيانة',
        'max_invoices_per_day': 1000,
        'max_products_per_store': 10000,
      });
      
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('RemoteConfig error: $e');
    }
  }

  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  int getInt(String key) => _remoteConfig.getInt(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);
}

// ---- InvoiceRepository ----
class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<InvoiceModel>> getInvoicesNoLimit(String storeId, {DateTime? from, DateTime? to}) async {
    try {
      Query query = _firestore
          .collection('invoices')
          .where('storeId', isEqualTo: storeId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true);
      
      if (from != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      }
      if (to != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => InvoiceModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      throw DatabaseException('فشل جلب الفواتير: $e');
    }
  }

  Future<DailyReportModel> generateDailyReport(String storeId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final invoices = await getInvoicesNoLimit(
        storeId, 
        from: startOfDay, 
        to: endOfDay
      );
      
      if (invoices.isEmpty) {
        return DailyReportModel(
          id: Utils.generateId(),
          storeId: storeId,
          date: date,
          totalInvoices: 0,
          totalRevenue: 0,
          totalCash: 0,
          totalCard: 0,
          totalBank: 0,
          totalCredit: 0,
          totalDiscount: 0,
          topProducts: {},
        );
      }
      
      num totalRevenue = 0;
      num totalCash = 0;
      num totalCard = 0;
      num totalBank = 0;
      num totalCredit = 0;
      num totalDiscount = 0;
      Map<String, int> productCount = {};
      
      for (final invoice in invoices) {
        totalRevenue += invoice.total;
        totalDiscount += invoice.discount;
        
        switch (invoice.paymentMethod) {
          case 'cash':
            totalCash += invoice.paidAmount;
            break;
          case 'card':
            totalCard += invoice.paidAmount;
            break;
          case 'bank':
            totalBank += invoice.paidAmount;
            break;
          case 'credit':
            totalCredit += invoice.paidAmount;
            break;
        }
        
        for (final item in invoice.items) {
          productCount[item.productName] = (productCount[item.productName] ?? 0) + item.quantity;
        }
      }
      
      // Sort top products
      var sortedProducts = Map.fromEntries(
        productCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
      );
      
      return DailyReportModel(
        id: Utils.generateId(),
        storeId: storeId,
        date: date,
        totalInvoices: invoices.length,
        totalRevenue: totalRevenue,
        totalCash: totalCash,
        totalCard: totalCard,
        totalBank: totalBank,
        totalCredit: totalCredit,
        totalDiscount: totalDiscount,
        topProducts: sortedProducts,
      );
    } catch (e) {
      throw DatabaseException('فشل توليد التقرير: $e');
    }
  }
}

// ============================================================
// PART 4: AppController (GetX) — مع كل منطق الدخول/التسجيل/الربط الجديد
// ============================================================

class AppController extends GetxController {
  final AuthService _authService = AuthService();
  final StoreService _storeService = StoreService();
  final DatabaseService _databaseService = DatabaseService();
  final InvoiceRepository _invoiceRepository = InvoiceRepository();
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  // Observables
  var currentUser = Rxn<UserModel>();
  var currentStore = Rxn<StoreModel>();
  var isLoading = false.obs;
  var isStoreLinked = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;

  // Stream subscription
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() async {
    super.onInit();
    await _remoteConfig.initialize();
    _authSubscription = _authService.user.listen((user) async {
      if (user != null) {
        final userModel = await _authService.getCurrentUserModel();
        currentUser.value = userModel;
        if (userModel?.storeId != null) {
          await loadStore(userModel!.storeId!);
          isStoreLinked.value = true;
        } else {
          isStoreLinked.value = false;
        }
      } else {
        currentUser.value = null;
        currentStore.value = null;
        isStoreLinked.value = false;
      }
      update();
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  // ---- Auth Methods ----
  Future<bool> signIn(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('AuthException: ', '');
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _authService.signUpWithEmailAndPassword(email, password, displayName);
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('AuthException: ', '');
      isLoading.value = false;
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    Get.offAllNamed('/login');
  }

  // ---- Store Methods ----
  Future<bool> createAndLinkStore(String name, {String? address, String? phone}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = _authService.currentUser;
      if (user == null) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        isLoading.value = false;
        return false;
      }
      
      final store = await _storeService.createStore(name, user.uid, address: address, phone: phone);
      await _authService.updateUserStore(user.uid, store.id);
      
      // Add user as admin employee
      await _databaseService.addEmployee(store.id, user.uid);
      
      currentStore.value = store;
      isStoreLinked.value = true;
      isLoading.value = false;
      successMessage.value = 'تم إنشاء المتجر وربطه بنجاح';
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('StoreException: ', '');
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> linkToExistingStore(String storeId) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = _authService.currentUser;
      if (user == null) {
        errorMessage.value = 'يجب تسجيل الدخول أولاً';
        isLoading.value = false;
        return false;
      }
      
      final store = await _storeService.getStore(storeId);
      if (store == null) {
        errorMessage.value = 'المتجر غير موجود';
        isLoading.value = false;
        return false;
      }
      
      await _authService.updateUserStore(user.uid, store.id);
      await _databaseService.addEmployee(store.id, user.uid);
      
      currentStore.value = store;
      isStoreLinked.value = true;
      isLoading.value = false;
      successMessage.value = 'تم الربط بنجاح';
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('StoreException: ', '');
      isLoading.value = false;
      return false;
    }
  }

  Future<void> loadStore(String storeId) async {
    try {
      final store = await _storeService.getStore(storeId);
      if (store != null) {
        currentStore.value = store;
      }
    } catch (e) {
      errorMessage.value = 'فشل تحميل المتجر: $e';
    }
  }

  // ---- Product Methods ----
  Future<List<ProductModel>> getProducts() async {
    if (currentStore.value == null) return [];
    try {
      return await _databaseService.getProducts(currentStore.value!.id);
    } catch (e) {
      errorMessage.value = 'فشل جلب المنتجات: $e';
      return [];
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      await _databaseService.addProduct(product);
      return true;
    } catch (e) {
      errorMessage.value = 'فشل إضافة المنتج: $e';
      return false;
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _databaseService.updateProduct(productId, data);
      return true;
    } catch (e) {
      errorMessage.value = 'فشل تحديث المنتج: $e';
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _databaseService.softDeleteProduct(productId);
      return true;
    } catch (e) {
      errorMessage.value = 'فشل حذف المنتج: $e';
      return false;
    }
  }

  // ---- Invoice Methods ----
  Future<List<InvoiceModel>> getInvoices() async {
    if (currentStore.value == null) return [];
    try {
      return await _databaseService.getInvoices(currentStore.value!.id);
    } catch (e) {
      errorMessage.value = 'فشل جلب الفواتير: $e';
      return [];
    }
  }

  Future<bool> addInvoice(InvoiceModel invoice) async {
    try {
      await _databaseService.addInvoice(invoice);
      return true;
    } catch (e) {
      errorMessage.value = 'فشل إضافة الفاتورة: $e';
      return false;
    }
  }

  Future<bool> requestInvoiceDeletion(String invoiceId, String reason) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        errorMessage.value = 'يجب تسجيل الدخول';
        return false;
      }
      
      final request = DeletionRequestModel(
        id: Utils.generateId(),
        storeId: currentStore.value!.id,
        documentId: invoiceId,
        documentType: 'invoice',
        requestedBy: user.uid,
        requestedAt: DateTime.now(),
        reason: reason,
      );
      
      await _databaseService.addDeletionRequest(request);
      successMessage.value = 'تم إرسال طلب الحذف للموافقة';
      return true;
    } catch (e) {
      errorMessage.value = 'فشل طلب الحذف: $e';
      return false;
    }
  }

  // ---- Daily Report ----
  Future<DailyReportModel?> getDailyReport(DateTime date) async {
    if (currentStore.value == null) return null;
    try {
      // Check if report exists
      final existing = await _databaseService.getDailyReport(currentStore.value!.id, date);
      if (existing != null) return existing;
      
      // Generate new report
      final report = await _invoiceRepository.generateDailyReport(currentStore.value!.id, date);
      await _databaseService.saveDailyReport(report);
      return report;
    } catch (e) {
      errorMessage.value = 'فشل جلب التقرير: $e';
      return null;
    }
  }

  // ---- Employees ----
  Future<List<UserModel>> getEmployees() async {
    if (currentStore.value == null) return [];
    try {
      return await _databaseService.getEmployees(currentStore.value!.id);
    } catch (e) {
      errorMessage.value = 'فشل جلب الموظفين: $e';
      return [];
    }
  }

  Future<bool> addEmployee(String email) async {
    try {
      // Find user by email
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isEmpty) {
        errorMessage.value = 'المستخدم غير موجود';
        return false;
      }
      
      final user = UserModel.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      await _databaseService.addEmployee(currentStore.value!.id, user.id);
      await _authService.updateUserStore(user.id, currentStore.value!.id);
      
      successMessage.value = 'تم إضافة الموظف بنجاح';
      return true;
    } catch (e) {
      errorMessage.value = 'فشل إضافة الموظف: $e';
      return false;
    }
  }

  Future<bool> removeEmployee(String userId) async {
    try {
      await _databaseService.removeEmployee(userId);
      await _authService.updateUserStore(userId, null);
      successMessage.value = 'تم إزالة الموظف بنجاح';
      return true;
    } catch (e) {
      errorMessage.value = 'فشل إزالة الموظف: $e';
      return false;
    }
  }

  // ---- Deletion Requests ----
  Future<List<DeletionRequestModel>> getDeletionRequests() async {
    if (currentStore.value == null) return [];
    try {
      return await _databaseService.getDeletionRequests(currentStore.value!.id);
    } catch (e) {
      errorMessage.value = 'فشل جلب طلبات الحذف: $e';
      return [];
    }
  }

  Future<bool> approveDeletionRequest(String requestId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        errorMessage.value = 'يجب تسجيل الدخول';
        return false;
      }
      
      await _databaseService.approveDeletionRequest(requestId, user.uid);
      successMessage.value = 'تمت الموافقة على الحذف';
      return true;
    } catch (e) {
      errorMessage.value = 'فشل الموافقة: $e';
      return false;
    }
  }

  Future<bool> rejectDeletionRequest(String requestId) async {
    try {
      await _databaseService.rejectDeletionRequest(requestId);
      successMessage.value = 'تم رفض طلب الحذف';
      return true;
    } catch (e) {
      errorMessage.value = 'فشل الرفض: $e';
      return false;
    }
  }

  // ---- Helper Methods ----
  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  bool get isAdmin => currentUser.value?.isAdmin ?? false;
  bool get isEmployee => currentUser.value?.isEmployee ?? false;
}

// ============================================================
// PART 5: main() + MyApp
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize GetX controller
  Get.put(AppController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/signup', page: () => const SignUpPage()),
        GetPage(name: '/link-store', page: () => const LinkStorePage()),
        GetPage(name: '/products', page: () => const ProductsPage()),
        GetPage(name: '/new-invoice', page: () => const NewInvoicePage()),
        GetPage(name: '/invoices', page: () => const InvoicesPage()),
        GetPage(name: '/daily-report', page: () => const DailyReportPage()),
        GetPage(name: '/settings', page: () => const SettingsPage()),
        GetPage(name: '/employees', page: () => const EmployeesPage()),
        GetPage(name: '/pending-deletions', page: () => const PendingDeletionsPage()),
        GetPage(name: '/payment', page: () => const PaymentPage()),
      ],
      unknownRoute: GetPage(name: '/notfound', page: () => const Scaffold(body: Center(child: Text('الصفحة غير موجودة')))),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    
    return Obx(() {
      if (controller.currentUser.value == null) {
        return const LoginPage();
      }
      if (!controller.isStoreLinked.value) {
        return const LinkStorePage();
      }
      return const HomePage();
    });
  }
}

// ============================================================
// PART 6: LoginPage + SignUpPage + LinkStorePage (كلها ميزات جديدة/معدّلة)
// ============================================================

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'متجر الموبايلات',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.errorMessage.value.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                
                if (email.isEmpty || password.isEmpty) {
                  controller.errorMessage.value = 'يرجى ملء جميع الحقول';
                  return;
                }
                
                final success = await controller.signIn(email, password);
                if (success) {
                  Get.offAllNamed('/');
                }
              },
              child: controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : const Text('تسجيل الدخول'),
            )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.toNamed('/signup'),
              child: const Text('ليس لديك حساب؟ سجل الآن'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'إنشاء حساب جديد',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.errorMessage.value.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                
                if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  controller.errorMessage.value = 'يرجى ملء جميع الحقول';
                  return;
                }
                
                if (password != confirmPassword) {
                  controller.errorMessage.value = 'كلمات المرور غير متطابقة';
                  return;
                }
                
                if (!Utils.isEmailValid(email)) {
                  controller.errorMessage.value = 'البريد الإلكتروني غير صحيح';
                  return;
                }
                
                final success = await controller.signUp(email, password, name);
                if (success) {
                  Get.offAllNamed('/');
                }
              },
              child: controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : const Text('إنشاء حساب'),
            )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.toNamed('/login'),
              child: const Text('لديك حساب؟ سجل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

class LinkStorePage extends StatelessWidget {
  const LinkStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final storeNameController = TextEditingController();
    final storeIdController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    
    return Scaffold(
      appBar: AppBar(title: const Text('ربط المتجر')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ربط متجر موجود أو إنشاء جديد',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'الخيار 1: ربط متجر موجود',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: storeIdController,
                decoration: const InputDecoration(
                  labelText: 'رقم المتجر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () async {
                  final storeId = storeIdController.text.trim();
                  if (storeId.isEmpty) {
                    controller.errorMessage.value = 'يرجى إدخال رقم المتجر';
                    return;
                  }
                  await controller.linkToExistingStore(storeId);
                  if (controller.errorMessage.value.isEmpty) {
                    Get.offAllNamed('/');
                  }
                },
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text('ربط المتجر'),
              )),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                'الخيار 2: إنشاء متجر جديد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: storeNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المتجر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '05xxxxxxxx',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () async {
                  final name = storeNameController.text.trim();
                  if (name.isEmpty) {
                    controller.errorMessage.value = 'يرجى إدخال اسم المتجر';
                    return;
                  }
                  
                  final address = addressController.text.trim().isEmpty ? null : addressController.text.trim();
                  final phone = phoneController.text.trim().isEmpty ? null : phoneController.text.trim();
                  
                  if (phone != null && !Utils.isPhoneValid(phone)) {
                    controller.errorMessage.value = 'رقم الهاتف غير صحيح (يجب أن يبدأ بـ 05)';
                    return;
                  }
                  
                  await controller.createAndLinkStore(name, address: address, phone: phone);
                  if (controller.errorMessage.value.isEmpty) {
                    Get.offAllNamed('/');
                  }
                },
                child: controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text('إنشاء وربط المتجر'),
              )),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  );
                }
                if (controller.successMessage.value.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.successMessage.value,
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PART 7: HomePage (مع إصلاح عداد المنتجات لأداء ممتاز مع أي كمية بيانات)
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.signOut(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.currentStore.value == null) {
          return const Center(child: Text('لم يتم ربط متجر بعد'));
        }
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، ${controller.currentUser.value?.displayName ?? 'مستخدم'}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المتجر: ${controller.currentStore.value?.name ?? 'غير محدد'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'الدور: ${controller.currentUser.value?.isAdmin ?? false ? 'مدير' : 'موظف'}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'المنتجات',
                        '0', // ستحدث بشكل ديناميكي
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'الفواتير',
                        '0',
                        Icons.receipt,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'الموظفين',
                        '0',
                        Icons.people,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'الإيرادات',
                        '0 ر.س',
                        Icons.monetization_on,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                const Text(
                  'الإجراءات السريعة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionButton(
                      'المنتجات',
                      Icons.inventory,
                      () => Get.toNamed('/products'),
                    ),
                    _buildActionButton(
                      'فاتورة جديدة',
                      Icons.add_shopping_cart,
                      () => Get.toNamed('/new-invoice'),
                    ),
                    _buildActionButton(
                      'الفواتير',
                      Icons.receipt_long,
                      () => Get.toNamed('/invoices'),
                    ),
                    _buildActionButton(
                      'التقرير اليومي',
                      Icons.bar_chart,
                      () => Get.toNamed('/daily-report'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Recent invoices (limited to 5 for performance)
                const Text(
                  'آخر الفواتير',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<InvoiceModel>>(
                  future: controller.getInvoices(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('خطأ: ${snapshot.error}'));
                    }
                    
                    final invoices = snapshot.data ?? [];
                    final recent = invoices.take(5).toList();
                    
                    if (recent.isEmpty) {
                      return const Center(child: Text('لا توجد فواتير'));
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      itemBuilder: (context, index) {
                        final invoice = recent[index];
                        return Card(
                          child: ListTile(
                            title: Text('فاتورة #${invoice.id.substring(0, 8)}'),
                            subtitle: Text(invoice.customerName),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  Utils.formatCurrency(invoice.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  Utils.formatDateShort(invoice.date),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              // يمكن إضافة صفحة عرض الفاتورة هنا
                              Get.snackbar('الفاتورة', 'تفاصيل الفاتورة قيد التطوير');
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 48),
      ),
    );
  }
}

// ============================================================
// PART 8: SettingsPage (موسّعة) + EmployeesPage + PendingDeletionsPage — كلها ميزات جديدة
// ============================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Obx(() {
        if (controller.currentStore.value == null) {
          return const Center(child: Text('لم يتم ربط متجر بعد'));
        }
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معلومات المتجر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('اسم المتجر', controller.currentStore.value!.name),
                        if (controller.currentStore.value!.address != null)
                          _buildInfoRow('العنوان', controller.currentStore.value!.address!),
                        if (controller.currentStore.value!.phone != null)
                          _buildInfoRow('رقم الهاتف', controller.currentStore.value!.phone!),
                        _buildInfoRow('رقم المتجر', controller.currentStore.value!.id),
                        _buildInfoRow('تاريخ الإنشاء', Utils.formatDate(controller.currentStore.value!.createdAt)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'إدارة المتجر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('الموظفين'),
                        subtitle: const Text('إدارة الموظفين والصلاحيات'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed('/employees'),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.delete_sweep),
                        title: const Text('طلبات الحذف'),
                        subtitle: const Text('الموافقة على طلبات حذف الفواتير'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed('/pending-deletions'),
                      ),
                      if (controller.isAdmin) ...[
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.store),
                          title: const Text('تعديل المتجر'),
                          subtitle: const Text('تحديث معلومات المتجر'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _showEditStoreDialog(context, controller),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'معلومات التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('الإصدار', kAppVersion),
                        _buildInfoRow('اسم التطبيق', kAppName),
                        const SizedBox(height: 8),
                        const Text(
                          'ملاحظة: الفواتير المحذوفة تتطلب موافقة المدير',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showEditStoreDialog(BuildContext context, AppController controller) {
    final nameController = TextEditingController(text: controller.currentStore.value?.name);
    final addressController = TextEditingController(text: controller.currentStore.value?.address);
    final phoneController = TextEditingController(text: controller.currentStore.value?.phone);
    
    Get.dialog(
      AlertDialog(
        title: const Text('تعديل المتجر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المتجر',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = <String, dynamic>{};
              if (nameController.text.trim().isNotEmpty) {
                data['name'] = nameController.text.trim();
              }
              if (addressController.text.trim().isNotEmpty) {
                data['address'] = addressController.text.trim();
              }
              if (phoneController.text.trim().isNotEmpty) {
                data['phone'] = phoneController.text.trim();
              }
              
              if (data.isNotEmpty) {
                final success = await controller.updateProduct(
                  controller.currentStore.value!.id,
                  data,
                );
                if (success) {
                  Get.back();
                  Get.snackbar('نجاح', 'تم تحديث المتجر بنجاح');
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    final emailController = TextEditingController();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموظفين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEmployeeDialog(context, controller, emailController),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return FutureBuilder<List<UserModel>>(
          future: controller.getEmployees(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            }
            
            final employees = snapshot.data ?? [];
            
            if (employees.isEmpty) {
              return const Center(child: Text('لا يوجد موظفون'));
            }
            
            return ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(employee.displayName?[0] ?? '?'),
                    ),
                    title: Text(employee.displayName ?? 'غير معروف'),
                    subtitle: Text(employee.email),
                    trailing: employee.id != controller.currentUser.value?.id
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showRemoveEmployeeDialog(context, controller, employee),
                          )
                        : const Text('أنت', style: TextStyle(color: Colors.green)),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }

  void _showAddEmployeeDialog(BuildContext context, AppController controller, TextEditingController emailController) {
    emailController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('إضافة موظف'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني للموظف',
            border: OutlineInputBorder(),
            hintText: 'employee@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                Get.snackbar('خطأ', 'يرجى إدخال البريد الإلكتروني');
                return;
              }
              
              final success = await controller.addEmployee(email);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تم إضافة الموظف بنجاح');
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showRemoveEmployeeDialog(BuildContext context, AppController controller, UserModel employee) {
    Get.dialog(
      AlertDialog(
        title: const Text('إزالة موظف'),
        content: Text('هل أنت متأكد من إزالة "${employee.displayName}" من الموظفين؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await controller.removeEmployee(employee.id);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تم إزالة الموظف بنجاح');
              }
            },
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }
}

class PendingDeletionsPage extends StatelessWidget {
  const PendingDeletionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الحذف المعلقة'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return FutureBuilder<List<DeletionRequestModel>>(
          future: controller.getDeletionRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            }
            
            final requests = snapshot.data ?? [];
            
            if (requests.isEmpty) {
              return const Center(child: Text('لا توجد طلبات حذف معلقة'));
            }
            
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      request.documentType == 'invoice' ? Icons.receipt : Icons.inventory,
                    ),
                    title: Text('طلب حذف ${request.documentType == 'invoice' ? 'فاتورة' : 'منتج'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السبب: ${request.reason}'),
                        Text('التاريخ: ${Utils.formatDate(request.requestedAt)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _showApproveDialog(context, controller, request),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _showRejectDialog(context, controller, request),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }

  void _showApproveDialog(BuildContext context, AppController controller, DeletionRequestModel request) {
    Get.dialog(
      AlertDialog(
        title: const Text('الموافقة على الحذف'),
        content: Text('هل أنت متأكد من الموافقة على حذف هذا ${request.documentType == 'invoice' ? 'الفاتورة' : 'المنتج'}؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final success = await controller.approveDeletionRequest(request.id);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تمت الموافقة على الحذف');
              }
            },
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AppController controller, DeletionRequestModel request) {
    Get.dialog(
      AlertDialog(
        title: const Text('رفض طلب الحذف'),
        content: Text('هل أنت متأكد من رفض طلب حذف هذا ${request.documentType == 'invoice' ? 'الفاتورة' : 'المنتج'}؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await controller.rejectDeletionRequest(request.id);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تم رفض طلب الحذف');
              }
            },
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PART 9: ProductsPage (تستخدم softDeleteProduct الجديدة)
// ============================================================

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final controller = Get.find<AppController>();
  final searchController = TextEditingController();
  List<ProductModel> products = [];
  List<ProductModel> filteredProducts = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
        _filterProducts();
      });
    });
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    products = await controller.getProducts();
    filteredProducts = List.from(products);
    setState(() => isLoading = false);
  }

  void _filterProducts() {
    if (searchQuery.isEmpty) {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((product) {
        return product.name.toLowerCase().contains(searchQuery) ||
               (product.description?.toLowerCase() ?? '').contains(searchQuery);
      }).toList();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'بحث عن منتج...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? const Center(child: Text('لا توجد منتجات'))
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            child: ListTile(
                              leading: product.imageUrl != null
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported);
                                      },
                                    )
                                  : const Icon(Icons.inventory, size: 40),
                              title: Text(product.name),
                              subtitle: Text(product.description ?? ''),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Utils.formatCurrency(product.price),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'الكمية: ${product.quantity}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () => _showEditProductDialog(context, product),
                              onLongPress: () => _showDeleteProductDialog(context, product),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final imageUrlController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('إضافة منتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'رابط الصورة (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = num.tryParse(priceController.text.trim());
              final quantity = int.tryParse(quantityController.text.trim());
              
              if (name.isEmpty || price == null || quantity == null) {
                Get.snackbar('خطأ', 'يرجى ملء جميع الحقول المطلوبة');
                return;
              }
              
              final product = ProductModel(
                id: Utils.generateId(),
                name: name,
                description: descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
                price: price,
                quantity: quantity,
                imageUrl: imageUrlController.text.trim().isNotEmpty
                    ? imageUrlController.text.trim()
                    : null,
                storeId: controller.currentStore.value!.id,
                createdAt: DateTime.now(),
              );
              
              final success = await controller.addProduct(product);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تم إضافة المنتج بنجاح');
                _loadProducts();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final quantityController = TextEditingController(text: product.quantity.toString());
    final imageUrlController = TextEditingController(text: product.imageUrl);
    
    Get.dialog(
      AlertDialog(
        title: const Text('تعديل المنتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'رابط الصورة (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = num.tryParse(priceController.text.trim());
              final quantity = int.tryParse(quantityController.text.trim());
              
              if (name.isEmpty || price == null || quantity == null) {
                Get.snackbar('خطأ', 'يرجى ملء جميع الحقول المطلوبة');
                return;
              }
              
              final data = {
                'name': name,
                'description': descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
                'price': price,
                'quantity': quantity,
                'imageUrl': imageUrlController.text.trim().isNotEmpty
                    ? imageUrlController.text.trim()
                    : null,
                'updatedAt': Timestamp.now(),
              };
              
              final success = await controller.updateProduct(product.id, data);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تم تحديث المنتج بنجاح');
                _loadProducts();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, ProductModel product) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await controller.deleteProduct(product.id);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تم حذف المنتج بنجاح');
                _loadProducts();
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PART 10: NewInvoicePage (بلا تغيير جوهري)
// ============================================================

class NewInvoicePage extends StatefulWidget {
  const NewInvoicePage({super.key});

  @override
  State<NewInvoicePage> createState() => _NewInvoicePageState();
}

class _NewInvoicePageState extends State<NewInvoicePage> {
  final controller = Get.find<AppController>();
  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final notesController = TextEditingController();
  
  List<ProductModel> products = [];
  List<InvoiceItem> items = [];
  String paymentMethod = 'cash';
  num discount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    products = await controller.getProducts();
    setState(() => isLoading = false);
  }

  void _addProductToInvoice(ProductModel product) {
    final existingItem = items.firstWhereOrNull(
      (item) => item.productId == product.id,
    );
    
    if (existingItem != null) {
      setState(() {
        existingItem.quantity++;
        existingItem.totalPrice = existingItem.unitPrice * existingItem.quantity;
      });
    } else {
      setState(() {
        items.add(InvoiceItem(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitPrice: product.price,
          totalPrice: product.price,
        ));
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int quantity) {
    setState(() {
      items[index].quantity = quantity;
      items[index].totalPrice = items[index].unitPrice * quantity;
    });
  }

  num get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  num get total => subtotal - discount;
  num get remaining => total; // للدفع الكامل

  Future<void> _saveInvoice() async {
    final customerName = customerNameController.text.trim();
    if (customerName.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال اسم العميل');
      return;
    }
    
    if (items.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إضافة منتجات للفاتورة');
      return;
    }
    
    final invoice = InvoiceModel(
      id: Utils.generateId(),
      storeId: controller.currentStore.value!.id,
      customerName: customerName,
      customerPhone: customerPhoneController.text.trim().isNotEmpty
          ? customerPhoneController.text.trim()
          : null,
      items: items,
      subtotal: subtotal,
      discount: discount,
      total: total,
      paidAmount: total, // الدفع كامل
      remainingAmount: 0,
      paymentMethod: paymentMethod,
      date: DateTime.now(),
      notes: notesController.text.trim().isNotEmpty
          ? notesController.text.trim()
          : null,
      createdBy: controller.currentUser.value!.id,
      createdAt: DateTime.now(),
    );
    
    final success = await controller.addInvoice(invoice);
    if (success) {
      // تحديث الكميات
      for (final item in items) {
        final product = products.firstWhereOrNull((p) => p.id == item.productId);
        if (product != null) {
          final newQuantity = product.quantity - item.quantity;
          await controller.updateProduct(product.id, {
            'quantity': newQuantity,
            'updatedAt': Timestamp.now(),
          });
        }
      }
      
      Get.snackbar('نجاح', 'تم إنشاء الفاتورة بنجاح');
      Get.back();
    }
  }

  @override
  void dispose() {
    customerNameController.dispose();
    customerPhoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveInvoice,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('معلومات العميل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم العميل',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('المنتجات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ProductModel>(
                      decoration: const InputDecoration(
                        labelText: 'إضافة منتج',
                        border: OutlineInputBorder(),
                      ),
                      items: products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text('${product.name} - ${Utils.formatCurrency(product.price)}'),
                        );
                      }).toList(),
                      onChanged: (product) {
                        if (product != null && product.quantity > 0) {
                          _addProductToInvoice(product);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Items list
                    if (items.isNotEmpty) ...[
                      const Text('المنتجات المضافة:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...List.generate(items.length, (index) {
                        final item = items[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.productName),
                            subtitle: Text('السعر: ${Utils.formatCurrency(item.unitPrice)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      _updateItemQuantity(index, item.quantity - 1);
                                    } else {
                                      _removeItem(index);
                                    }
                                  },
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _updateItemQuantity(index, item.quantity + 1),
                                ),
                                Text(Utils.formatCurrency(item.totalPrice)),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    
                    const Text('الملخص', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildSummaryRow('المجموع الفرعي', Utils.formatCurrency(subtotal)),
                    _buildSummaryRow('الخصم', Utils.formatCurrency(discount)),
                    _buildSummaryRow('الإجمالي', Utils.formatCurrency(total), isTotal: true),
                    
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ============================================================
// PART 11: PaymentPage — الإصلاح الرئيسي (كانت StatelessWidget مع خلل تحديث، الآن StatefulWidget يتحدث لحظيًا فورًا)
// ============================================================

class PaymentPage extends StatefulWidget {
  final InvoiceModel? invoice;
  final num? amount;
  
  const PaymentPage({super.key, this.invoice, this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final controller = Get.find<AppController>();
  final amountController = TextEditingController();
  final paymentMethodController = TextEditingController();
  
  num paidAmount = 0;
  num remainingAmount = 0;
  String selectedPaymentMethod = 'cash';
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  void _initializePayment() {
    if (widget.invoice != null) {
      paidAmount = widget.invoice!.paidAmount;
      remainingAmount = widget.invoice!.remainingAmount;
      selectedPaymentMethod = widget.invoice!.paymentMethod;
      amountController.text = remainingAmount.toString();
    } else if (widget.amount != null) {
      remainingAmount = widget.amount!;
      amountController.text = widget.amount!.toString();
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    paymentMethodController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (isProcessing) return;
    
    final amount = num.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar('خطأ', 'يرجى إدخال مبلغ صحيح');
      return;
    }
    
    if (amount > remainingAmount) {
      Get.snackbar('خطأ', 'المبلغ المدفوع أكبر من المتبقي');
      return;
    }
    
    setState(() => isProcessing = true);
    
    try {
      if (widget.invoice != null) {
        // تحديث الفاتورة الحالية
        final newPaidAmount = paidAmount + amount;
        final newRemainingAmount = remainingAmount - amount;
        
        await controller.updateProduct(widget.invoice!.id, {
          'paidAmount': newPaidAmount,
          'remainingAmount': newRemainingAmount,
          'paymentMethod': selectedPaymentMethod,
        });
        
        Get.snackbar('نجاح', 'تم تسجيل الدفع بنجاح');
        Get.back();
      } else {
        // دفعة جديدة أو دفعة جزئية لفواتير متعددة
        Get.snackbar('نجاح', 'تم تسجيل الدفع بمبلغ ${Utils.formatCurrency(amount)}');
        Get.back(result: {'amount': amount, 'method': selectedPaymentMethod});
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل عملية الدفع: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدفع'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (widget.invoice != null) ...[
                        _buildSummaryRow('العميل', widget.invoice!.customerName),
                        _buildSummaryRow('رقم الفاتورة', '#${widget.invoice!.id.substring(0, 8)}'),
                        const Divider(),
                      ],
                      _buildSummaryRow('المبلغ المتبقي', Utils.formatCurrency(remainingAmount)),
                      if (widget.invoice != null)
                        _buildSummaryRow('المبلغ المدفوع سابقاً', Utils.formatCurrency(paidAmount)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Payment form
              const Text('تفاصيل الدفع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'طريقة الدفع',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('نقداً')),
                  DropdownMenuItem(value: 'card', child: Text('بطاقة ائتمان')),
                  DropdownMenuItem(value: 'bank', child: Text('تحويل بنكي')),
                  DropdownMenuItem(value: 'credit', child: Text('أجل')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value ?? 'cash';
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: isProcessing
                          ? const CircularProgressIndicator()
                          : const Text('تسجيل الدفع'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================
// PART 12: InvoicesPage + DailyReportPage (بلا تغيير جوهري بالواجهة، تستفيد من الإصلاحات بالخلفية)
// ============================================================

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final controller = Get.find<AppController>();
  final searchController = TextEditingController();
  List<InvoiceModel> invoices = [];
  List<InvoiceModel> filteredInvoices = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
        _filterInvoices();
      });
    });
  }

  Future<void> _loadInvoices() async {
    setState(() => isLoading = true);
    invoices = await controller.getInvoices();
    filteredInvoices = List.from(invoices);
    setState(() => isLoading = false);
  }

  void _filterInvoices() {
    if (searchQuery.isEmpty) {
      filteredInvoices = List.from(invoices);
    } else {
      filteredInvoices = invoices.where((invoice) {
        return invoice.customerName.toLowerCase().contains(searchQuery) ||
               invoice.id.toLowerCase().contains(searchQuery);
      }).toList();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed('/new-invoice'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'بحث عن فاتورة...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInvoices.isEmpty
                    ? const Center(child: Text('لا توجد فواتير'))
                    : ListView.builder(
                        itemCount: filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                          return Card(
                            child: ListTile(
                              title: Text('فاتورة #${invoice.id.substring(0, 8)}'),
                              subtitle: Text('العميل: ${invoice.customerName}'),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Utils.formatCurrency(invoice.total),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    Utils.formatDateShort(invoice.date),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () => _showInvoiceDetailsDialog(context, invoice),
                              onLongPress: () => _showDeleteInvoiceDialog(context, invoice),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetailsDialog(BuildContext context, InvoiceModel invoice) {
    Get.dialog(
      AlertDialog(
        title: const Text('تفاصيل الفاتورة'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('رقم الفاتورة', '#${invoice.id.substring(0, 8)}'),
              _buildDetailRow('العميل', invoice.customerName),
              if (invoice.customerPhone != null)
                _buildDetailRow('رقم الهاتف', invoice.customerPhone!),
              _buildDetailRow('التاريخ', Utils.formatDate(invoice.date)),
              _buildDetailRow('طريقة الدفع', _getPaymentMethodName(invoice.paymentMethod)),
              const Divider(),
              const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.productName} x${item.quantity}'),
                      Text(Utils.formatCurrency(item.totalPrice)),
                    ],
                  ),
                );
              }),
              const Divider(),
              _buildDetailRow('المجموع الفرعي', Utils.formatCurrency(invoice.subtotal)),
              _buildDetailRow('الخصم', Utils.formatCurrency(invoice.discount)),
              _buildDetailRow('الإجمالي', Utils.formatCurrency(invoice.total), isBold: true),
              _buildDetailRow('المدفوع', Utils.formatCurrency(invoice.paidAmount)),
              _buildDetailRow('المتبقي', Utils.formatCurrency(invoice.remainingAmount)),
              if (invoice.notes != null) ...[
                const Divider(),
                _buildDetailRow('ملاحظات', invoice.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
          if (invoice.remainingAmount > 0)
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/payment', arguments: {'invoice': invoice});
              },
              child: const Text('تسجيل دفعة'),
            ),
        ],
      ),
    );
  }

  void _showDeleteInvoiceDialog(BuildContext context, InvoiceModel invoice) {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('طلب حذف الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من طلب حذف هذه الفاتورة؟ ستحتاج إلى موافقة المدير.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الحذف',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                Get.snackbar('خطأ', 'يرجى إدخال سبب الحذف');
                return;
              }
              
              final success = await controller.requestInvoiceDeletion(invoice.id, reason);
              if (success) {
                Get.back();
                Get.snackbar('نجاح', 'تم إرسال طلب الحذف للموافقة');
              }
            },
            child: const Text('إرسال طلب الحذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash': return 'نقداً';
      case 'card': return 'بطاقة ائتمان';
      case 'bank': return 'تحويل بنكي';
      case 'credit': return 'أجل';
      default: return method;
    }
  }
}

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({super.key});

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  final controller = Get.find<AppController>();
  DateTime selectedDate = DateTime.now();
  DailyReportModel? report;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);
    report = await controller.getDailyReport(selectedDate);
    setState(() => isLoading = false);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقرير اليومي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لا توجد بيانات لهذا اليوم'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('تحديد تاريخ آخر'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'التقرير اليومي',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  Utils.formatDateShort(report!.date),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'عدد الفواتير',
                                '${report!.totalInvoices}',
                                Icons.receipt,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'الإيرادات',
                                Utils.formatCurrency(report!.totalRevenue),
                                Icons.monetization_on,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'الخصم',
                                Utils.formatCurrency(report!.totalDiscount),
                                Icons.discount,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'العمليات',
                                '${report!.totalInvoices}',
                                Icons.shopping_cart,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Payment methods breakdown
                        const Text('تفصيل طرق الدفع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildPaymentRow('نقداً', report!.totalCash),
                                _buildPaymentRow('بطاقة ائتمان', report!.totalCard),
                                _buildPaymentRow('تحويل بنكي', report!.totalBank),
                                _buildPaymentRow('أجل', report!.totalCredit),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Top products
                        const Text('أكثر المنتجات مبيعاً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: report!.topProducts.isEmpty
                                ? const Center(child: Text('لا توجد منتجات مباعة'))
                                : Column(
                                    children: report!.topProducts.entries.take(10).map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(entry.key),
                                            Text('${entry.value} قطعة'),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, num amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(Utils.formatCurrency(amount)),
        ],
      ),
    );
  }
}

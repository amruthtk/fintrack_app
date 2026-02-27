import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/transaction.dart' as tx;
import '../models/group.dart';
import '../models/notification_model.dart';

class DashboardData {
  final double totalSpent;
  final double totalIncome;
  final double toPay;
  final double toReceive;

  const DashboardData({
    this.totalSpent = 0,
    this.totalIncome = 0,
    this.toPay = 0,
    this.toReceive = 0,
  });
}

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- UI STATE ---
  bool _loading = true;
  bool get loading => _loading;

  bool _isPrivate = false;
  bool get isPrivate => _isPrivate;
  set isPrivate(bool v) {
    _isPrivate = v;
    _prefs?.setBool('fintrack_is_private', v);
    notifyListeners();
  }

  bool _darkMode = false;
  bool get darkMode => _darkMode;
  set darkMode(bool v) {
    _darkMode = v;
    _prefs?.setBool('fintrack_dark_mode', v);
    notifyListeners();
  }

  // --- USER STATE ---
  AppUser? _user;
  AppUser? get user => _user;

  final List<AppUser> _usersCache = [];
  List<AppUser> get users => _usersCache;

  // --- DATA STATE ---
  DashboardData _dashboardData = const DashboardData();
  DashboardData get dashboardData => _dashboardData;

  List<tx.Transaction> _transactions = [];
  List<tx.Transaction> get transactions => _transactions;

  List<tx.Transaction> _recentActivities = [];
  List<tx.Transaction> get recentActivities => _recentActivities;

  List<Group> _groups = [];
  List<Group> get groups => _groups;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  // --- LOCAL GUEST ---
  List<tx.Transaction> _localTransactions = [];
  List<tx.Transaction> get localTransactions => _localTransactions;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SharedPreferences? _prefs;
  StreamSubscription? _notifSub;

  // ============ INITIALIZATION ============

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _darkMode = _prefs?.getBool('fintrack_dark_mode') ?? false;
    _isPrivate = _prefs?.getBool('fintrack_is_private') ?? false;

    // Restore guest data
    final guestData = _prefs?.getString('fintrack_guest_data');
    if (guestData != null) {
      try {
        final list = jsonDecode(guestData) as List;
        _localTransactions = list
            .map((m) => tx.Transaction.fromMap(m))
            .toList();
      } catch (_) {}
    }

    // Check if Firebase Auth has a persisted user session
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        final userDoc = await _db
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (userDoc.exists) {
          _user = AppUser.fromFirestore(userDoc);
          addUserToCache(_user!);
          await _loadUserData(_user!.id);
        } else {
          // No Firestore profile — sign out
          await _auth.signOut();
          _user = null;
        }
      } catch (e) {
        debugPrint('Auth restore error: $e');
        _user = null;
      }
    } else if (_localTransactions.isNotEmpty) {
      _computeStats(_localTransactions, 'guest');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String userId) async {
    await Future.wait([
      fetchTransactions(userId),
      fetchUserGroups(userId),
      _setupNotificationListener(userId),
    ]);
  }

  // ============ AUTH (Firebase Authentication) ============

  /// Login: look up email from Firestore by phone, then sign in with Firebase Auth
  Future<AppUser?> loginWithPhone(String phone, String password) async {
    // Look up user email from Firestore by phone number
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone.trim())
        .get();
    if (snap.docs.isEmpty) return null;

    final userEmail = snap.docs.first.data()['email'] as String?;
    if (userEmail == null || userEmail.isEmpty) {
      throw Exception('No email linked to this account');
    }

    final userCred = await _auth.signInWithEmailAndPassword(
      email: userEmail,
      password: password,
    );
    final uid = userCred.user!.uid;

    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    final appUser = AppUser.fromFirestore(userDoc);
    await _setUser(appUser);
    return appUser;
  }

  /// Register with real email
  Future<AppUser> register({
    required String displayName,
    required String phone,
    required String email,
    required String password,
    String? username,
    List<Map<String, dynamic>>? initialWallets,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final uid = userCred.user!.uid;

    final userData = {
      'displayName': displayName,
      'name': displayName,
      'phone': phone,
      'email': email.trim().toLowerCase(),
      'username': (username ?? phone).toLowerCase(),
      'isPrivate': false,
      'wallets':
          initialWallets ??
          [
            {
              'id': 'bank',
              'name': 'Bank Account',
              'balance': 0,
              'type': 'bank',
            },
            {
              'id': 'cash',
              'name': 'Physical Cash',
              'balance': 0,
              'type': 'cash',
            },
          ],
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Use the Auth UID as the Firestore document ID
    await _db.collection('users').doc(uid).set(userData);

    final walletsList = (userData['wallets'] as List)
        .map((w) => Wallet.fromMap(w as Map<String, dynamic>))
        .toList();

    final newUser = AppUser(
      id: uid,
      name: displayName,
      phone: phone,
      email: email.trim().toLowerCase(),
      username: (username ?? phone).toLowerCase(),
      wallets: walletsList,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _setUser(newUser);
    return newUser;
  }

  /// Send password reset email by phone number
  Future<String> sendPasswordReset(String phone) async {
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone.trim())
        .get();
    if (snap.docs.isEmpty) throw Exception('No account with this phone number');

    final userEmail = snap.docs.first.data()['email'] as String?;
    if (userEmail == null || userEmail.isEmpty) {
      throw Exception('No email linked to this account');
    }

    await _auth.sendPasswordResetEmail(email: userEmail);
    return userEmail;
  }

  Future<void> _setUser(AppUser u) async {
    _user = u;
    addUserToCache(u);
    await _loadUserData(u.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _notifSub?.cancel();
    await _auth.signOut();
    _user = null;
    _transactions = [];
    _groups = [];
    _notifications = [];
    _dashboardData = const DashboardData();
    _recentActivities = [];
    _prefs?.remove('fintrack_user');
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_user == null) return;
    final uid = _user!.id;
    _notifSub?.cancel();

    try {
      // 1. Delete Auth account FIRST — frees the email for re-registration
      await _auth.currentUser?.delete();

      // 2. Delete Firestore profile
      await _db.collection('users').doc(uid).delete();

      // 3. Delete User's Bills (where they are the creator)
      final billsSnap = await _db
          .collection('bills')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in billsSnap.docs) {
        await doc.reference.delete();
      }

      // 4. Delete Notifications related to the user (sent to them or from them)
      final notifsToSnap = await _db
          .collection('notifications')
          .where('toUserId', isEqualTo: uid)
          .get();
      for (final doc in notifsToSnap.docs) {
        await doc.reference.delete();
      }

      final notifsFromSnap = await _db
          .collection('notifications')
          .where('fromUserId', isEqualTo: uid)
          .get();
      for (final doc in notifsFromSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Delete account data cleanup error: $e');
      // Re-throw to handle "recent login" error in UI
      rethrow;
    }

    _user = null;
    _transactions = [];
    _groups = [];
    _notifications = [];
    _dashboardData = const DashboardData();
    _recentActivities = [];
    _prefs?.remove('fintrack_user');
    notifyListeners();
  }

  // ============ USER CACHE ============

  void addUserToCache(AppUser user) {
    final idx = _usersCache.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _usersCache[idx] = user;
    } else {
      _usersCache.add(user);
    }
  }

  void updateUserInCache(String userId, Map<String, dynamic> updates) {
    final idx = _usersCache.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final old = _usersCache[idx];
      _usersCache[idx] = AppUser(
        id: old.id,
        username: updates['username'] as String? ?? old.username,
        name: updates['displayName'] as String? ?? old.name,
        phone: updates['phone'] as String? ?? old.phone,
        avatarUrl: updates['avatarUrl'] as String? ?? old.avatarUrl,
        avatarColor: updates['avatarColor'] as String? ?? old.avatarColor,
        isPrivate: updates['isPrivate'] as bool? ?? old.isPrivate,
        wallets: old.wallets,
        upiId: updates['upiId'] as String? ?? old.upiId,
        createdAt: old.createdAt,
      );
    }
    if (_user?.id == userId) {
      _user = _user!.copyWith(
        name: updates['displayName'] as String? ?? _user!.name,
        username: updates['username'] as String? ?? _user!.username,
        phone: updates['phone'] as String? ?? _user!.phone,
        avatarUrl: updates['avatarUrl'] as String? ?? _user!.avatarUrl,
        upiId: updates['upiId'] as String? ?? _user!.upiId,
      );
    }
    notifyListeners();
  }

  Future<List<AppUser>> fetchUsersByIds(
    List<String> ids, {
    bool force = false,
  }) async {
    if (ids.isEmpty) return [];

    final uncached = force
        ? ids
        : ids.where((id) => !_usersCache.any((u) => u.id == id)).toList();

    if (uncached.isNotEmpty) {
      // Firestore 'in' limit = 30
      for (var i = 0; i < uncached.length; i += 30) {
        final chunk = uncached.skip(i).take(30).toList();
        final snap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          addUserToCache(AppUser.fromFirestore(doc));
        }
      }
    }

    return ids.map((id) => getCachedUser(id)).whereType<AppUser>().toList();
  }

  AppUser? getCachedUser(String id) {
    try {
      return _usersCache.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // ============ USER SEARCH ============

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    final snap = await _db.collection('users').get();
    final results = snap.docs
        .map((d) => AppUser.fromFirestore(d))
        .where(
          (u) =>
              (u.username.toLowerCase().contains(lower) ||
                  u.name.toLowerCase().contains(lower) ||
                  u.phone.contains(query)) &&
              u.id != _user?.id,
        )
        .toList();
    for (final u in results) {
      addUserToCache(u);
    }
    return results;
  }

  Future<bool> checkPhoneExists(String phone) async {
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ============ GROUPS ============

  Future<void> fetchUserGroups(String userId) async {
    try {
      final snap = await _db
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();
      _groups = snap.docs.map((d) => Group.fromFirestore(d)).toList();

      // Cache group members
      final allMemberIds = _groups.expand((g) => g.memberIds).toSet().toList();
      if (allMemberIds.isNotEmpty) {
        await fetchUsersByIds(allMemberIds);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('fetchUserGroups failed: $e');
    }
  }

  Future<String> createGroup(Map<String, dynamic> data) async {
    final docRef = await _db.collection('groups').add({
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (_user != null) await fetchUserGroups(_user!.id);
    return docRef.id;
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    await _db.collection('groups').doc(groupId).update(updates);
    if (_user != null) await fetchUserGroups(_user!.id);
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  // ============ TRANSACTIONS / BILLS ============

  Future<void> fetchTransactions(String userId) async {
    if (userId == 'guest') {
      _computeStats(_localTransactions, 'guest');
      return;
    }
    try {
      final snap = await _db
          .collection('bills')
          .where('memberIds', arrayContains: userId)
          .get();
      final allTx =
          snap.docs.map((d) => tx.Transaction.fromFirestore(d)).toList()
            ..sort((a, b) {
              if (a.createdAt != null && b.createdAt != null) {
                return b.createdAt!.compareTo(a.createdAt!);
              }
              return '${b.date}T${b.time}'.compareTo('${a.date}T${a.time}');
            });

      // Cache encountered users FIRST (include payerIds too, they may not be in memberIds)
      final allMemberIds = allTx.expand((t) => t.memberIds).toSet();
      for (final t in allTx) {
        if (t.payerId != null && t.payerId!.isNotEmpty) {
          allMemberIds.add(t.payerId!);
        }
      }
      final allIdsToFetch = allMemberIds.toList();
      if (allIdsToFetch.isNotEmpty) {
        await fetchUsersByIds(allIdsToFetch);
      }

      // Now compute stats & notify listeners — users are already cached
      _computeStats(allTx, userId);
    } catch (e) {
      debugPrint('fetchTransactions failed: $e');
    }
  }

  void _computeStats(List<tx.Transaction> txList, String userId) {
    double totalSpent = 0, totalIncome = 0, toPay = 0, toReceive = 0;

    for (final t in txList) {
      final amount = t.amount;
      if (t.type == 'income') {
        totalIncome += amount;
      } else if (t.type == 'expense') {
        totalSpent += amount;
      } else if (t.type == 'split') {
        if (t.payerId == userId) {
          totalSpent += t.payerShare ?? 0;
          final othersOwe = t.members
              .where((m) => m.id != userId && m.status != 'paid')
              .fold<double>(0, (s, m) => s + m.amount);
          toReceive += othersOwe;
        } else {
          final myEntry = t.members.where((m) => m.id == userId).firstOrNull;
          if (myEntry != null) {
            totalSpent += myEntry.amount;
            if (myEntry.status != 'paid') toPay += myEntry.amount;
          }
        }
      }
    }

    _dashboardData = DashboardData(
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      toPay: toPay > 0 ? toPay : 0,
      toReceive: toReceive > 0 ? toReceive : 0,
    );
    _transactions = txList;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    _recentActivities = txList.where((t) => t.date == today).toList();
    notifyListeners();
  }

  Future<String> createBill(Map<String, dynamic> data) async {
    if (_user == null) {
      // Guest mode
      final guestBill = tx.Transaction.fromMap({
        ...data,
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'userId': 'guest',
        'memberIds': ['guest'],
        'isLocal': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _localTransactions.insert(0, guestBill);
      _prefs?.setString(
        'fintrack_guest_data',
        jsonEncode(_localTransactions.map((t) => t.toMap()).toList()),
      );
      _computeStats(_localTransactions, 'guest');
      return guestBill.id;
    }

    final billData = {
      ...data,
      'userId': _user!.id,
      'memberIds':
          data['memberIds'] ??
          (data['members'] != null
              ? (data['members'] as List).map((m) => m['id']).toList()
              : [_user!.id]),
      'createdAt': DateTime.now().toIso8601String(),
    };

    final docRef = await _db.collection('bills').add(billData);

    // Auto-update wallet balance (with insufficient funds check)
    if ((data['type'] == 'expense' || data['type'] == 'income') &&
        data['wallet'] != null &&
        data['isAdjustment'] != true) {
      final targetWallet = _user!.wallets
          .where((w) => w.name == data['wallet'])
          .firstOrNull;
      if (targetWallet != null) {
        final amount = (data['amount'] as num).toDouble();
        if (data['type'] == 'expense' && targetWallet.balance < amount) {
          throw Exception(
            'Insufficient balance in your ${targetWallet.name}. Please reconcile or top-up.',
          );
        }
        final newBalance = data['type'] == 'expense'
            ? targetWallet.balance - amount
            : targetWallet.balance + amount;
        await _updateWalletInFirestore(targetWallet.id, newBalance);
      }
    }

    // Handle split wallet deduction (with insufficient funds check)
    if (data['type'] == 'split' &&
        data['wallet'] != null &&
        data['payerId'] == _user!.id) {
      final targetWallet = _user!.wallets
          .where((w) => w.name == data['wallet'])
          .firstOrNull;
      if (targetWallet != null) {
        final amount = (data['amount'] as num).toDouble();
        if (targetWallet.balance < amount) {
          throw Exception(
            'Insufficient balance in your ${targetWallet.name} for this split. Please reconcile or top-up.',
          );
        }
        final newBalance = targetWallet.balance - amount;
        await _updateWalletInFirestore(targetWallet.id, newBalance);
      }
    }

    // Send notifications for splits
    if (data['type'] == 'split' && data['members'] != null) {
      final members = data['members'] as List;
      for (final m in members) {
        if (m['id'] != data['payerId']) {
          await _db.collection('notifications').add({
            'type': 'split_request',
            'billId': docRef.id,
            'fromUserId': _user!.id,
            'fromUserName': _user!.name,
            'toUserId': m['id'],
            'amount': m['amount'],
            'title': data['title'] ?? 'Split Bill',
            'read': false,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    await fetchTransactions(_user!.id);
    return docRef.id;
  }

  Future<void> deleteTransaction(tx.Transaction transaction) async {
    if (_user == null) {
      _localTransactions.removeWhere((t) => t.id == transaction.id);
      _prefs?.setString(
        'fintrack_guest_data',
        jsonEncode(_localTransactions.map((t) => t.toMap()).toList()),
      );
      _computeStats(_localTransactions, 'guest');
      return;
    }

    // Revert wallet balance
    if ((transaction.type == 'expense' || transaction.type == 'income') &&
        transaction.wallet != null &&
        !transaction.isAdjustment) {
      final targetWallet = _user!.wallets
          .where((w) => w.name == transaction.wallet)
          .firstOrNull;
      if (targetWallet != null) {
        final newBalance = transaction.type == 'expense'
            ? targetWallet.balance + transaction.amount
            : targetWallet.balance - transaction.amount;
        await _updateWalletInFirestore(targetWallet.id, newBalance);
      }
    }

    await _db.collection('bills').doc(transaction.id).delete();
    _transactions.removeWhere((t) => t.id == transaction.id);
    _recentActivities.removeWhere((t) => t.id == transaction.id);
    notifyListeners();
  }

  // ============ WALLET ============

  Future<void> updateWalletBalance(
    String walletId,
    double newBalance, {
    String reason = 'Adjustment',
    bool skipLog = false,
  }) async {
    if (_user == null) return;
    await _updateWalletInFirestore(walletId, newBalance);

    if (!skipLog) {
      final diff =
          newBalance -
          (_user!.wallets.firstWhere((w) => w.id == walletId).balance);
      if (diff != 0) {
        await createBill({
          'title': 'Balance Adjustment ($reason)',
          'amount': diff.abs(),
          'type': diff > 0 ? 'income' : 'expense',
          'category': 'Other',
          'wallet': _user!.wallets.firstWhere((w) => w.id == walletId).name,
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'time': DateTime.now().toIso8601String().substring(11, 19),
          'isAdjustment': true,
        });
      }
    }
  }

  Future<void> _updateWalletInFirestore(
    String walletId,
    double newBalance,
  ) async {
    if (_user == null) return;
    final updatedWallets = _user!.wallets.map((w) {
      if (w.id == walletId) {
        return Wallet(
          id: w.id,
          name: w.name,
          balance: newBalance,
          type: w.type,
        );
      }
      return w;
    }).toList();

    await _db.collection('users').doc(_user!.id).update({
      'wallets': updatedWallets.map((w) => w.toMap()).toList(),
    });
    _user = _user!.copyWith(wallets: updatedWallets);
    _prefs?.setString('fintrack_user', jsonEncode(_user!.toMap()));
    notifyListeners();
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    if (_user == null) return;
    await _db.collection('users').doc(_user!.id).update({
      'wallets': wallets.map((w) => w.toMap()).toList(),
      'wealthCalibrationComplete': true,
    });
    _user = _user!.copyWith(wallets: wallets, wealthCalibrationComplete: true);
    _prefs?.setString('fintrack_user', jsonEncode(_user!.toMap()));
    notifyListeners();
  }

  // ============ SETTLEMENTS ============

  Future<void> requestSettlement(
    String billId,
    String memberId, {
    String paymentMethod = 'other',
    String? walletId,
  }) async {
    if (_user == null) return;
    final billSnap = await _db.collection('bills').doc(billId).get();
    if (!billSnap.exists) return;
    final data = billSnap.data()!;
    final memberEntry = (data['members'] as List?)?.firstWhere(
      (m) => m['id'] == memberId,
      orElse: () => null,
    );
    final amount = (memberEntry?['amount'] ?? 0).toDouble();

    // Deduct from debtor's wallet if a wallet was selected
    if (walletId != null && amount > 0) {
      final targetWallet = _user!.wallets
          .where((w) => w.id == walletId)
          .firstOrNull;
      if (targetWallet != null) {
        if (targetWallet.balance < amount) {
          throw Exception(
            'Insufficient balance in ${targetWallet.name}. Current: ₹${targetWallet.balance.toStringAsFixed(0)}',
          );
        }
        await _updateWalletInFirestore(
          targetWallet.id,
          targetWallet.balance - amount,
        );
      }
    }

    await _db.collection('notifications').add({
      'type': 'settlement_request',
      'billId': billId,
      'fromUserId': _user!.id,
      'fromUserName': _user!.name,
      'toUserId': data['payerId'],
      'memberId': memberId,
      'amount': amount,
      'title': data['title'] ?? 'Split Bill',
      'wallet': data['wallet'],
      'paymentMethod': paymentMethod,
      'read': false,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> approveSettlement(
    String notificationId,
    String billId,
    String memberId,
    double amount,
    String fromUserId,
    String? wallet, {
    String? receivedWalletId,
  }) async {
    if (_user == null) return;

    // Update member status to paid
    final billRef = _db.collection('bills').doc(billId);
    final billSnap = await billRef.get();
    if (billSnap.exists) {
      final data = billSnap.data()!;
      final updatedMembers = (data['members'] as List).map((m) {
        if (m['id'] == memberId) return {...m, 'status': 'paid'};
        return m;
      }).toList();
      await billRef.update({'members': updatedMembers});
    }

    // Add to payer's chosen wallet (or fallback to bill wallet)
    if (amount > 0) {
      if (receivedWalletId != null) {
        // Payer chose a specific wallet to receive into
        final targetWallet = _user!.wallets
            .where((w) => w.id == receivedWalletId)
            .firstOrNull;
        if (targetWallet != null) {
          await _updateWalletInFirestore(
            targetWallet.id,
            targetWallet.balance + amount,
          );
        }
      } else if (wallet != null) {
        // Fallback: use the original bill's wallet name
        final targetWallet = _user!.wallets
            .where((w) => w.name == wallet)
            .firstOrNull;
        if (targetWallet != null) {
          await _updateWalletInFirestore(
            targetWallet.id,
            targetWallet.balance + amount,
          );
        }
      }
    }

    // Update notification
    await _db.collection('notifications').doc(notificationId).update({
      'status': 'approved',
      'read': true,
    });

    // Send confirmation
    await _db.collection('notifications').add({
      'type': 'settlement_approved',
      'billId': billId,
      'fromUserId': _user!.id,
      'fromUserName': _user!.name,
      'toUserId': fromUserId,
      'amount': amount,
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await fetchTransactions(_user!.id);
  }

  Future<void> settleSplit(String billId, String memberId) async {
    if (_user == null) return;
    final billRef = _db.collection('bills').doc(billId);
    final billSnap = await billRef.get();
    if (!billSnap.exists) return;
    final data = billSnap.data()!;

    final settledMember = (data['members'] as List?)?.firstWhere(
      (m) => m['id'] == memberId,
      orElse: () => null,
    );
    final settledAmount = (settledMember?['amount'] ?? 0).toDouble();

    final updatedMembers = (data['members'] as List).map((m) {
      if (m['id'] == memberId) return {...m, 'status': 'paid'};
      return m;
    }).toList();
    await billRef.update({'members': updatedMembers});

    if (data['payerId'] == _user!.id &&
        data['wallet'] != null &&
        settledAmount > 0) {
      final targetWallet = _user!.wallets
          .where((w) => w.name == data['wallet'])
          .firstOrNull;
      if (targetWallet != null) {
        await _updateWalletInFirestore(
          targetWallet.id,
          targetWallet.balance + settledAmount,
        );
      }
    }
    await fetchTransactions(_user!.id);
  }

  // ============ POOLS ============

  Future<String> createPool(Map<String, dynamic> data) async {
    if (_user == null) return '';
    final poolTarget =
        (data['amount'] as num).toDouble() -
        ((data['payerShare'] as num?)?.toDouble() ?? 0);

    final billData = {
      ...data,
      'type': 'split',
      'splitType': 'pool',
      'poolStatus': 'open',
      'poolTarget': poolTarget,
      'poolDeclaredTotal': 0,
      'userId': _user!.id,
      'memberIds': (data['members'] as List).map((m) => m['id']).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    final docRef = await _db.collection('bills').add(billData);

    // Deduct from payer
    if (data['wallet'] != null && data['payerId'] == _user!.id) {
      final targetWallet = _user!.wallets
          .where((w) => w.name == data['wallet'])
          .firstOrNull;
      if (targetWallet != null) {
        await _updateWalletInFirestore(
          targetWallet.id,
          targetWallet.balance - (data['amount'] as num).toDouble(),
        );
      }
    }

    // Pool invite notifications
    for (final m in data['members'] as List) {
      if (m['id'] != data['payerId']) {
        await _db.collection('notifications').add({
          'type': 'pool_invite',
          'billId': docRef.id,
          'fromUserId': _user!.id,
          'fromUserName': _user!.name,
          'toUserId': m['id'],
          'amount': data['amount'],
          'poolTarget': poolTarget,
          'title': data['title'] ?? 'Pool Split',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }

    await fetchTransactions(_user!.id);
    return docRef.id;
  }

  Future<void> declarePoolShare(
    String billId,
    String memberId,
    double declaredAmount,
  ) async {
    if (_user == null) return;
    final billRef = _db.collection('bills').doc(billId);
    final billSnap = await billRef.get();
    if (!billSnap.exists) return;
    final data = billSnap.data()!;

    final updatedMembers = (data['members'] as List).map((m) {
      if (m['id'] == memberId) {
        return {...m, 'amount': declaredAmount, 'status': 'declared'};
      }
      return m;
    }).toList();

    final newDeclaredTotal = updatedMembers
        .where((m) => m['id'] != data['payerId'])
        .fold<double>(0, (s, m) => s + ((m['amount'] ?? 0) as num).toDouble());

    final updates = <String, dynamic>{
      'members': updatedMembers,
      'poolDeclaredTotal': newDeclaredTotal,
    };

    final poolTarget = (data['poolTarget'] ?? 0).toDouble();
    if ((newDeclaredTotal - poolTarget).abs() < 0.01 && poolTarget > 0) {
      updates['poolStatus'] = 'closed';
    }

    await billRef.update(updates);
    await fetchTransactions(_user!.id);
  }

  Future<void> confirmPoolPayment(String billId, String memberId) async {
    if (_user == null) return;
    final billRef = _db.collection('bills').doc(billId);
    final billSnap = await billRef.get();
    if (!billSnap.exists) return;
    final data = billSnap.data()!;

    final updatedMembers = (data['members'] as List).map((m) {
      if (m['id'] == memberId) return {...m, 'status': 'paid'};
      return m;
    }).toList();
    await billRef.update({'members': updatedMembers});

    // Credit wallet
    final confirmedMember = (data['members'] as List).firstWhere(
      (m) => m['id'] == memberId,
      orElse: () => null,
    );
    final confirmedAmount = (confirmedMember?['amount'] ?? 0).toDouble();
    if (data['wallet'] != null && confirmedAmount > 0) {
      final targetWallet = _user!.wallets
          .where((w) => w.name == data['wallet'])
          .firstOrNull;
      if (targetWallet != null) {
        await _updateWalletInFirestore(
          targetWallet.id,
          targetWallet.balance + confirmedAmount,
        );
      }
    }

    await fetchTransactions(_user!.id);
  }

  Future<void> closePool(String billId) async {
    await _db.collection('bills').doc(billId).update({'poolStatus': 'closed'});
    if (_user != null) await fetchTransactions(_user!.id);
  }

  // ============ NOTIFICATIONS ============

  Future<void> _setupNotificationListener(String userId) async {
    _notifSub?.cancel();
    _notifSub = _db
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
          _notifications =
              snap.docs.map((d) => AppNotification.fromFirestore(d)).toList()
                ..sort(
                  (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
                );
          notifyListeners();
        });
  }

  Future<void> markAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'read': true});
  }

  Future<void> deleteNotification(String notifId) async {
    await _db.collection('notifications').doc(notifId).delete();
  }

  Future<void> clearNotifications() async {
    if (_user == null) return;
    final snap = await _db
        .collection('notifications')
        .where('toUserId', isEqualTo: _user!.id)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ============ SYNC ============

  Future<void> syncLocalData() async {
    if (_user == null || _localTransactions.isEmpty) return;
    _isSyncing = true;
    notifyListeners();
    try {
      for (final t in _localTransactions) {
        final map = t.toMap();
        map.remove('id');
        map.remove('isLocal');
        map['userId'] = _user!.id;
        map['memberIds'] = [_user!.id];
        await _db.collection('bills').add(map);
      }
      _localTransactions = [];
      _prefs?.remove('fintrack_guest_data');
      await fetchTransactions(_user!.id);
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ============ PROFILE UPDATES ============

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;
    await _db.collection('users').doc(_user!.id).update(updates);
    updateUserInCache(_user!.id, updates);
  }

  Future<void> updatePassword(String current, String newPassword) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || _user == null) {
      throw Exception('Not logged in');
    }

    // Re-authenticate with current credentials
    final credential = EmailAuthProvider.credential(
      email: firebaseUser.email!,
      password: current,
    );
    await firebaseUser.reauthenticateWithCredential(credential);

    // Update password in Firebase Auth
    await firebaseUser.updatePassword(newPassword);
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }
}

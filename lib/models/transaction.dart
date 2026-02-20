import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionMember {
  final String id;
  final String name;
  final String? username;
  double amount;
  String status; // 'pending', 'paid', 'declared'

  TransactionMember({
    required this.id,
    this.name = '',
    this.username,
    this.amount = 0,
    this.status = 'pending',
  });

  factory TransactionMember.fromMap(Map<String, dynamic> map) {
    return TransactionMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'],
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'username': username,
    'amount': amount,
    'status': status,
  };
}

class Transaction {
  final String id;
  final String type; // 'expense', 'income', 'transfer', 'split'
  final String title;
  final double amount;
  final String date;
  final String time;
  final String category;
  final String? wallet;
  final String? walletType;
  final String? paymentMode;
  final String? payerId;
  final List<String> memberIds;
  final List<TransactionMember> members;
  final String? splitType; // 'equal', 'custom', 'pool'
  final String? poolStatus; // 'open', 'closed'
  final double? poolTarget;
  final double? poolDeclaredTotal;
  final double? payerShare;
  final bool isAdjustment;
  final String? userId;
  final String? createdAt;
  final String? groupId;
  final bool? isLocal;
  final bool? isRecurring;
  final String? frequency;

  Transaction({
    required this.id,
    this.type = 'expense',
    this.title = '',
    this.amount = 0,
    this.date = '',
    this.time = '',
    this.category = 'Other',
    this.wallet,
    this.walletType,
    this.paymentMode,
    this.payerId,
    this.memberIds = const [],
    this.members = const [],
    this.splitType,
    this.poolStatus,
    this.poolTarget,
    this.poolDeclaredTotal,
    this.payerShare,
    this.isAdjustment = false,
    this.userId,
    this.createdAt,
    this.groupId,
    this.isLocal,
    this.isRecurring,
    this.frequency,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Transaction(
      id: doc.id,
      type: data['type'] ?? 'expense',
      title: data['title'] ?? data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date']?.toString() ?? '',
      time: data['time']?.toString() ?? '00:00',
      category: data['category'] ?? 'Other',
      wallet: data['wallet'],
      walletType: data['walletType'],
      paymentMode: data['paymentMode'],
      payerId: data['payerId'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      members: (data['members'] as List<dynamic>?)
              ?.map((m) =>
                  TransactionMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      splitType: data['splitType'],
      poolStatus: data['poolStatus'],
      poolTarget: (data['poolTarget'] ?? 0).toDouble(),
      poolDeclaredTotal: (data['poolDeclaredTotal'] ?? 0).toDouble(),
      payerShare: data['payerShare'] != null
          ? (data['payerShare']).toDouble()
          : null,
      isAdjustment: data['isAdjustment'] ?? false,
      userId: data['userId'],
      createdAt: data['createdAt']?.toString(),
      groupId: data['groupId'],
      isLocal: data['isLocal'],
      isRecurring: data['isRecurring'],
      frequency: data['frequency'],
    );
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      type: map['type'] ?? 'expense',
      title: map['title'] ?? map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '00:00',
      category: map['category'] ?? 'Other',
      wallet: map['wallet'],
      walletType: map['walletType'],
      paymentMode: map['paymentMode'],
      payerId: map['payerId'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      members: (map['members'] as List<dynamic>?)
              ?.map((m) =>
                  TransactionMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      splitType: map['splitType'],
      poolStatus: map['poolStatus'],
      poolTarget: map['poolTarget'] != null
          ? (map['poolTarget']).toDouble()
          : null,
      poolDeclaredTotal: map['poolDeclaredTotal'] != null
          ? (map['poolDeclaredTotal']).toDouble()
          : null,
      payerShare: map['payerShare'] != null
          ? (map['payerShare']).toDouble()
          : null,
      isAdjustment: map['isAdjustment'] ?? false,
      userId: map['userId'],
      createdAt: map['createdAt']?.toString(),
      groupId: map['groupId'],
      isLocal: map['isLocal'],
      isRecurring: map['isRecurring'],
      frequency: map['frequency'],
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'title': title,
    'amount': amount,
    'date': date,
    'time': time,
    'category': category,
    'wallet': wallet,
    'walletType': walletType,
    'paymentMode': paymentMode,
    'payerId': payerId,
    'memberIds': memberIds,
    'members': members.map((m) => m.toMap()).toList(),
    'splitType': splitType,
    'poolStatus': poolStatus,
    'poolTarget': poolTarget,
    'poolDeclaredTotal': poolDeclaredTotal,
    'payerShare': payerShare,
    'isAdjustment': isAdjustment,
    'userId': userId,
    'createdAt': createdAt,
    'groupId': groupId,
    'isRecurring': isRecurring,
    'frequency': frequency,
  };
}

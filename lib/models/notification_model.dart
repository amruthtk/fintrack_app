import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String
  type; // 'settlement_request', 'settlement_approved', 'split_request', 'pool_invite'
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String? billId;
  final String? memberId;
  final double? amount;
  final double? poolTarget;
  final String title;
  final String? status; // 'pending', 'approved', 'rejected'
  final String? wallet;
  final bool read;
  final String? createdAt;

  AppNotification({
    required this.id,
    this.type = 'split_bill',
    this.fromUserId = '',
    this.fromUserName = '',
    this.toUserId = '',
    this.billId,
    this.memberId,
    this.amount,
    this.poolTarget,
    this.title = '',
    this.status,
    this.wallet,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      type: data['type'] ?? 'split_bill',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      toUserId: data['toUserId'] ?? '',
      billId: data['billId'],
      memberId: data['memberId'],
      amount: data['amount'] != null ? (data['amount']).toDouble() : null,
      poolTarget: data['poolTarget'] != null
          ? (data['poolTarget']).toDouble()
          : null,
      title: data['title'] ?? '',
      status: data['status'],
      wallet: data['wallet'],
      read: data['read'] ?? false,
      createdAt: data['createdAt']?.toString(),
    );
  }
}

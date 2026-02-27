import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String name;
  double balance;
  final String type; // 'bank', 'cash', 'credit'

  Wallet({
    required this.id,
    required this.name,
    this.balance = 0,
    this.type = 'bank',
  });

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      type: map['type'] ?? 'bank',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'balance': balance,
    'type': type,
  };
}

/// User model for FinTrack.
/// Authentication (password) is managed by Firebase Auth.
/// No password/pin is stored in the Firestore user document.
class AppUser {
  final String id;
  final String username;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? avatarColor;
  final bool isPrivate;
  final List<Wallet> wallets;
  final String? upiId;
  final String? createdAt;
  final bool? wealthCalibrationComplete;

  AppUser({
    required this.id,
    this.username = '',
    this.name = '',
    this.phone = '',
    this.email,
    this.avatarUrl,
    this.avatarColor,
    this.isPrivate = false,
    this.wallets = const [],
    this.upiId,
    this.createdAt,
    this.wealthCalibrationComplete,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: doc.id,
      username: data['username'] ?? '',
      name: data['displayName'] ?? data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      avatarUrl: data['avatarUrl'],
      avatarColor: data['avatarColor'],
      isPrivate: data['isPrivate'] ?? false,
      wallets:
          (data['wallets'] as List<dynamic>?)
              ?.map((w) => Wallet.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [],
      upiId: data['upiId'],
      createdAt: data['createdAt']?.toString(),
      wealthCalibrationComplete: data['wealthCalibrationComplete'] as bool?,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['displayName'] ?? map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      avatarUrl: map['avatarUrl'],
      avatarColor: map['avatarColor'],
      isPrivate: map['isPrivate'] ?? false,
      wallets:
          (map['wallets'] as List<dynamic>?)
              ?.map((w) => Wallet.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [],
      upiId: map['upiId'],
      createdAt: map['createdAt']?.toString(),
      wealthCalibrationComplete: map['wealthCalibrationComplete'] as bool?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'displayName': name,
    'phone': phone,
    'email': email,
    'avatarUrl': avatarUrl,
    'avatarColor': avatarColor,
    'isPrivate': isPrivate,
    'wallets': wallets.map((w) => w.toMap()).toList(),
    'upiId': upiId,
    'createdAt': createdAt,
    'wealthCalibrationComplete': wealthCalibrationComplete,
  };

  AppUser copyWith({
    String? id,
    String? username,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? avatarColor,
    bool? isPrivate,
    List<Wallet>? wallets,
    String? upiId,
    String? createdAt,
    bool? wealthCalibrationComplete,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
      isPrivate: isPrivate ?? this.isPrivate,
      wallets: wallets ?? this.wallets,
      upiId: upiId ?? this.upiId,
      createdAt: createdAt ?? this.createdAt,
      wealthCalibrationComplete:
          wealthCalibrationComplete ?? this.wealthCalibrationComplete,
    );
  }

  String get initials {
    if (name.isEmpty) return '?';
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .join()
        .toUpperCase()
        .substring(0, name.split(' ').length > 1 ? 2 : 1);
  }

  double get totalBalance => wallets
      .where((w) => w.type != 'credit')
      .fold(0.0, (total, w) => total + w.balance);
}

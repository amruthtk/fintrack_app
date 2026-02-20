import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String emoji;
  final List<String> memberIds;
  final String createdBy;
  final String? coverImage;
  final String? createdAt;

  Group({
    required this.id,
    this.name = '',
    this.emoji = '👥',
    this.memberIds = const [],
    this.createdBy = '',
    this.coverImage,
    this.createdAt,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '👥',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      coverImage: data['coverImage'],
      createdAt: data['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'emoji': emoji,
    'memberIds': memberIds,
    'createdBy': createdBy,
    'coverImage': coverImage,
    'createdAt': createdAt,
  };
}

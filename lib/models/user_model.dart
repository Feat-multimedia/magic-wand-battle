import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? photoURL;
  final bool isAdmin;
  final UserStats stats;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.isAdmin,
    required this.stats,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'],
      isAdmin: data['isAdmin'] ?? false,
      stats: UserStats(
        matchsPlayed: data['stats']?['matchsPlayed'] ?? 0,
        spellsUsed: data['stats']?['spellsUsed'] != null
            ? Map<String, int>.from(data['stats']['spellsUsed'])
            : {},
        totalPoints: (data['stats']?['totalPoints'] ?? 0.0).toDouble(),
        successRate: (data['stats']?['successRate'] ?? 0.0).toDouble(),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'isAdmin': isAdmin,
      'stats': {
        'matchsPlayed': stats.matchsPlayed,
        'spellsUsed': stats.spellsUsed,
        'totalPoints': stats.totalPoints,
        'successRate': stats.successRate,
      },
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    bool? isAdmin,
    UserStats? stats,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserStats {
  final int matchsPlayed;
  final double totalPoints;
  final Map<String, int> spellsUsed;
  final double successRate;

  UserStats({
    required this.matchsPlayed,
    required this.totalPoints,
    required this.spellsUsed,
    required this.successRate,
  });

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      matchsPlayed: data['matchsPlayed'] ?? 0,
      totalPoints: (data['totalPoints'] ?? 0.0).toDouble(),
      spellsUsed: Map<String, int>.from(data['spellsUsed'] ?? {}),
      successRate: (data['successRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchsPlayed': matchsPlayed,
      'totalPoints': totalPoints,
      'spellsUsed': spellsUsed,
      'successRate': successRate,
    };
  }

  UserStats copyWith({
    int? matchsPlayed,
    double? totalPoints,
    Map<String, int>? spellsUsed,
    double? successRate,
  }) {
    return UserStats(
      matchsPlayed: matchsPlayed ?? this.matchsPlayed,
      totalPoints: totalPoints ?? this.totalPoints,
      spellsUsed: spellsUsed ?? this.spellsUsed,
      successRate: successRate ?? this.successRate,
    );
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏆 **Types de tournois disponibles**
enum TournamentType {
  singleElimination, // Élimination directe
  doubleElimination, // Double élimination
  roundRobin,        // Poules (tous contre tous)
  swiss,             // Système suisse
}

/// 📊 **Statuts du tournoi**
enum TournamentStatus {
  draft,        // Brouillon - en création
  registration, // Inscriptions ouvertes
  ready,        // Prêt à commencer
  inProgress,   // En cours
  finished,     // Terminé
  cancelled,    // Annulé
}

/// 🏅 **Types de récompenses**
enum RewardType {
  trophy,    // Trophée
  title,     // Titre
  points,    // Points de ranking
  badge,     // Badge spécial
}

/// 🎁 **Récompense du tournoi**
class TournamentReward {
  final String id;
  final RewardType type;
  final String name;
  final String description;
  final String? iconUrl;
  final int position; // 1er, 2ème, 3ème, etc.
  final Map<String, dynamic>? metadata;

  const TournamentReward({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.position,
    this.metadata,
  });

  factory TournamentReward.fromMap(Map<String, dynamic> map) {
    return TournamentReward(
      id: map['id'] ?? '',
      type: RewardType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => RewardType.trophy,
      ),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'],
      position: map['position'] ?? 1,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'position': position,
      'metadata': metadata,
    };
  }
}

/// 🏆 **Modèle principal du tournoi**
class TournamentModel {
  final String id;
  final String name;
  final String description;
  final TournamentType type;
  final TournamentStatus status;
  
  // 📅 Planning
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  
  // 👥 Participants
  final int maxParticipants;
  final int minParticipants;
  final List<String> registeredPlayerIds;
  final List<String> checkedInPlayerIds;
  
  // 👑 Organisation
  final String organizerId; // Admin qui crée le tournoi
  final List<String> moderatorIds; // Admins qui peuvent gérer
  
  // 🏟️ Configuration
  final String? arenaId; // Arène par défaut
  final List<String>? allowedSpellIds; // Sorts autorisés (null = tous)
  final Map<String, dynamic> rules; // Règles spécifiques
  
  // 🏅 Récompenses
  final List<TournamentReward> rewards;
  
  // 📊 Statistiques
  final Map<String, dynamic> stats;
  final Map<String, dynamic> settings;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    required this.maxParticipants,
    this.minParticipants = 2,
    this.registeredPlayerIds = const [],
    this.checkedInPlayerIds = const [],
    required this.organizerId,
    this.moderatorIds = const [],
    this.arenaId,
    this.allowedSpellIds,
    this.rules = const {},
    this.rewards = const [],
    this.stats = const {},
    this.settings = const {},
  });

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TournamentModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: TournamentType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TournamentType.singleElimination,
      ),
      status: TournamentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TournamentStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startDate: data['startDate'] != null 
        ? (data['startDate'] as Timestamp).toDate() 
        : null,
      endDate: data['endDate'] != null 
        ? (data['endDate'] as Timestamp).toDate() 
        : null,
      registrationDeadline: data['registrationDeadline'] != null 
        ? (data['registrationDeadline'] as Timestamp).toDate() 
        : null,
      maxParticipants: data['maxParticipants'] ?? 8,
      minParticipants: data['minParticipants'] ?? 2,
      registeredPlayerIds: List<String>.from(data['registeredPlayerIds'] ?? []),
      checkedInPlayerIds: List<String>.from(data['checkedInPlayerIds'] ?? []),
      organizerId: data['organizerId'] ?? '',
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      arenaId: data['arenaId'],
      allowedSpellIds: data['allowedSpellIds'] != null 
        ? List<String>.from(data['allowedSpellIds']) 
        : null,
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      rewards: (data['rewards'] as List<dynamic>?)
        ?.map((reward) => TournamentReward.fromMap(reward))
        .toList() ?? [],
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'registrationDeadline': registrationDeadline != null 
        ? Timestamp.fromDate(registrationDeadline!) 
        : null,
      'maxParticipants': maxParticipants,
      'minParticipants': minParticipants,
      'registeredPlayerIds': registeredPlayerIds,
      'checkedInPlayerIds': checkedInPlayerIds,
      'organizerId': organizerId,
      'moderatorIds': moderatorIds,
      'arenaId': arenaId,
      'allowedSpellIds': allowedSpellIds,
      'rules': rules,
      'rewards': rewards.map((reward) => reward.toMap()).toList(),
      'stats': stats,
      'settings': settings,
    };
  }

  /// 🔄 **Méthodes utilitaires**
  
  bool get isRegistrationOpen => status == TournamentStatus.registration;
  bool get canStart => registeredPlayerIds.length >= minParticipants;
  bool get isActive => status == TournamentStatus.inProgress;
  bool get isFinished => status == TournamentStatus.finished;
  
  int get availableSlots => maxParticipants - registeredPlayerIds.length;
  double get registrationProgress => registeredPlayerIds.length / maxParticipants;
  
  bool canRegister(String playerId) {
    return isRegistrationOpen && 
           !registeredPlayerIds.contains(playerId) && 
           availableSlots > 0;
  }
  
  TournamentModel copyWith({
    String? name,
    String? description,
    TournamentType? type,
    TournamentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxParticipants,
    int? minParticipants,
    List<String>? registeredPlayerIds,
    List<String>? checkedInPlayerIds,
    List<String>? moderatorIds,
    String? arenaId,
    List<String>? allowedSpellIds,
    Map<String, dynamic>? rules,
    List<TournamentReward>? rewards,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? settings,
  }) {
    return TournamentModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      minParticipants: minParticipants ?? this.minParticipants,
      registeredPlayerIds: registeredPlayerIds ?? this.registeredPlayerIds,
      checkedInPlayerIds: checkedInPlayerIds ?? this.checkedInPlayerIds,
      organizerId: organizerId,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      arenaId: arenaId ?? this.arenaId,
      allowedSpellIds: allowedSpellIds ?? this.allowedSpellIds,
      rules: rules ?? this.rules,
      rewards: rewards ?? this.rewards,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
    );
  }
} 
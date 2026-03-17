class GamificationProfile {
  final int totalXP;
  final int level;
  final String levelTitle;
  final int xpCurrent;
  final int xpRequired;
  final int xpRemaining;
  final int campusCredits;
  final int currentStreak;
  final int longestStreak;
  final int badgeCount;
  final int totalBadgesAvailable;
  final Map<String, dynamic> stats;
  final List<XPTransaction> recentXP;

  GamificationProfile({
    required this.totalXP,
    required this.level,
    required this.levelTitle,
    required this.xpCurrent,
    required this.xpRequired,
    required this.xpRemaining,
    required this.campusCredits,
    required this.currentStreak,
    required this.longestStreak,
    required this.badgeCount,
    required this.totalBadgesAvailable,
    required this.stats,
    required this.recentXP,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    final xpNext = json['xpToNextLevel'] ?? {};
    return GamificationProfile(
      totalXP: (json['totalXP'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelTitle: json['levelTitle']?.toString() ?? 'Freshman',
      xpCurrent: (xpNext['current'] as num?)?.toInt() ?? 0,
      xpRequired: (xpNext['required'] as num?)?.toInt() ?? 100,
      xpRemaining: (xpNext['remaining'] as num?)?.toInt() ?? 100,
      campusCredits: (json['campusCredits'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      badgeCount: (json['badgeCount'] as num?)?.toInt() ?? 0,
      totalBadgesAvailable: (json['totalBadgesAvailable'] as num?)?.toInt() ?? 18,
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      recentXP: (json['recentXP'] as List? ?? [])
          .map((e) => XPTransaction.fromJson(e))
          .toList(),
    );
  }
}

class XPTransaction {
  final String action;
  final int xp;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  XPTransaction({
    required this.action,
    required this.xp,
    required this.description,
    required this.metadata,
    required this.createdAt,
  });

  factory XPTransaction.fromJson(Map<String, dynamic> json) {
    return XPTransaction(
      action: json['action']?.toString() ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class GamificationBadge {
  final String badgeId;
  final String name;
  final String description;
  final String category;
  final String rarity;
  final String icon;
  final bool earned;
  final DateTime? earnedAt;

  GamificationBadge({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.icon,
    required this.earned,
    this.earnedAt,
  });

  factory GamificationBadge.fromJson(Map<String, dynamic> json) {
    return GamificationBadge(
      badgeId: json['badgeId']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'quiz',
      rarity: json['rarity']?.toString() ?? 'common',
      icon: json['icon']?.toString() ?? 'star',
      earned: json['earned'] == true,
      earnedAt: json['earnedAt'] != null
          ? DateTime.tryParse(json['earnedAt'].toString())
          : null,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String studentId;
  final String? instituteId;
  final int totalXP;
  final int level;
  final String levelTitle;
  final int badgeCount;
  final int streak;

  LeaderboardEntry({
    required this.rank,
    required this.studentId,
    this.instituteId,
    required this.totalXP,
    required this.level,
    required this.levelTitle,
    required this.badgeCount,
    required this.streak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      studentId: json['studentId']?.toString() ?? '',
      instituteId: json['instituteId']?.toString(),
      totalXP: (json['totalXP'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelTitle: json['levelTitle']?.toString() ?? 'Freshman',
      badgeCount: (json['badgeCount'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final int myRank;
  final int total;

  LeaderboardData({
    required this.entries,
    required this.myRank,
    required this.total,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      entries: (json['leaderboard'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      myRank: (json['myRank'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

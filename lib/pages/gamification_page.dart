import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gamification_model.dart';
import '../services/gamification_service.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  GamificationProfile? _profile;
  List<GamificationBadge> _badges = [];
  LeaderboardData? _leaderboard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        GamificationService.getProfile(),
        GamificationService.getBadges(),
        GamificationService.getLeaderboard(limit: 5),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as GamificationProfile;
          _badges = results[1] as List<GamificationBadge>;
          _leaderboard = results[2] as LeaderboardData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.black54),
                          const SizedBox(height: 12),
                          Text('Something went wrong',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _fetchData,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                              ),
                              child: Text('RETRY', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: Colors.black,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildProfileCard(),
                          const SizedBox(height: 14),
                          _buildXPProgressBar(),
                          const SizedBox(height: 20),
                          _buildStatsGrid(),
                          const SizedBox(height: 20),
                          _buildRecentXPFeed(),
                          const SizedBox(height: 20),
                          _buildBadgeGallery(),
                          const SizedBox(height: 20),
                          _buildLeaderboardPreview(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Section 1: Header ──────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text('Rewards',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 4),
              Text('${_profile?.campusCredits ?? 0}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section 2: Profile Card ────────────────────────────────────
  Widget _buildProfileCard() {
    final p = _profile!;
    final progress = p.xpRequired > 0 ? (p.xpCurrent / p.xpRequired).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(
        children: [
          // XP Progress Ring
          SizedBox(
            width: 85,
            height: 85,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 85,
                  height: 85,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1BEE7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Center(
                    child: Text('${p.level}',
                        style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8E6CF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(p.levelTitle.toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                Text('${p.totalXP} XP',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFFFF6B6B), size: 18),
                    const SizedBox(width: 4),
                    Text('${p.currentStreak} day streak',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('Best: ${p.longestStreak}',
                        style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 3: XP Progress Bar ─────────────────────────────────
  Widget _buildXPProgressBar() {
    final p = _profile!;
    final fraction = p.xpRequired > 0 ? (p.xpCurrent / p.xpRequired).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LEVEL ${p.level}',
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              Text('LEVEL ${p.level + 1}',
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${p.xpCurrent} / ${p.xpRequired} XP',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
        ],
      ),
    );
  }

  // ── Section 4: Stats Grid ──────────────────────────────────────
  Widget _buildStatsGrid() {
    final stats = _profile!.stats;
    final items = [
      {'label': 'QUIZZES\nPASSED', 'value': '${stats['quizzesPassed'] ?? 0}', 'icon': Icons.quiz, 'color': const Color(0xFFFFF9C4)},
      {'label': 'MODULES\nDONE', 'value': '${stats['modulesCompleted'] ?? 0}', 'icon': Icons.school, 'color': const Color(0xFFC5CAE9)},
      {'label': 'CAPSTONES', 'value': '${stats['capstonesEvaluated'] ?? 0}', 'icon': Icons.build, 'color': const Color(0xFFFFCDD2)},
      {'label': 'INTERVIEWS', 'value': '${stats['mockInterviewsCompleted'] ?? 0}', 'icon': Icons.mic, 'color': const Color(0xFFE1BEE7)},
      {'label': 'BADGES', 'value': '${_profile!.badgeCount}', 'icon': Icons.military_tech, 'color': const Color(0xFFA8E6CF)},
      {'label': 'RANK', 'value': '#${_leaderboard?.myRank ?? '-'}', 'icon': Icons.leaderboard, 'color': const Color(0xFFFFD3B6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Stats', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item['color'] as Color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, size: 20, color: Colors.black87),
                  const SizedBox(height: 4),
                  Text(item['value'] as String,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(item['label'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.3, height: 1.2)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Section 5: Recent XP Feed ──────────────────────────────────
  Widget _buildRecentXPFeed() {
    final recentXP = _profile!.recentXP;
    if (recentXP.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent XP', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...recentXP.take(5).map((xp) => _buildXPRow(xp)),
        ],
      ),
    );
  }

  Widget _buildXPRow(XPTransaction xp) {
    IconData icon;
    switch (xp.action) {
      case 'quiz_pass':
        icon = Icons.quiz;
        break;
      case 'quiz_perfect':
        icon = Icons.stars;
        break;
      case 'quiz_first_try':
        icon = Icons.looks_one;
        break;
      case 'module_completed':
        icon = Icons.school;
        break;
      case 'learning_path_completed':
        icon = Icons.route;
        break;
      case 'capstone_evaluated':
        icon = Icons.build;
        break;
      case 'mock_interview_completed':
        icon = Icons.mic;
        break;
      case 'daily_login':
        icon = Icons.login;
        break;
      case 'login_streak_bonus':
        icon = Icons.local_fire_department;
        break;
      case 'performance_improvement':
        icon = Icons.trending_up;
        break;
      default:
        icon = Icons.star;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFA8E6CF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 18, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(xp.description,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(_timeAgo(xp.createdAt),
                    style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black45)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFA8E6CF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text('+${xp.xp} XP',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ── Section 6: Badge Gallery ───────────────────────────────────
  Widget _buildBadgeGallery() {
    final grouped = <String, List<GamificationBadge>>{};
    for (final b in _badges) {
      grouped.putIfAbsent(b.category, () => []).add(b);
    }

    const categoryOrder = ['quiz', 'learning', 'project', 'interview', 'engagement', 'legendary'];
    const categoryLabels = {
      'quiz': 'QUIZ MASTERY',
      'learning': 'LEARNING',
      'project': 'PROJECTS',
      'interview': 'INTERVIEW',
      'engagement': 'ENGAGEMENT',
      'legendary': 'LEGENDARY',
    };

    final earnedCount = _badges.where((b) => b.earned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Badge Gallery', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$earnedCount / ${_badges.length}',
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...categoryOrder.where((c) => grouped.containsKey(c)).map((cat) {
          return _buildBadgeCategory(categoryLabels[cat] ?? cat.toUpperCase(), grouped[cat]!);
        }),
      ],
    );
  }

  Widget _buildBadgeCategory(String label, List<GamificationBadge> badges) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges.map<Widget>((b) => _buildBadgeItem(b)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'rare':
        return const Color(0xFF3B82F6);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'legendary':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _badgeIcon(String category) {
    switch (category) {
      case 'quiz':
        return Icons.quiz;
      case 'learning':
        return Icons.school;
      case 'project':
        return Icons.build;
      case 'interview':
        return Icons.mic;
      case 'engagement':
        return Icons.local_fire_department;
      case 'legendary':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  Widget _buildBadgeItem(GamificationBadge badge) {
    final rColor = _rarityColor(badge.rarity);

    return GestureDetector(
      onTap: () => _showBadgeDetail(badge),
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: badge.earned ? rColor.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge.earned ? rColor : Colors.grey.shade300,
            width: badge.earned ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(_badgeIcon(badge.category),
                    size: 28, color: badge.earned ? rColor : Colors.grey.shade400),
                if (!badge.earned)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.lock, size: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(badge.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: badge.earned ? Colors.black : Colors.grey,
                )),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(GamificationBadge badge) {
    final rColor = _rarityColor(badge.rarity);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_badgeIcon(badge.category),
                size: 48, color: badge.earned ? rColor : Colors.grey),
            const SizedBox(height: 12),
            Text(badge.name,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge.rarity.toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 14),
            Text(badge.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if (badge.earned && badge.earnedAt != null)
              Text('Earned ${_timeAgo(badge.earnedAt!)}',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
            if (!badge.earned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('LOCKED',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Section 7: Leaderboard Preview ─────────────────────────────
  Widget _buildLeaderboardPreview() {
    if (_leaderboard == null || _leaderboard!.entries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Leaderboard',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text('YOUR RANK: #${_leaderboard!.myRank}',
                    style: GoogleFonts.poppins(
                        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._leaderboard!.entries.map((e) => _buildLeaderboardRow(e)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    Color? medalColor;
    if (entry.rank == 1) medalColor = const Color(0xFFF59E0B);
    if (entry.rank == 2) medalColor = const Color(0xFF9CA3AF);
    if (entry.rank == 3) medalColor = const Color(0xFFCD7F32);

    final isMe = entry.rank == _leaderboard!.myRank;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFA8E6CF) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? Colors.black : Colors.grey.shade300, width: isMe ? 2 : 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: medalColor ?? Colors.grey.shade200,
              shape: BoxShape.circle,
              border: entry.rank <= 3 ? Border.all(color: Colors.black, width: 1.5) : null,
            ),
            child: Center(
              child: Text('${entry.rank}',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: entry.rank <= 3 ? Colors.white : Colors.black)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.studentId,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Lv.${entry.level} ${entry.levelTitle}',
                    style: GoogleFonts.poppins(
                        fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
              ],
            ),
          ),
          Text('${entry.totalXP} XP',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

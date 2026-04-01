import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/student_service.dart';
import '../models/faculty_annotation_model.dart';
import '../models/notice_model.dart';

class FacultyNotesPage extends StatefulWidget {
  const FacultyNotesPage({super.key});

  @override
  State<FacultyNotesPage> createState() => _FacultyNotesPageState();
}

class _FacultyNotesPageState extends State<FacultyNotesPage> {
  bool _loading = true;
  List<FacultyAnnotation> _facultyNotes = [];
  List<Notice> _notices = [];
  int _selectedTab = 0;
  final PageController _pageCtrl = PageController();

  static const _bg    = Color(0xFFFFFBF0);
  static const _amber = Color(0xFFFFAB00);
  static const _mint  = Color(0xFFA8E6CF);
  static const _coral = Color(0xFFFF8B94);
  static const _sky   = Color(0xFFB3E5FC);
  static const _black = Colors.black;

  static const _stripes = [
    Color(0xFFFFAB00),
    Color(0xFF4DB6AC),
    Color(0xFFFF8B94),
    Color(0xFF81C784),
    Color(0xFF7986CB),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    List<FacultyAnnotation> fetchedNotes = [];
    List<Notice> fetchedNotices = [];

    // Run both requests in PARALLEL — cuts load time in half
    await Future.wait([
      StudentService.getFacultyNotes()
          .then((v) => fetchedNotes = v)
          .catchError((e) {
        if (kDebugMode) debugPrint('[FacultyAnnotation] ERROR: $e');
      }),
      StudentService.getNotices()
          .then((v) => fetchedNotices = v)
          .catchError((e) {
        if (kDebugMode) debugPrint('[Notices] ERROR: $e');
      }),
    ]);

    if (mounted) {
      setState(() {
        _facultyNotes = fetchedNotes;
        _notices      = fetchedNotices;
        _loading      = false;
      });
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1)    return '${diff.inDays}d ago';
    if (diff.inDays == 1)   return '1d ago';
    if (diff.inHours > 0)   return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildSegmentedTab(),
            const SizedBox(height: 4),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _amber, strokeWidth: 2.5))
                  : PageView(
                      controller: _pageCtrl,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() => _selectedTab = page);
                      },
                      children: [
                        _buildAnnotationsTab(),
                        _buildNoticeTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _black, width: 1.8),
                boxShadow: const [BoxShadow(color: _black, offset: Offset(2, 2))],
              ),
              child: const Icon(Icons.arrow_back, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACULTY ANNOTATION',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.5),
                ),
                Text(
                  'Guidance & notices from your faculty',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.black45),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _black, width: 1.8),
                boxShadow: const [BoxShadow(color: _black, offset: Offset(2, 2))],
              ),
              child: const Icon(Icons.refresh, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented Tab ──────────────────────────────────────────────────────────

  Widget _buildSegmentedTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEADD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _black, width: 2),
        ),
        child: Stack(
          children: [
            // ── Sliding highlight pill ───────────────────────────────────
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              alignment: _selectedTab == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                width: (MediaQuery.of(context).size.width - 28 - 8 - 8) / 2,
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? _amber : _sky,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _black, width: 1.5),
                ),
              ),
            ),

            // ── Tab labels on top ────────────────────────────────────────
            Row(
              children: [
                _tabLabel(index: 0, icon: Icons.comment_bank_outlined,
                    label: 'Annotation',
                    badge: _facultyNotes.isNotEmpty ? '${_facultyNotes.length}' : null),
                _tabLabel(index: 1, icon: Icons.campaign_outlined,
                    label: 'Notice'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabLabel({
    required int index,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _pageCtrl.animateToPage(
            index,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
          );
        },
        child: SizedBox.expand(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15,
                  color: isActive ? _black : Colors.black38),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                  color: isActive ? _black : Colors.black38,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive ? _black : Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge,
                      style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Annotation Tab ─────────────────────────────────────────────────────────

  Widget _buildAnnotationsTab() {
    if (_facultyNotes.isEmpty) {
      return _emptyState(
        icon: Icons.comment_bank_outlined,
        iconColor: _amber,
        title: 'No Annotations Yet',
        subtitle: 'When your faculty adds annotations,\nthey will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _amber,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        itemCount: _facultyNotes.length,
        itemBuilder: (ctx, i) => _buildAnnotationCard(_facultyNotes[i], i),
      ),
    );
  }

  Widget _buildAnnotationCard(FacultyAnnotation note, int index) {
    final stripe = _stripes[index % _stripes.length];
    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _black, width: 2),
          boxShadow: const [BoxShadow(color: _black, offset: Offset(3, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left coloured accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Faculty chip + timestamp
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: stripe,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _black, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                note.facultyName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time, size: 11, color: Colors.black38),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(note.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    // Note text
                    Text(
                      note.note,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Alert ID tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '# ${note.alertId}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.black38,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notice Tab ─────────────────────────────────────────────────────────────

  Widget _buildNoticeTab() {
    if (_notices.isEmpty) {
      return _emptyState(
        icon: Icons.campaign_outlined,
        iconColor: _sky,
        title: 'No Notices Yet',
        subtitle: 'Faculty notices and\nannouncements will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _sky,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        itemCount: _notices.length,
        itemBuilder: (ctx, i) => _buildNoticeCard(_notices[i]),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice) {
    final p = notice.priority.toLowerCase().trim();

    final bool isUrgent = p == 'high' || p == 'urgent' || p == 'critical';
    final bool isLow    = p == 'low'  || p == 'normal' || p == 'info';

    // Use app theme palette — no dark headers, match cream background
    final Color accentBar;   // left bar
    final Color cardTint;    // very subtle card bg tint
    final Color iconColor;   // icon fg
    final Color iconBg;      // icon bg bubble
    final Color badgeBg;
    final Color badgeFg;
    final IconData icon;
    final String badgeLabel;

    if (isUrgent) {
      accentBar  = const Color(0xFFE53935);   // red
      cardTint   = const Color(0xFFFFF8F8);
      iconColor  = const Color(0xFFE53935);
      iconBg     = const Color(0xFFFFEBEE);
      badgeBg    = const Color(0xFFFFCDD2);
      badgeFg    = const Color(0xFFB71C1C);
      icon       = Icons.warning_amber_rounded;
      badgeLabel = '⚠ URGENT';
    } else if (isLow) {
      accentBar  = const Color(0xFF43A047);   // green
      cardTint   = const Color(0xFFF8FFFE);
      iconColor  = const Color(0xFF2E7D32);
      iconBg     = const Color(0xFFA8E6CF);
      badgeBg    = const Color(0xFFA8E6CF);
      badgeFg    = const Color(0xFF1B5E20);
      icon       = Icons.campaign_outlined;
      badgeLabel = 'GENERAL';
    } else {
      accentBar  = const Color(0xFFFFAB00);   // amber — app primary
      cardTint   = const Color(0xFFFFFDF5);
      iconColor  = const Color(0xFFE65100);
      iconBg     = const Color(0xFFFFECB3);
      badgeBg    = const Color(0xFFFFD54F);
      badgeFg    = const Color(0xFF663C00);
      icon       = Icons.info_outline;
      badgeLabel = 'NOTICE';
    }

    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _black, width: 2),
          boxShadow: const [BoxShadow(color: _black, offset: Offset(3, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentBar,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: _black, width: 1),
                          ),
                          child: Icon(icon, size: 15, color: iconColor),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            notice.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _black, width: 1.5),
                          ),
                          child: Text(
                            badgeLabel,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              fontSize: 8.5,
                              color: badgeFg,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Divider
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 1,
                      color: accentBar.withValues(alpha: 0.2),
                    ),
                    // Message
                    Text(
                      notice.message,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 9),
                    // Footer
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 11, color: accentBar),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(notice.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black45,
                          ),
                        ),
                        if (notice.expiresAt != null) ...[
                          const SizedBox(width: 8),
                          Container(width: 3, height: 3,
                              decoration: BoxDecoration(
                                color: accentBar.withValues(alpha: 0.4),
                                shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Icon(Icons.event_busy_outlined,
                              size: 11, color: accentBar),
                          const SizedBox(width: 4),
                          Text(
                            'Expires ${_timeAgo(notice.expiresAt!)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }





  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _emptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _black, width: 2),
              boxShadow: const [BoxShadow(color: _black, offset: Offset(4, 4))],
            ),
            child: Icon(icon, size: 42, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

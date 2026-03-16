import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/student_service.dart';
import '../models/faculty_annotation_model.dart';
import '../models/performance_model.dart';

class FacultyNotesPage extends StatefulWidget {
  const FacultyNotesPage({super.key});

  @override
  State<FacultyNotesPage> createState() => _FacultyNotesPageState();
}

class _FacultyNotesPageState extends State<FacultyNotesPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<FacultyAnnotation> _facultyNotes = [];
  InterventionData? _intervention;
  late TabController _tabCtrl;

  static const _bg = Color(0xFFF5F0FF);
  static const _purple = Color(0xFFD4AAFF);
  static const _green = Color(0xFF40FFA7);
  static const _yellow = Color(0xFFFFD54F);
  static const _red = Color(0xFFFF8B94);
  static const _black = Colors.black;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([_loadFacultyNotes(), _loadIntervention()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadFacultyNotes() async {
    try {
      final notes = await StudentService.getFacultyNotes();
      if (mounted) setState(() => _facultyNotes = notes);
    } catch (_) {}
  }

  Future<void> _loadIntervention() async {
    try {
      final data = await StudentService.getIntervention();
      if (mounted) setState(() => _intervention = data);
    } catch (_) {}
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) return '${diff.inDays}d ago';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: _black, strokeWidth: 2.5))
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildNotesTab(),
                        _buildInterventionTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _black, width: 2),
                boxShadow: const [
                  BoxShadow(color: _black, offset: Offset(3, 3)),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACULTY NOTES',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Messages & guidance from your faculty',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _black, width: 2),
                boxShadow: const [
                  BoxShadow(color: _black, offset: Offset(3, 3)),
                ],
              ),
              child: const Icon(Icons.refresh, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _black, width: 2),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: _purple,
            borderRadius: BorderRadius.circular(14),
          ),
          labelColor: _black,
          unselectedLabelColor: Colors.black54,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dividerHeight: 0,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sticky_note_2, size: 16),
                  const SizedBox(width: 6),
                  Text('Notes (${_facultyNotes.length})'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment, size: 16),
                  SizedBox(width: 6),
                  Text('Actions'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── NOTES TAB ──────────────────────────────────────────────────────────

  Widget _buildNotesTab() {
    if (_facultyNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _black, width: 2),
              ),
              child:
                  const Icon(Icons.mark_email_read, size: 48, color: _purple),
            ),
            const SizedBox(height: 16),
            Text(
              'No Faculty Notes Yet',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When your faculty adds notes or\nannotations, they will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _facultyNotes.length,
        itemBuilder: (ctx, i) => _buildNoteCard(_facultyNotes[i]),
      ),
    );
  }

  Widget _buildNoteCard(FacultyAnnotation note) {
    final color = _purple;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _black, width: 2),
        boxShadow: const [
          BoxShadow(color: _black, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header stripe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _black, width: 1.5),
                  ),
                  child: const Icon(Icons.school, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.facultyName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        note.alertId,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              note.note,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  _timeAgo(note.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── INTERVENTION TAB ───────────────────────────────────────────────────

  Widget _buildInterventionTab() {
    if (_intervention == null || !_intervention!.interventionRequired) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _black, width: 2),
              ),
              child: const Icon(Icons.check_circle, size: 48, color: _green),
            ),
            const SizedBox(height: 16),
            Text(
              'No Interventions Needed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You\'re on track! No faculty\ninterventions at this time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    final actions = _intervention!.actions;
    final pending = _intervention!.pendingActions;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _black,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          _buildSummaryCard(pending),
          const SizedBox(height: 16),
          // Action items
          ...actions.map((a) => _buildActionCard(a)),
          const SizedBox(height: 16),
          // Next review
          if (_intervention!.daysUntilReview > 0) _buildReviewCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int pending) {
    final priority = _intervention!.priority.toLowerCase();
    final priorityColor = priority == 'high'
        ? _red
        : priority == 'moderate'
            ? _yellow
            : _green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: priorityColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _black, width: 2),
        boxShadow: const [
          BoxShadow(color: _black, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _black, width: 2),
            ),
            child: const Icon(Icons.assignment_turned_in, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACULTY GUIDANCE',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pending pending action${pending == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _black, width: 2),
            ),
            child: Text(
              _intervention!.priority.toUpperCase(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(InterventionAction action) {
    final done = action.status.toLowerCase() == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? _green.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _black, width: 2),
        boxShadow: const [
          BoxShadow(color: _black, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: done ? _green : _purple,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _black, width: 1.5),
            ),
            child: Icon(
              done ? Icons.check : Icons.pending_actions,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: done ? Colors.black45 : _black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: done ? Colors.black45 : Colors.black87,
                    height: 1.4,
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _black, width: 2),
        boxShadow: const [
          BoxShadow(color: _black, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _yellow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _black, width: 1.5),
            ),
            child: const Icon(Icons.event, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT REVIEW',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'In ${_intervention!.daysUntilReview} day${_intervention!.daysUntilReview == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

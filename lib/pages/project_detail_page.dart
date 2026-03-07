
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/project_service.dart';

// ── Palette ─────────────────────────────────────────────────────────────────
const _bg     = Color(0xFFF4F7F5);
const _black  = Color(0xFF0D0D0D);
const _white  = Color(0xFFFFFFFF);
const _green  = Color(0xFF84DCC6);
const _red    = Color(0xFFFF8B94);
const _yellow = Color(0xFFFFB703);
const _blue   = Color(0xFF64B5F6);
const _purple = Color(0xFFB5A1E5);
const _orange = Color(0xFFFFD6A5);

BoxDecoration _card(Color color, {double r = 16, double s = 3}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(r),
  border: Border.all(color: _black, width: 2),
  boxShadow: [BoxShadow(color: _black, offset: Offset(s, s))],
);


TextStyle _h2() => GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _black);
TextStyle _body() => GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.4);
TextStyle _label() => GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.2);
TextStyle _tag() => GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _black);

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});
  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _repoCtrl = TextEditingController();

  bool _loading    = true;
  bool _submitting = false;
  bool _showDetailed = false;
  String _error    = '';

  Map<String, dynamic>? _project;
  Map<String, dynamic>? _evaluation;

  late AnimationController _scoreAnimCtrl;
  late Animation<double>   _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scoreAnimCtrl, curve: Curves.easeOutCubic));
    _fetch();
  }

  @override
  void dispose() {
    _scoreAnimCtrl.dispose();
    _repoCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final d = await ProjectService.getProject(widget.projectId);
      setState(() {
        _project = d;
        _loading = false;
        if (d['status'] == 'evaluated' && d['evaluation'] != null) {
          _evaluation = d['evaluation'];
          _scoreAnimCtrl.forward();
        }
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception:', '').trim(); });
    }
  }

  Future<void> _submit() async {
    final url = _repoCtrl.text.trim();
    if (url.isEmpty || !url.contains('github.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paste a valid GitHub URL')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final d = await ProjectService.submitProject(widget.projectId, url);
      setState(() {
        _submitting = false;
        _evaluation = d['evaluation'];
        _project?['status'] = 'evaluated';
      });
      _scoreAnimCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception:', '').trim())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _black, borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('←', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _white))),
            ),
          ),
        ),
        title: Text('Project', style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w800, color: _black)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _black))
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameCard(),
                      const SizedBox(height: 16),
                      _buildInfoRow(),
                      const SizedBox(height: 20),
                      _buildTechChips(),
                      const SizedBox(height: 24),
                      _buildReqs(),
                      const SizedBox(height: 28),
                      if (_evaluation == null) _buildSubmitCard(),
                      if (_evaluation != null) ...[
                        _buildScoreSection(),
                        const SizedBox(height: 20),
                        if (!_showDetailed)
                          GestureDetector(
                            onTap: () => setState(() => _showDetailed = true),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _black,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [BoxShadow(color: Color(0xFF444444), offset: Offset(3, 3))],
                              ),
                              child: Center(
                                child: Text('Show Detailed Results',
                                    style: GoogleFonts.poppins(
                                        color: _white, fontWeight: FontWeight.w800, fontSize: 15)),
                              ),
                            ),
                          ),
                        if (_showDetailed) ...[
                          const SizedBox(height: 4),
                          _buildRadarChart(),
                          const SizedBox(height: 24),
                          _buildFeedbackCard(),
                          const SizedBox(height: 24),
                          _buildReqChecklist(),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  // ── Name card ──────────────────────────────────────────────────────────
  Widget _buildNameCard() {
    final name = _project?['name']?.toString() ?? 'Project';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(_black, s: 4),
      child: Text(name,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: _white, height: 1.3)),
    );
  }

  // ── Info row (difficulty + hours) ───────────────────────────────────────
  Widget _buildInfoRow() {
    final diff  = _project?['difficulty']?.toString() ?? 'Medium';
    final hours = _project?['estimatedHours']?.toString() ?? '?';
    final desc  = _project?['description']?.toString() ?? '';

    Color dc = _yellow;
    if (diff.toLowerCase() == 'hard') dc = _red;
    if (diff.toLowerCase() == 'easy') dc = _green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _chip(diff.toUpperCase(), dc),
            const SizedBox(width: 8),
            _chip('$hours HRS', _blue),
          ],
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(desc, style: _body(), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }

  Widget _chip(String txt, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _black, width: 1.5)),
    child: Text(txt, style: _tag()),
  );

  // ── Tech stack chips ───────────────────────────────────────────────────
  Widget _buildTechChips() {
    final list = (_project?['techStack'] as List<dynamic>?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    final colors = [_green, _purple, _yellow, _blue, _orange, _red];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TECH STACK', style: _label()),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: list.asMap().entries.map((e) =>
            _chip(e.value.toString(), colors[e.key % colors.length])).toList()),
      ],
    );
  }

  // ── Requirements (tappable expand) ──────────────────────────────────
  final Set<int> _expandedReqs = {};

  Widget _buildReqs() {
    final reqs = (_project?['requirements'] as List<dynamic>?) ?? [];
    if (reqs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REQUIREMENTS', style: _label()),
        const SizedBox(height: 10),
        Container(
          decoration: _card(_white),
          child: Column(
            children: reqs.asMap().entries.map((e) {
              final r = e.value;
              final title = r['title']?.toString() ?? '';
              final desc  = r['description']?.toString() ?? '';
              final isOpen = _expandedReqs.contains(e.key);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isOpen) { _expandedReqs.remove(e.key); }
                  else { _expandedReqs.add(e.key); }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFFF5F5F5) : _white,
                    border: e.key < reqs.length - 1
                        ? const Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(color: _black, borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('${e.key + 1}',
                                style: GoogleFonts.poppins(color: _white, fontSize: 11, fontWeight: FontWeight.w800))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(title, style: _h2().copyWith(fontSize: 13))),
                          AnimatedRotation(
                            turns: isOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Text('▾', style: TextStyle(fontSize: 16, color: Colors.black45)),
                          ),
                        ],
                      ),
                      if (isOpen && desc.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(desc, style: _body()),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Submit card ────────────────────────────────────────────────────────
  Widget _buildSubmitCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(_yellow, s: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUBMIT REPO', style: _label().copyWith(color: Colors.black54)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _black, width: 2)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _repoCtrl,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'https://github.com/user/repo',
                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _submitting ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _black, borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0xFF444444), offset: Offset(3, 3))]),
              child: Center(
                child: _submitting
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                    : Text('Submit', style: GoogleFonts.poppins(
                        color: _white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Score + Grade ─────────────────────────────────────────────────────
  Widget _buildScoreSection() {
    final score = (_evaluation?['score'] as num?)?.toInt() ?? 0;
    final grade = _evaluation?['grade']?.toString() ?? '?';
    final sc = score >= 80 ? _green : score >= 50 ? _yellow : _red;

    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (_, __) {
        final animVal = (_scoreAnim.value * score).toInt();
        return Row(
          children: [
            // Donut chart
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: _card(sc, s: 5),
                child: Column(
                  children: [
                    SizedBox(
                      height: 130, width: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(PieChartData(
                            startDegreeOffset: -90,
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: _scoreAnim.value * score.toDouble(),
                                color: _black,
                                radius: 18,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: 100 - _scoreAnim.value * score.toDouble(),
                                color: _black.withAlpha(25),
                                radius: 18,
                                showTitle: false,
                              ),
                            ],
                          )),
                          Text('$animVal',
                              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('out of 100', style: _label()),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Grade
            Expanded(
              flex: 2,
              child: Container(
                height: 180,
                decoration: _card(_white, s: 5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(grade, style: GoogleFonts.poppins(fontSize: 52, fontWeight: FontWeight.w900)),
                      Text('GRADE', style: _label()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Radar chart for requirement breakdown ─────────────────────────────
  Widget _buildRadarChart() {
    final reqBreak = (_evaluation?['feedback']?['requirementBreakdown'] as List<dynamic>?) ?? [];
    if (reqBreak.length < 3) return const SizedBox.shrink(); // need 3+ for radar

    final entries = reqBreak.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SKILLS RADAR', style: _label()),
        const SizedBox(height: 10),
        Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          decoration: _card(_white),
          child: RadarChart(RadarChartData(
            dataSets: [
              RadarDataSet(
                dataEntries: entries.map((r) =>
                    RadarEntry(value: (r['met'] == true) ? 100 : 30)).toList(),
                fillColor: _green.withAlpha(80),
                borderColor: _black,
                borderWidth: 2,
                entryRadius: 3,
              ),
            ],
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            radarBorderData: const BorderSide(color: Color(0xFFE0E0E0)),
            gridBorderData: const BorderSide(color: Color(0xFFEEEEEE)),
            titlePositionPercentageOffset: 0.2,
            tickCount: 3,
            tickBorderData: const BorderSide(color: Color(0xFFE0E0E0)),
            ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
            getTitle: (i, _) {
              final title = (entries[i]['requirementTitle'] ?? 'R${i + 1}').toString();
              return RadarChartTitle(
                text: title.length > 10 ? '${title.substring(0, 10)}…' : title,
                angle: 0,
              );
            },
          )),
        ),
      ],
    );
  }

  // ── Feedback card (strengths + improvements as horizontal bars) ──────
  Widget _buildFeedbackCard() {
    final fb = _evaluation?['feedback'] as Map<String, dynamic>? ?? {};
    final overall = fb['overall']?.toString() ?? '';
    final strengths = (fb['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final improvements = (fb['improvements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overall.isNotEmpty) ...[
          Text('FEEDBACK', style: _label()),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _card(_white),
            child: Text(overall, style: _body(), maxLines: 4, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 16),
        ],

        // Strengths as green bars
        if (strengths.isNotEmpty) ...[
          Text('STRENGTHS', style: _label()),
          const SizedBox(height: 8),
          ...strengths.map((s) => _barItem(s, _green)),
          const SizedBox(height: 16),
        ],

        // Improvements as orange bars
        if (improvements.isNotEmpty) ...[
          Text('TO IMPROVE', style: _label()),
          const SizedBox(height: 8),
          ...improvements.map((s) => _barItem(s, _orange)),
        ],
      ],
    );
  }

  Widget _barItem(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _black, width: 1.5),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }

  // ── Requirement checklist (bar chart) ─────────────────────────────────
  Widget _buildReqChecklist() {
    final reqBreak = (_evaluation?['feedback']?['requirementBreakdown'] as List<dynamic>?) ?? [];
    if (reqBreak.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REQUIREMENTS', style: _label()),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _card(_white),
          child: Column(
            children: reqBreak.asMap().entries.map((e) {
              final r = e.value;
              final met = r['met'] == true;
              final title = r['requirementTitle']?.toString() ?? 'Req ${e.key + 1}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: met ? _green : _red,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _black, width: 1.5),
                          ),
                          child: Center(child: Text(met ? '✓' : '✗',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w900))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(title, style: _h2().copyWith(fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress-style bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: met ? 1.0 : 0.25,
                        minHeight: 8,
                        color: met ? _green : _red,
                        backgroundColor: const Color(0xFFEEEEEE),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

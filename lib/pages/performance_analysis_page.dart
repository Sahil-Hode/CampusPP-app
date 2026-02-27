import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/student_service.dart';
import 'ai_analysis_page.dart';

// ─── THEME CONSTANTS ────────────────────────────────────────────────────────
const _bg        = Color(0xFFF4F7F5);
const _black     = Color(0xFF0D0D0D);
const _white     = Color(0xFFFAFAF7);
const _yellow    = Color(0xFFFFB703);
const _orange    = Color(0xFFFB8500);
const _blue      = Color(0xFF8ECAE6);
const _navy      = Color(0xFF219EBC);
const _green     = Color(0xFF84DCC6);
const _purple    = Color(0xFFB5A1E5);
const _red       = Color(0xFFFF6B6B);

// ─── UTILS ──────────────────────────────────────────────────────────────────
BoxDecoration brutalBox(Color color, {double radius = 16, double shadow = 4}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _black, width: 2),
      boxShadow: [BoxShadow(color: _black, offset: Offset(shadow, shadow))],
    );

class PerformanceAnalysisPage extends StatefulWidget {
  const PerformanceAnalysisPage({super.key});

  @override
  State<PerformanceAnalysisPage> createState() => _PerformanceAnalysisPageState();
}

class _PerformanceAnalysisPageState extends State<PerformanceAnalysisPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await StudentService.getPerformanceRaw();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Safe map/list accessors
  dynamic get nested => _data ?? {};
  Map<String, dynamic> get currentPerformance => nested['currentPerformance'] ?? {};
  Map<String, dynamic> get metadata => currentPerformance['metadata'] ?? {};
  Map<String, dynamic> get predictive => currentPerformance['predictiveIntelligence'] ?? {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Performance Page',
            style: GoogleFonts.poppins(
                color: _black, fontSize: 20, fontWeight: FontWeight.w900)),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: brutalBox(_white, radius: 10, shadow: 2),
                child: const Icon(Icons.arrow_back, color: _black, size: 20),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _black, strokeWidth: 3))
          : _error != null
              ? Center(child: Text('Error: $_error\n\nPlease check server connection.',
                  textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: _black,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildMetricsGrid(),
                        const SizedBox(height: 16),
                        _buildPredictiveStrip(),
                        const SizedBox(height: 16),
                        _buildSmartAlert(),
                        const SizedBox(height: 24),
                        const _SectionTitle("RISK ANALYSIS"),
                        const SizedBox(height: 8),
                        _buildRiskBreakdown(),
                        const SizedBox(height: 16),
                        _buildImpactSimulator(),
                        const SizedBox(height: 16),
                        _buildTrendCard(),
                        const SizedBox(height: 24),
                        const _SectionTitle("PERFORMANCE PROFILE"),
                        const SizedBox(height: 8),
                        _buildStrengthsConcerns(),
                        const SizedBox(height: 16),
                        _buildAiReasoning(),
                        const SizedBox(height: 24),
                        const _SectionTitle("ACTIONABLE PLANS"),
                        const SizedBox(height: 8),
                        _buildActionPlan(),
                        const SizedBox(height: 16),
                        _buildInterventionCard(),
                        const SizedBox(height: 24),
                        const _SectionTitle("TOP RECOMMENDATIONS"),
                        const SizedBox(height: 8),
                        _buildRecommendations(),
                        const SizedBox(height: 32),
                        _buildCtaButton(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  // 1. Header Card (Score)
  Widget _buildHeaderCard() {
    final score = (currentPerformance['score'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(_white),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _purple,
              shape: BoxShape.circle,
              border: Border.all(color: _black, width: 2),
            ),
            child: const Icon(Icons.person, color: _white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Overall Score",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 12,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(_orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text("$score%",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1)),
        ],
      ),
    );
  }

  // 2. Metrics Grid (2x2)
  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _MetricBlock(label: "Attendance", value: "${metadata['attendance'] ?? 0}%", color: _blue),
              const SizedBox(height: 12),
              _MetricBlock(label: "Assignment", value: "${metadata['assignmentCompletion'] ?? 0}%", color: _green),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _MetricBlock(label: "Internal Marks", value: "${metadata['marks'] ?? 0}/100", color: _orange),
              const SizedBox(height: 12),
              _MetricBlock(label: "LMS Engagement", value: "${metadata['lmsEngagement'] ?? 0}/100", color: _purple),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Predictive Intelligence Bar
  Widget _buildPredictiveStrip() {
    final stabMap = predictive['academicStability'] is Map ? predictive['academicStability'] as Map<String, dynamic> : {};
    final stab = stabMap['stabilityScore']?.toString() ?? predictive['academicStability']?.toString() ?? '0.0';
    final risk = (predictive['failureProbability'] ?? predictive['failureRisk'] ?? stabMap['finalRisk'] ?? 0).toString();
    final conf = (predictive['confidence'] ?? stabMap['predictionConfidence'] ?? 0).toString();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip("Stability: $stab", _white, Icons.track_changes, Colors.blueAccent),
          const SizedBox(width: 8),
          _buildChip("Risk: $risk%", _white, Icons.warning_amber_rounded, Colors.orange),
          const SizedBox(width: 8),
          _buildChip("Confidence: $conf%", _white, Icons.analytics, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color bg, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: brutalBox(bg, radius: 100, shadow: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: _black)),
        ],
      ),
    );
  }

  // 4. Risk Breakdown
  Widget _buildRiskBreakdown() {
    final rb = predictive['riskBreakdown'] as Map<String, dynamic>? ?? {};
    final pWeakness = rb['primaryWeakness']?.toString() ?? 'None identified';
    final posFactors = (rb['positiveFactors'] as List<dynamic>? ?? []);
    final negFactors = (rb['negativeFactors'] as List<dynamic>? ?? []);
    final reasons = (rb['reasons'] as List<dynamic>? ?? []);

    return Container(
      decoration: brutalBox(_white),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: brutalBox(_red, radius: 8, shadow: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 16, color: _black),
                const SizedBox(width: 6),
                Text("Primary Weakness: $pWeakness",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 11, color: _black)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ...posFactors.map((f) => _buildPill(f.toString(), const Color(0xFFE8F5E9), Icons.check_circle, Colors.green)),
              ...negFactors.map((f) => _buildPill(f.toString(), const Color(0xFFFFEBEE), Icons.warning_rounded, Colors.redAccent)),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.black26),
            const SizedBox(height: 4),
            ...reasons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(r.toString(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))),
                ],
              ),
            )),
          ]
        ],
      ),
    );
  }

  Widget _buildPill(String t, Color c, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _black, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(t, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 5. Impact Simulator
  Widget _buildImpactSimulator() {
    final simList = predictive['impactSimulator'] as List<dynamic>? ?? [];
    if (simList.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(_navy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What-If Impact Simulator",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: _white, fontSize: 13)),
          const SizedBox(height: 12),
          ...simList.map((item) {
            final metric = item['metric'] ?? 'Metric';
            final target = item['targetValue'] ?? '100%';
            final oldRisk = item['currentRisk'] ?? '0';
            final newRisk = item['projectedRisk'] ?? '0';
            final impact = item['riskReduction'] ?? '0';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: brutalBox(_white, radius: 8, shadow: 0),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, size: 14, color: _black),
                  const SizedBox(width: 6),
                  Text("If $metric → $target",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11)),
                  const Spacer(),
                  Text("Risk: $oldRisk → $newRisk%",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10, color: Colors.black54)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4), border: Border.all(color: _black)),
                    child: Text("-$impact%", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 6. Trend Card
  Widget _buildTrendCard() {
    final ta = predictive['trendAnalysis'] as Map<String, dynamic>? ?? {};
    final overall = ta['overallTrend']?.toString() ?? 'Stable';
    final tb = ta['trendBreakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(_white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Trend: $overall",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tb.entries.map((e) {
                final val = e.value.toString().toLowerCase();
                IconData icon = Icons.arrow_forward;
                Color iColor = Colors.grey;
                if (val.contains("up") || val.contains("improv")) { icon = Icons.arrow_upward; iColor = Colors.green; }
                if (val.contains("down") || val.contains("declin")) { icon = Icons.arrow_downward; iColor = Colors.red; }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPill(e.key, _white, icon, iColor),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Smart Alert Banner
  Widget _buildSmartAlert() {
    final alert = predictive['smartAlert'] as Map<String, dynamic>? ?? {};
    if (alert.isEmpty) return const SizedBox.shrink();

    final level = alert['level']?.toString().toLowerCase() ?? 'info';
    final msg = alert['message']?.toString() ?? '';
    Color c = _green;
    IconData ic = Icons.info;
    if (level == 'warning') { c = _yellow; ic = Icons.warning; }
    if (level == 'critical') { c = _red; ic = Icons.error; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: brutalBox(c, radius: 8),
      child: Row(
        children: [
          Icon(ic, color: _black, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  // 8. Strengths & Concerns
  Widget _buildStrengthsConcerns() {
    final st = currentPerformance['strengths'] as List<dynamic>? ?? [];
    final cn = currentPerformance['concerns'] as List<dynamic>? ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ExpandableBox(title: "Strengths", icon: Icons.fitness_center, items: st, bg: _white, titleCol: _green)),
        const SizedBox(width: 12),
        Expanded(child: _ExpandableBox(title: "Concerns", icon: Icons.warning_amber_rounded, items: cn, bg: _white, titleCol: _red)),
      ],
    );
  }

  // 9. Recommendations
  Widget _buildRecommendations() {
    final rec = currentPerformance['recommendations'] as List<dynamic>? ?? [];
    if (rec.isEmpty) return const SizedBox.shrink();
    return Column(
      children: rec.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: brutalBox(_white),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: _orange),
            const SizedBox(width: 12),
            Expanded(child: Text(r.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12))),
          ],
        ),
      )).toList(),
    );
  }

  // 10. Reason / AI Analysis
  Widget _buildAiReasoning() {
    final reason = currentPerformance['reason']?.toString() ?? '';
    if (reason.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(_white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AI Assessment Reasoning",
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(reason,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  // 11. 7-Day Action Plan
  Widget _buildActionPlan() {
    final plan = predictive['actionPlan'] as Map<String, dynamic>? ?? {};
    final days = plan['days'] as List<dynamic>? ?? [];
    if (days.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: brutalBox(_navy),
      child: ExpansionTile(
        collapsedIconColor: _white,
        iconColor: _white,
        title: Text("7-Day Action Plan", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: _white)),
        subtitle: Text("Risk Reduction: ${plan['expectedRiskReduction'] ?? 'Unknown'}",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.white70, fontSize: 11)),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: days.map((day) {
                final d = day['day']?.toString() ?? '';
                final a = day['action']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50, padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(4)),
                        child: Center(child: Text(d, style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 10))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a, style: GoogleFonts.poppins(color: _white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  // 12. Intervention Actions
  Widget _buildInterventionCard() {
    final inv = currentPerformance['intervention'] as Map<String, dynamic>? ?? {};
    final actions = inv['actions'] as List<dynamic>? ?? [];
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(_white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Intervention Plan", style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...actions.map((act) {
            final t = act['type']?.toString().toUpperCase() ?? 'ACTION';
            final s = act['status']?.toString().toUpperCase() ?? 'PENDING';
            final d = act['description']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: brutalBox(_bg, radius: 8, shadow: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _black, borderRadius: BorderRadius.circular(4)),
                        child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: _white)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(d, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 13. CTA Button
  Widget _buildCtaButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AiAnalysisPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: brutalBox(_yellow, radius: 100, shadow: 4),
        child: Center(
          child: Text("View Detailed AI Report",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      ),
    );
  }
}

// ─── HELPER COMPONENTS ────────────────────────────────────────────────────────

class _MetricBlock extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricBlock({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: Colors.black45));
  }
}

class _ExpandableBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<dynamic> items;
  final Color bg;
  final Color titleCol;
  const _ExpandableBox({required this.title, required this.icon, required this.items, required this.bg, required this.titleCol});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: brutalBox(bg),
      child: ExpansionTile(
        shape: const Border(),
        title: Row(
          children: [
            Icon(icon, size: 16, color: titleCol),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12))),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: titleCol)),
                    Expanded(child: Text(i.toString(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500))),
                  ],
                ),
              )).toList(),
            ),
          )
        ],
      ),
    );
  }
}

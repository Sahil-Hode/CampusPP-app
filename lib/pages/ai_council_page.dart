import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';

// ─── THEME CONSTANTS ────────────────────────────────────────────────────────
const _bg        = Color(0xFFC2EED5);
const _black     = Color(0xFF0D0D0D);
const _white     = Color(0xFFFAFAF7);
const _yellow    = Color(0xFFFFE566);
const _purple    = Color(0xFFD4AAFF);
const _greenCard = Color(0xFF4DDBA0);
const _greenBtn  = Color(0xFF3DD68C);
const _indigo    = Color(0xFFE8EAF6);
const _lemon     = Color(0xFFFFFDE7);
const _redPill   = Color(0xFFFF4D4D);
const _bluePill  = Color(0xFF4D9FFF);

// ─── DECORATION HELPER ──────────────────────────────────────────────────────
BoxDecoration brutalBox(Color color, {double radius = 16, double shadow = 5}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _black, width: 2.5),
      boxShadow: [BoxShadow(color: _black, offset: Offset(shadow, shadow))],
    );

// ─── SCREEN ──────────────────────────────────────────────────────────────────
class AiCouncilScreen extends StatefulWidget {
  const AiCouncilScreen({super.key});
  @override
  State<AiCouncilScreen> createState() => _AiCouncilScreenState();
}

class _AiCouncilScreenState extends State<AiCouncilScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _councilFuture;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final String baseUrl = "https://campuspp-f7qx.onrender.com/api/ai-council";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _councilFuture = _fetchCouncil();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchCouncil({bool forceRegenerate = false}) async {
    try {
      final token = await AuthService.getToken();
      
      if (!forceRegenerate) {
        final headers = {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        };
        
        final res = await http.get(Uri.parse(baseUrl), headers: headers);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body)['data'];
          _animCtrl.forward();
          return data;
        }
      }

      // Explicitly trigger the /generate endpoint with the regenerate payload
      final gen = await http.post(
        Uri.parse('$baseUrl/generate'),
        body: jsonEncode({"regenerate": forceRegenerate}),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(gen.body)['data'];
      _animCtrl.forward();
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // ── FORMAT ISO TIMESTAMP ──────────────────────────────────────────────────
  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return 'Pending Action';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min  = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return "${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$min $ampm";
    } catch (_) {
      return iso;
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _councilFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _black, strokeWidth: 2.5),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48),
                      const SizedBox(height: 12),
                      Text("Couldn't load council data",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _councilFuture = _fetchCouncil()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: brutalBox(_greenBtn, radius: 10, shadow: 3),
                          child: Text("Retry",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data     = snap.data!;
            final stability = data['stabilitySnapshot'] as Map<String, dynamic>? ?? {};
            final alert     = data['alertSnapshot']     as Map<String, dynamic>? ?? {};
            final decision  = data['councilDecision']   as Map<String, dynamic>? ?? {};
            final agents    = data['agents']            as List<dynamic>? ?? [];

            return FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _Header(
                    onRefresh: () => setState(() {
                      _animCtrl.reset();
                      _councilFuture = _fetchCouncil();
                    }),
                    onRegenerate: () => setState(() {
                      _animCtrl.reset();
                      _councilFuture = _fetchCouncil(forceRegenerate: true);
                    }),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _StabilityCard(stability: stability),
                        const SizedBox(height: 12),
                        _MetricsRow(stability: stability),
                        const SizedBox(height: 12),
                        _AlertBanner(alert: alert),
                        const SizedBox(height: 12),
                        _VerdictCard(
                          decision: decision,
                          stability: stability,
                          formatTimestamp: _formatTimestamp,
                          onActivate: () => setState(() => _councilFuture = _fetchCouncil()),
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle(title: "COUNCIL AGENTS"),
                        const SizedBox(height: 8),
                        ...agents.map((a) => _AgentCard(
                          agent: a as Map<String, dynamic>,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onRegenerate;

  const _Header({required this.onRefresh, required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44, height: 44,
              decoration: brutalBox(_white, radius: 12, shadow: 3),
              child: const Center(
                child: Icon(Icons.arrow_back_rounded, size: 22, color: _black),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text("AI Council",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900, fontSize: 18, color: _black)),
          const Spacer(),
          // Regenerate AI Insights button
          GestureDetector(
            onTap: onRegenerate,
            child: Container(
              width: 42, height: 42,
              decoration: brutalBox(_white, radius: 12, shadow: 3),
              child: const Center(
                child: Icon(Icons.auto_awesome, size: 20, color: _purple),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh button
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 42, height: 42,
              decoration: brutalBox(_white, radius: 12, shadow: 3),
              child: const Center(
                child: Icon(Icons.refresh_rounded, size: 20, color: _black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STABILITY CARD ───────────────────────────────────────────────────────────
class _StabilityCard extends StatelessWidget {
  final Map<String, dynamic> stability;
  const _StabilityCard({required this.stability});

  @override
  Widget build(BuildContext context) {
    final score = (stability['stabilityScore'] as num?)?.toDouble() ?? 85.5;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: brutalBox(_greenCard),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _black, width: 2),
                ),
                child: const Center(child: Icon(Icons.track_changes, size: 22, color: _black)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Stability Score",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14, color: _black)),
                  Text("ACADEMIC HEALTH",
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: Colors.black54,
                          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                ],
              ),
              const Spacer(),
              Text("${score.toStringAsFixed(1)}%",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, fontSize: 26,
                      color: _black, letterSpacing: -1)),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: Colors.black.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(_black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── METRICS ROW ─────────────────────────────────────────────────────────────
class _MetricsRow extends StatelessWidget {
  final Map<String, dynamic> stability;
  const _MetricsRow({required this.stability});

  @override
  Widget build(BuildContext context) {
    final failureRisk  = stability['finalRisk']  ?? '15';
    final confidence   = stability['predictionConfidence']   ?? '70';

    return Row(
      children: [
        Expanded(child: _MetricCard(
          label: "Failure Risk",
          value: "$failureRisk%",
          sub: "Low Risk",
          icon: Icons.warning_amber_rounded,
          color: _yellow,
        )),
        const SizedBox(width: 12),
        Expanded(child: _MetricCard(
          label: "Confidence",
          value: "$confidence%",
          sub: "Moderate",
          icon: Icons.psychology_rounded,
          color: _purple,
        )),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Colors.black54, letterSpacing: 0.5)),
              Icon(icon, size: 18, color: Colors.black38),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900, fontSize: 30,
                  color: _black, letterSpacing: -1.5, height: 1)),
          const SizedBox(height: 4),
          Text(sub,
              style: GoogleFonts.poppins(
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: Colors.black38, letterSpacing: 0.5,
                  textStyle: const TextStyle(decoration: TextDecoration.none))),
        ],
      ),
    );
  }
}

// ─── ALERT BANNER ─────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final msg  = alert['message']  as String? ?? "Great performance! Keep up the consistency.";
    final type = alert['level']     as String? ?? 'success';
    final isGood = type == 'success' || type == 'info';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: brutalBox(isGood ? const Color(0xFFE8FFF4) : const Color(0xFFFFF3E0)),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: isGood ? _greenBtn : _yellow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _black, width: 1.5),
            ),
            child: Center(
              child: Icon(
                isGood ? Icons.check_circle : Icons.warning_rounded,
                size: 20, 
                color: _black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _black,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ─── VERDICT CARD ─────────────────────────────────────────────────────────────
class _VerdictCard extends StatelessWidget {
  final Map<String, dynamic> decision;
  final Map<String, dynamic> stability;
  final String Function(String?) formatTimestamp;
  final VoidCallback onActivate;

  const _VerdictCard({
    required this.decision,
    required this.stability,
    required this.formatTimestamp,
    required this.onActivate,
  });

  Future<void> _activateBtnPressed(BuildContext context) async {
    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("https://campuspp-f7qx.onrender.com/api/ai-council/activate-plan");
      final res = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚀 7-Day Plan Activated!")),
        );
        onActivate();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to activate plan.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgency    = decision['urgencyLevel']        as String? ?? 'LOW';
    final trend      = stability['trend']              as String? ?? 'STABLE';
    final focus      = decision['priorityFocusArea']   as String? ?? 'GENERAL';
    final risk       = decision['riskSentence']        as String? ?? 'Failure risk is 15%';
    final summary    = decision['overallSummary']      as String? ?? '';
    final action     = decision['recommendedAction']   as String? ?? '';
    final active     = decision['actionPlanActivated'] as bool?   ?? false;
    final activatedAt = decision['actionPlanActivatedAt'] as String?;

    return Container(
      decoration: brutalBox(_white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // — Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("AI Verdict",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900, fontSize: 24,
                              color: _black, letterSpacing: -0.8, height: 1.1)),
                      const SizedBox(height: 2),
                      Text("Quiz & Assessment Performance",
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black45,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Urgency box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _greenCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _black, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text("URGENCY",
                          style: GoogleFonts.poppins(
                              fontSize: 7, fontWeight: FontWeight.w700,
                              color: Colors.black45, letterSpacing: 1)),
                      Text(urgency.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w900, color: _black)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // — Strips
          Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                  horizontal: BorderSide(color: _black, width: 2)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StripItem(label: "SYSTEM OUTLOOK", value: trend, color: _indigo),
                  Container(width: 2, color: _black),
                  _StripItem(label: "FOCUS AREA",     value: focus, color: _lemon),
                ],
              ),
            ),
          ),

          // — Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RISK LEVEL pill row
                _PillRow(
                  pillLabel: "RISK LEVEL",
                  pillColor: _redPill,
                  text: risk,
                ),
                const SizedBox(height: 10),
                // ACTION pill row
                _PillRow(
                  pillLabel: "ACTION",
                  pillColor: _bluePill,
                  text: action,
                ),
                const SizedBox(height: 14),

                // Analysis chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _black,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text("ANALYSIS: ${risk.split(' ').last.toUpperCase()}",
                      style: const TextStyle(
                          color: _white, fontWeight: FontWeight.w800,
                          fontSize: 9, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 12),

                // Summary
                Text(summary,
                    style: GoogleFonts.poppins(
                        fontSize: 13, height: 1.6, color: Colors.black87)),
                const SizedBox(height: 18),

                // Required Action box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _white,
                    border: Border.all(color: _black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: _black, offset: Offset(3, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("REQUIRED ACTION",
                          style: GoogleFonts.poppins(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: Colors.black54, letterSpacing: 1.2)),
                      const SizedBox(height: 5),
                      Text(action,
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: _black, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Activation button
                GestureDetector(
                  onTap: active ? null : () => _activateBtnPressed(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: brutalBox(
                      active ? _greenBtn : _black,
                      radius: 12, shadow: 4,
                    ),
                    child: active
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified, size: 20, color: _black),
                                  const SizedBox(width: 8),
                                  Text("PLAN ACTIVE",
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15, color: _black)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Activated on ${formatTimestamp(activatedAt)}",
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.black87,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rocket_launch, size: 18, color: _white),
                                const SizedBox(width: 8),
                                Text("ACTIVATE 7-DAY PLAN",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14, color: _white)),
                              ],
                            ),
                          ),
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

// ─── STRIP ITEM ───────────────────────────────────────────────────────────────
class _StripItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StripItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 8, fontWeight: FontWeight.w700,
                    color: Colors.black45, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900, fontSize: 12, color: _black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── PILL ROW ─────────────────────────────────────────────────────────────────
class _PillRow extends StatelessWidget {
  final String pillLabel, text;
  final Color pillColor;
  const _PillRow(
      {required this.pillLabel, required this.text, required this.pillColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: _black, width: 1.5),
          ),
          child: Text(pillLabel,
              style: const TextStyle(
                  color: _white, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _black,
                  fontWeight: FontWeight.w600, height: 1.3)),
        ),
      ],
    );
  }
}

// ─── SECTION TITLE ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: Colors.black38, letterSpacing: 2.5));
  }
}

// ─── AGENT CARD ───────────────────────────────────────────────────────────────
class _AgentCard extends StatefulWidget {
  final Map<String, dynamic> agent;
  const _AgentCard({required this.agent});

  @override
  State<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<_AgentCard> {
  bool _expanded = false;

  IconData _iconFor(String? id) {
    switch (id) {
      case 'performance_analyst': return FontAwesomeIcons.chartLine;
      case 'learning_strategist': return FontAwesomeIcons.bookOpen;
      case 'cognitive_coach':     return FontAwesomeIcons.brain;
      default:                    return FontAwesomeIcons.briefcase;
    }
  }

  Color _colorFor(String? id) {
    switch (id) {
      case 'performance_analyst': return const Color(0xFFE8F5E9);
      case 'learning_strategist': return _purple;
      case 'cognitive_coach':     return const Color(0xFFFFF3E0);
      default:                    return _white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id   = widget.agent['agentId']   as String?;
    final name = (widget.agent['agentName'] as String? ?? 'Agent').toUpperCase();
    final narrative = widget.agent['narrative'] as String? ?? '';
    final roleMap = {
      'performance_analyst': 'Data & metrics specialist',
      'learning_strategist': 'Study plan architect',
      'cognitive_coach':     'Mental performance advisor',
    };
    final role = roleMap[id] ?? 'AI Agent';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: brutalBox(_colorFor(id)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _black, width: 2),
                    ),
                    child: Center(
                      child: FaIcon(_iconFor(id), size: 16, color: _black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w900,
                                color: _black, letterSpacing: 0.3)),
                        Text(role,
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.black45,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: Colors.black38),
                  ),
                ],
              ),
            ),
            // Expanded body
            if (_expanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: _black.withOpacity(0.12), thickness: 1),
                    const SizedBox(height: 8),
                    Text(narrative,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black87,
                            height: 1.6, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
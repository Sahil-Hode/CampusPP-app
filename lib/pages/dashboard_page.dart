import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/student_model.dart'; // Keep for other sample data if needed
import '../models/performance_model.dart';
import '../services/student_service.dart';
import 'performance_analysis_page.dart';
import 'ai_analysis_page.dart';
import 'resume_upload_page.dart';
import 'profile_page.dart';
import 'ai_council_page.dart';
import 'chatbot_page.dart';
import '../widgets/attendance_card.dart';
import '../widgets/lms_engagement_card.dart';
import 'score_breakdown_page.dart';
import '../widgets/overall_score_card.dart';
import '../widgets/subject_marks_card.dart';
import 'learning_path_page.dart';
import 'interventions_page.dart';
import 'three_d_mentor_page.dart';
import '../widgets/quiz_score_card.dart';
import 'mock_interview_page.dart';
import '../widgets/quiz_overview_card.dart';
import '../services/quiz_service.dart';
import '../models/quiz_model.dart';
import 'ar_viewer_page.dart';
import 'vr_interview_page.dart';
import 'predictive_dashboard_page.dart';


import '../models/student_profile_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  OverviewData? _overviewData;
  CouncilDecisionData? _councilData;
  StudentProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  ImageProvider _buildAvatarImage() {
    final src = _profile?.avatarUrl ??
        'https://api.dicebear.com/7.x/avataaars/png?seed=Felix';
    if (src.startsWith('data:image')) {
      final base64Data = src.split(',').last;
      return MemoryImage(base64Decode(base64Data));
    }
    return NetworkImage(src);
  }

  Future<void> _refreshProfile() async {
    try {
      final profile = await StudentService.getFullStudentProfile();
      if (mounted) {
        setState(() => _profile = profile);
      }
    } catch (e) {
      print('Error refreshing profile: $e');
    }
  }

  Future<CouncilDecisionData?> _safeFetchCouncilData() async {
    try {
      return await StudentService.getCouncilData();
    } catch (e) {
      print('Failed to load council data: $e');
      return null;
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final results = await Future.wait([
        StudentService.getOverview(),
        _safeFetchCouncilData(),
        StudentService.getFullStudentProfile(),
      ]);

      if (mounted) {
        setState(() {
          _overviewData = results[0] as OverviewData;
          _councilData = results[1] as CouncilDecisionData?;
          _profile = results[2] as StudentProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  Future<void> _showRiskPopup() async {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Invisible backdrop
      builder: (context) {
        // Automatically close the dialog after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
        
        return Stack(
        children: [
          Positioned(
            top: 80, // Positioned near header
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (!_isLoading && ((_overviewData?.riskLevel ?? '').toLowerCase() == 'high' || 
                          (_overviewData?.riskLevel ?? '').toLowerCase() == 'critical' )) 
                          ? const Color(0xFFFFCDD2) 
                          : const Color(0xFFA8E6D5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _isLoading ? 'Loading...' : 'Risk: ${_overviewData?.riskLevel ?? "Safe"}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                           ((_overviewData?.riskLevel ?? '').toLowerCase() == 'high' || (_overviewData?.riskLevel ?? '').toLowerCase() == 'critical') 
                           ? Icons.warning : Icons.check,
                          size: 16,
                          color: ((_overviewData?.riskLevel ?? '').toLowerCase() == 'high' || (_overviewData?.riskLevel ?? '').toLowerCase() == 'critical') 
                           ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    Color riskColor = const Color(0xFFA8E6D5); // Default Safe (Mint)
    String riskText = 'Loading...';
    IconData riskIcon = Icons.hourglass_empty;
    Color riskIconColor = Colors.grey;

    if (!_isLoading && _overviewData != null) {
      String level = _overviewData?.riskLevel ?? 'Unknown';
      bool isHighRisk = level.toLowerCase() == 'high' || level.toLowerCase() == 'critical';

      if (isHighRisk) {
        riskColor = const Color(0xFFFFCDD2); // Red for High Risk
        riskText = 'Risk: $level';
        riskIcon = Icons.warning;
        riskIconColor = Colors.red;
      } else {
        riskColor = const Color(0xFFA8E6D5); // Mint for Safe
        riskText = 'Risk: ${level == "Unknown" ? "Safe" : level}';
        riskIcon = Icons.check;
        riskIconColor = Colors.green;
      }
    } else if (!_isLoading && _overviewData == null) {
       riskText = 'Risk: Unknown';
    }

    final pSum = _overviewData?.predictiveSummary;
    final alert = pSum?.smartAlert;

    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5), // Light mint/cyan background
      body: SafeArea(
        child: Column(
          children: [
            // Top section with avatar and status
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      ).then((result) {
                        if (mounted) {
                           _refreshProfile();
                        }
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        image: DecorationImage(
                          onError: (exception, stackTrace) {
                            print('Error loading avatar: $exception');
                          },
                          image: _buildAvatarImage(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Campus ++',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Keep header on one line: compact risk + chatbot
                  GestureDetector(
                    onTap: () {
                      _showRiskPopup();
                      _fetchDashboardData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: riskColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            riskIcon,
                            size: 14,
                            color: riskIconColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (_overviewData?.riskLevel ?? 'Safe').toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chatbot Button (Moved here)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatbotPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy, // Unique AI/Chatbot icon
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchDashboardData(),
                color: Colors.black,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (alert != null && alert.level != 'Safe')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (alert.level == 'Critical' || alert.level == 'High') 
                                ? const Color(0xFFFFCDD2) : const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.black, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${alert.level} Alert'.toUpperCase(), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                                  const SizedBox(height: 4),
                                  Text(alert.message.isNotEmpty ? alert.message : 'Action required', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      

                    // --- Stability & Risk card (separate) ---
                    if (pSum != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5CAE9), // Lavender
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.shield_outlined, size: 14),
                                      const SizedBox(width: 6),
                                      const Text('Stability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${pSum.stabilityScore}/100',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 26)),
                                  const SizedBox(height: 4),
                                  // Mini bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: pSum.stabilityScore / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.black12,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7986CB)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: pSum.failureProbability > 40
                                    ? const Color(0xFFFFCDD2)
                                    : const Color(0xFFA8E6CF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(pSum.failureProbability > 40 ? Icons.warning_amber_rounded : Icons.check_circle_outline, size: 14),
                                      const SizedBox(width: 6),
                                      const Text('Failure Risk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${pSum.failureProbability}%',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      color: pSum.failureProbability > 40 ? Colors.red[900] : Colors.black,
                                    )),
                                  const SizedBox(height: 4),
                                  // Trend badge
                                  Row(
                                    children: [
                                      Icon(pSum.trendDirection == 'Improving' ? Icons.trending_up : Icons.trending_down,
                                          size: 14, color: pSum.trendDirection == 'Improving' ? Colors.green[800] : Colors.red[800]),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text(pSum.trend, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Overall Performance Chart Card ---
                    if (_overviewData != null)
                      _buildPerformanceChartCard(),

                    const SizedBox(height: 16),

                    // --- AI Council Directive Card (Neobrutalist Verdict Style) ---
                    if (_councilData != null)
                      _buildCouncilCard()
                    else if (_isLoading)
                      const SizedBox.shrink(),


                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Row(
                      children: [
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('5', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.15,
                      children: [
                        _buildQuickActionButton(
                          context,
                          icon: Icons.view_in_ar,
                          label: '3D Mentor',
                          subtitle: 'Interactive VR',
                          color: const Color(0xFFB2F5EA),
                          iconBgColor: const Color(0xFF4DDBA0),
                          textColor: Colors.black,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ThreeDMentorPage())),
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.camera_alt_outlined,
                          label: 'AR Models',
                          subtitle: 'Explore in AR',
                          color: const Color(0xFFE8EAF6),
                          iconBgColor: const Color(0xFF7986CB),
                          textColor: Colors.black,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ARViewerPage())),
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.headset_mic_outlined,
                          label: 'VR Interview',
                          subtitle: 'Immersive',
                          color: const Color(0xFFF3E5F5),
                          iconBgColor: const Color(0xFF9C27B0),
                          textColor: Colors.black,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VRInterviewPage())),
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.forum_outlined,
                          label: 'Mock Interview',
                          subtitle: 'AI Practice',
                          color: const Color(0xFFFFE566),
                          iconBgColor: const Color(0xFFFFA726),
                          textColor: Colors.black,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MockInterviewPage())),
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.description_outlined,
                          label: 'Resume',
                          subtitle: 'AI Analyzer',
                          color: const Color(0xFFFFCDD2),
                          iconBgColor: const Color(0xFFE57373),
                          textColor: Colors.black,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeUploadPage())),
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.psychology_outlined,
                          label: 'Interventions',
                          subtitle: 'AI Coaching',
                          color: const Color(0xFFA8E6CF),
                          iconBgColor: const Color(0xFF2E7D55),
                          textColor: Colors.black,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InterventionsPage())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildNavItem(context, Icons.view_in_ar, '3D Mentor', false, is3DMentor: true)),
            Expanded(child: _buildNavItem(context, Icons.map, 'Learning Path', false, isPath: true)), 
            Expanded(child: _buildNavItem(context, Icons.home, 'Home', true)),
            Expanded(child: _buildNavItem(context, Icons.bar_chart, 'Performance', false, isProgress: true)),
            Expanded(child: _buildNavItem(context, Icons.gavel, 'AI Council', false)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChartCard() {
    final d = _overviewData!;
    final metrics = [
      {'label': 'Attendance', 'value': d.attendance.toDouble(), 'color': const Color(0xFFFFD54F)},
      {'label': 'Internals', 'value': d.internalMarks.toDouble(), 'color': const Color(0xFF7986CB)},
      {'label': 'Assignments', 'value': d.assignmentScore.toDouble(), 'color': const Color(0xFFFF8B94)},
      {'label': 'LMS', 'value': d.lmsEngagement.toDouble(), 'color': const Color(0xFF4DB6AC)},
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Performance',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: d.riskLevel.toLowerCase() == 'low'
                      ? const Color(0xFFA8E6CF)
                      : const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text('Risk: ${d.riskLevel}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.black12,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= metrics.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(metrics[idx]['label'] as String,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: metrics.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  final val = item['value'] as double;
                  final col = item['color'] as Color;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        width: 36,
                        color: col,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
                      '${rod.toY.toInt()}%',
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            children: metrics.map((m) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: m['color'] as Color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Text('${m['label']}: ${(m['value'] as double).toInt()}%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCouncilCard() {
  final c = _councilData!;
  
  // Define Urgency Color based on API value
  final urgencyColor = c.urgency.toLowerCase() == 'high'
      ? const Color(0xFFFF8B94) // Bold Red-ish
      : c.urgency.toLowerCase() == 'medium'
          ? const Color(0xFFFFD3B6) // Warm Orange
          : const Color(0xFFA8E6CF); // Mint Green

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black, width: 3), // Thicker border for Neo-Brutalism
      boxShadow: const [
        BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0) // Hard shadow
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- HEADER SECTION (No AI Icons) ---
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'AI COUNCIL\nDIRECTIVE',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    height: 1.0,
                    color: Colors.black,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              // URGENCY STATUS BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: urgencyColor,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    const Text('URGENCY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    Text(c.urgency.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- BOLD METRIC STRIP (Outlook & Focus) ---
        Container(
          decoration: const BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: Colors.black, width: 2.5)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // SYSTEM OUTLOOK
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFE8EAF6), // Neo-Lavender
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SYSTEM OUTLOOK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          (_overviewData?.predictiveSummary?.failureProbability ?? 0) > 40 ? 'CRITICAL' : 'STABLE',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 2.5, color: Colors.black),
                // FOCUS AREA
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFFFF9C4), // Neo-Yellow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FOCUS AREA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          c.priorityFocusArea.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- ANALYSIS & ACTION BODY ---
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TEXT PILL
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ('ANALYSIS: ' + c.riskSentence).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              // Main Narrative text
              Text(
                c.summary,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.5, color: Colors.black),
              ),
              const SizedBox(height: 20),
              // REQUIRED ACTION BOX (Indented Sticker Style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REQUIRED ACTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Text(
                      c.recommendedAction,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.4, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String subtitle = '',
    Color iconBgColor = Colors.white,
    Color textColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.15), width: 1.5),
              ),
              child: Icon(icon, color: Colors.black87, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textColor.withOpacity(0.65),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeuStatCard({required String title, required String value, required Color color, required IconData icon, bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: isAlert ? Colors.red[900] : Colors.black)),
        ],
      ),
    );
  }



  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, {bool isProgress = false, bool isPath = false, bool isChat = false, bool is3DMentor = false}) {
    return GestureDetector(
      onTap: () {
        if (isProgress) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PerformanceAnalysisPage(),
            ),
          );
        } else if (isPath) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LearningPathPage(), // Navigate to Learning Path
            ),
          );
        } else if (isChat) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChatbotPage(),
            ),
          );
        } else if (is3DMentor) {
           Navigator.of(context).push(
            MaterialPageRoute(
               builder: (context) => const ThreeDMentorPage(),
            ),
          );
        } else if (label == 'AI Council') {
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AiCouncilScreen(),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFA726) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


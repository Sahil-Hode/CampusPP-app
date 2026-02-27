import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student_model.dart'; // Keep for other sample data if needed
import '../models/performance_model.dart';
import '../services/student_service.dart';
import 'performance_analysis_page.dart';
import 'ai_analysis_page.dart';
import 'resume_upload_page.dart';
import 'profile_page.dart';
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


import '../models/student_profile_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  RiskData? _riskData;
  ScoreBreakdown? _scoreData;
  OverviewData? _overviewData;
  InterventionData? _interventionData;
  StudentProfile? _profile; // Added profile
  QuizOverviewSummary? _quizOverview;
  QuizScoreSummary? _quizScore;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiskData();
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

  Future<void> _fetchRiskData() async {
    try {
      // Fetch all data concurrently
      final results = await Future.wait([
        StudentService.getRiskStatus(),
        StudentService.getScoreBreakdown(),
        StudentService.getOverview(),
        StudentService.getIntervention(),
        StudentService.getFullStudentProfile(),
        QuizService.getOverviewSummary(),
        QuizService.getScoreSummary(),
      ]);

      if (mounted) {
        setState(() {
          _riskData = results[0] as RiskData;
          _scoreData = results[1] as ScoreBreakdown;
          _overviewData = results[2] as OverviewData;
          _interventionData = results[3] as InterventionData;
          _profile = results[4] as StudentProfile;
          _quizOverview = results[5] as QuizOverviewSummary;
          _quizScore = results[6] as QuizScoreSummary;
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
                    color: (!_isLoading && ((_riskData?.isAtRisk ?? false) || 
                          (_riskData?.riskLevel ?? '').toLowerCase() == 'high' || 
                          (_riskData?.riskLevel ?? '').toLowerCase() == 'critical' )) 
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
                          _isLoading ? 'Loading...' : 'Risk: ${_riskData?.riskLevel ?? _overviewData?.riskLevel ?? "Safe"}',
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
                          ((_riskData?.isAtRisk ?? false) || 
                           (_riskData?.riskLevel ?? '').toLowerCase() == 'high') 
                           ? Icons.warning : Icons.check,
                          size: 16,
                          color: ((_riskData?.isAtRisk ?? false) || 
                           (_riskData?.riskLevel ?? '').toLowerCase() == 'high') 
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
    // Keep sample data for other widgets for now as requested only Risk Status
    final attendance = DashboardData.getSampleAttendance();



    Color riskColor = const Color(0xFFA8E6D5); // Default Safe (Mint)
    String riskText = 'Loading...';
    IconData riskIcon = Icons.hourglass_empty;
    Color riskIconColor = Colors.grey;

    if (!_isLoading && (_riskData != null || _overviewData != null)) {
      String level = _riskData?.riskLevel ?? _overviewData?.riskLevel ?? 'Unknown';
      bool isHighRisk = (_riskData?.isAtRisk ?? false) || 
                        level.toLowerCase() == 'high' || 
                        level.toLowerCase() == 'critical';

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
    } else if (!_isLoading && _riskData == null && _overviewData == null) {
       riskText = 'Risk: Unknown';
    }

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
                      _fetchRiskData();
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
                            (_riskData?.riskLevel ?? _overviewData?.riskLevel ?? 'Safe').toUpperCase(),
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
                onRefresh: () => _fetchRiskData(),
                color: Colors.black,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Attendance and LMS Engagement Row
                    // LMS Engagement Card (Horizontal & Compact)
                    LMSEngagementCard(
                      engagementScore: _scoreData?.lmsEngagement ?? 0,
                    ),
                    const SizedBox(height: 16),
                    
                    // Attendance Card (Restored to normal size)
                    Row(
                      children: [
                        Expanded(
                          child: AttendanceCard(
                            title: 'Attendance',
                            value: '${(_scoreData?.attendance ?? 0) > 0 ? _scoreData!.attendance : (_overviewData?.attendance ?? 0)}%',
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: QuizScoreCard(
                            title: 'Quiz Score',
                            value: '${_quizScore?.overallScore ?? 0}%',
                            color: const Color(0xFFCE93D8), // Light purple
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_quizOverview != null) ...[
                      QuizOverviewCard(summary: _quizOverview!),
                      const SizedBox(height: 16),
                    ],

                    // Overall Score Card
                    OverallScoreCard(
                      overallScore: (_scoreData?.overallScore ?? 0) > 0 
                          ? _scoreData!.overallScore 
                          : (_overviewData?.overallScore ?? 0),
                      breakdown: _scoreData,
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.25,
                      children: [
                        _buildQuickActionButton(
                          context,
                          icon: Icons.view_in_ar,
                          label: '3D Mentor',
                          color: const Color(0xFFA8E6CF),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ThreeDMentorPage())),
                          useGridSizing: true,
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.camera_alt_outlined,
                          label: 'AR Models',
                          color: const Color(0xFFC5CAE9),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ARViewerPage())),
                          useGridSizing: true,
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.vrpano_outlined,
                          label: 'VR Interview',
                          color: const Color(0xFFE1BEE7),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VRInterviewPage())),
                          useGridSizing: true,
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.forum_outlined,
                          label: 'Mock Interview',
                          color: const Color(0xFFFFD3B6),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MockInterviewPage())),
                          useGridSizing: true,
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.description_outlined,
                          label: 'Resume Analyzer',
                          color: const Color(0xFFFF8B94),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeUploadPage())),
                          useGridSizing: true,
                        ),
                        _buildQuickActionButton(
                          context,
                          icon: Icons.psychology_outlined,
                          label: 'Interventions',
                          color: const Color(0xFFDCEDC1),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InterventionsPage())),
                          useGridSizing: true,
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
            Expanded(child: _buildNavItem(context, Icons.person_outline, 'Profile', false)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool useGridSizing = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: useGridSizing ? double.infinity : 100,
        margin: useGridSizing ? EdgeInsets.zero : const EdgeInsets.only(right: 16, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
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
        } else if (label == 'Profile') {
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
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

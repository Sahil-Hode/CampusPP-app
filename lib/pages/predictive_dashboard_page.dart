import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/student_service.dart';

class PredictiveDashboardPage extends StatefulWidget {
  const PredictiveDashboardPage({super.key});

  @override
  State<PredictiveDashboardPage> createState() => _PredictiveDashboardPageState();
}

class _PredictiveDashboardPageState extends State<PredictiveDashboardPage> {
  Map<String, dynamic>? _predictiveData;
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchPredictiveData();
  }

  Future<void> _fetchPredictiveData() async {
    try {
      final data = await StudentService.getPredictiveAnalysis();
      if (mounted) {
        setState(() {
          // The API returns the raw predictive map or wraps it inside `predictiveIntelligence` depending on backend implementation.
          // Since the prompt shows: Response: { predictiveIntelligence: { ... } } we handle both.
          _predictiveData = data['predictiveIntelligence'] ?? data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3), // Mint/Grey background for a tech feel
      appBar: AppBar(
        title: Text(
          'Predictive Intelligence',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _errorMsg.isNotEmpty
              ? Center(child: Text('Error: $_errorMsg\nPlease check backend connection.'))
              : _predictiveData == null
                  ? const Center(child: Text('No predictive data available.'))
                  : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    // Unpack all 6 layers
    final stability = _predictiveData!['academicStability'] ?? {};
    final trend = _predictiveData!['trendAnalysis'] ?? {};
    final riskBreakdown = _predictiveData!['riskBreakdown'] ?? {};
    final impact = _predictiveData!['impactSimulator'] ?? {};
    final actionPlanContainer = _predictiveData!['actionPlan'] ?? {}; // Sometimes `{actionPlan: {...}}`
    final actionPlan = actionPlanContainer['actionPlan'] ?? actionPlanContainer;
    final alertData = _predictiveData!['smartAlert'] ?? {};
    final alert = alertData['alert'] ?? alertData;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // L6: SMART ALERT SYSTEM (Show first if critical)
          if (alert.isNotEmpty && alert['level'] != 'Safe') ...[
             _buildSmartAlertBanner(alert),
             const SizedBox(height: 24),
          ],

          // L1: STABILITY & RISK
          Row(
            children: [
              Expanded(
                child: _buildNeuCard(
                  title: 'Stability Score',
                  child: Center(
                    child: Text(
                      '${stability['stabilityScore'] ?? 0}/100',
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ),
                  color: const Color(0xFFC5CAE9), // Light purple/blue
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNeuCard(
                  title: 'Failure Risk',
                  child: Center(
                    child: Text(
                      '${stability['finalRisk'] ?? 0}%',
                      style: GoogleFonts.poppins(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900,
                        color: ((stability['finalRisk'] ?? 0) > 40) ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                  color: const Color(0xFFFFD3B6), // Light Orange
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // L2: TREND INTELLIGENCE
          _buildNeuCard(
            title: 'Performance Trend',
            icon: Icons.trending_up,
            color: const Color(0xFFDCEDC1), // Light Mint
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      (trend['direction'] == 'Improving') ? Icons.arrow_upward :
                      (trend['direction'] == 'Declining') ? Icons.arrow_downward : Icons.swap_horiz,
                      size: 28,
                      color: (trend['direction'] == 'Improving') ? Colors.green :
                             (trend['direction'] == 'Declining') ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      trend['label'] ?? 'Stable Performance',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (trend['trendBreakdown'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.black, thickness: 1),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (trend['trendBreakdown'] as Map<String, dynamic>).entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),

          // L4: IMPACT SIMULATOR (What-If)
          _buildNeuCard(
            title: 'Impact Simulator (+10% Boost)',
            icon: Icons.batch_prediction,
            color: const Color(0xFFA8E6CF), // Cyan
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Strategy: ${impact['topRecommendation'] ?? 'Increase overall engagement'}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (impact['simulations'] != null)
                  ...(impact['simulations'] as List).take(3).map((sim) {
                    final newRisk = sim['newRisk'] ?? 0;
                    final oldRisk = impact['currentRisk'] ?? 0;
                    final drop = oldRisk - newRisk;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.insights, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'If ${sim['metric']} improves, risk drops by $drop%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Risk: $newRisk%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // L3: RISK BREAKDOWN (WHY)
          _buildNeuCard(
             title: 'Risk Breakdown',
             icon: Icons.search,
             color: const Color(0xFFFF8B94), // Pink/Red
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 if (riskBreakdown['primaryWeakness'] != null)
                   Text('🚨 Primary Weakness: ${riskBreakdown['primaryWeakness'].toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900)),
                 const SizedBox(height: 10),
                 if (riskBreakdown['reasons'] != null)
                   ...(riskBreakdown['reasons'] as List).map((r) => Padding(
                     padding: const EdgeInsets.only(bottom: 6),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('• ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                         Expanded(child: Text(r.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                       ],
                     ),
                   )),
               ],
             )
          ),
          const SizedBox(height: 20),

          // L5: 7-DAY ACTION PLAN
          if (actionPlan.isNotEmpty)
            _buildNeuCard(
               title: 'Auto 7-Day Plan: ${actionPlan['focusArea'] ?? 'General'}',
               icon: Icons.calendar_month,
               color: const Color(0xFFFDEB71), // Yellow
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   if (actionPlan['days'] != null)
                     ...(actionPlan['days'] as List).map((dayData) {
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           border: Border.all(color: Colors.black, width: 1.5),
                           borderRadius: BorderRadius.circular(12),
                           boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                         ),
                         child: Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(8),
                               decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                               child: Text('D${dayData['day']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(dayData['action'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                   Text('${dayData['duration']} mins', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                 ],
                               )
                             )
                           ],
                         ),
                       );
                     }),
                 ],
               )
            ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSmartAlertBanner(Map<String, dynamic> alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (alert['level'] == 'Critical' || alert['level'] == 'High') 
              ? const Color(0xFFFFCDD2) // Red
              : const Color(0xFFFFE0B2), // Orange
        borderRadius: BorderRadius.circular(16),
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
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert['level']} Alert'.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red[900]),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] ?? 'Immediate action required.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNeuCard({
    required String title,
    required Widget child,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Icon(icon, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

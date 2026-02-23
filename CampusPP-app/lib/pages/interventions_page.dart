import 'package:flutter/material.dart';
import '../models/performance_model.dart';
import '../services/student_service.dart';

class InterventionsPage extends StatefulWidget {
  const InterventionsPage({super.key});

  @override
  State<InterventionsPage> createState() => _InterventionsPageState();
}

class _InterventionsPageState extends State<InterventionsPage> {
  InterventionData? _data;
  bool _isLoading = true;
  // Track local completion status to allow immediate UI feedback
  final Set<String> _completedActionIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await StudentService.getIntervention();
      if (mounted) {
        setState(() { 
          _data = data; 
          _isLoading = false;
          // Initialize completed IDs from API
          if (data != null) {
            for (var action in data.actions) {
              if (action.status.toLowerCase() == 'completed') {
                _completedActionIds.add(action.id);
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsCompleted(String actionId) {
    if (_completedActionIds.contains(actionId)) return; // Already done

    setState(() {
      _completedActionIds.add(actionId);
    });
    
    // Todo: Call API to update status if provided in future
    // await StudentService.completeAction(actionId);
  }

  // ... (build method remains mostly same until _buildActionCard) ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Neutral background
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : Stack(
            children: [
              // Background Pattern
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF40FFA7).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Intervention Plan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_data == null)
                       const Center(child: Text('Failed to load data.'))
                    else
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildStatusCard(),
                            const SizedBox(height: 30),
                            if (_data!.actions.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Text('ACTION PLAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                                    child: Text('${_data!.actions.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                              ..._data!.actions.map((action) => _buildActionCard(action)),
                            ] else 
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Text("No actions assigned yet! 🎉", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                              )
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

  Widget _buildStatusCard() {
    // Calculate pending based on local state
    int completedCount = _data!.actions.where((a) => _completedActionIds.contains(a.id)).length;
    int pendingCount = _data!.actions.length - completedCount;
    
    // Determine priority (Simplified logic)
    bool isUrgent = _data!.interventionRequired && _data!.priority.toLowerCase() == 'high';
    
    // If all done, show green
    if (pendingCount == 0 && _data!.actions.isNotEmpty) {
        isUrgent = false;
    }

    Color bgColor = isUrgent ? const Color(0xFFFF8A80) : const Color(0xFF40FFA7);
    IconData icon = isUrgent ? Icons.medical_services_outlined : Icons.verified_user_outlined;
    String title = isUrgent ? 'ATTENTION NEEDED' : 'ON TRACK';
    
    if (pendingCount == 0 && _data!.actions.isNotEmpty) {
      title = 'ALL CAUGHT UP!';
      icon = Icons.celebration;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8), blurRadius: 0)],
      ),
      child: Column(
        children: [
          // Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    'Next Review: ${_data!.daysUntilReview}d',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATUS PRIORITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        pendingCount == 0 ? 'LOW' : _data!.priority.toUpperCase(), 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.0)
                      ),
                    ],
                  ),
                ),
                Container(
                   width: 60,
                   height: 60,
                   decoration: BoxDecoration(
                     color: Colors.white,
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.black, width: 2),
                   ),
                   child: Center(
                     child: Text('$pendingCount', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                   ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(InterventionAction action) {
    bool isDone = _completedActionIds.contains(action.id);
    
    return GestureDetector(
      onTap: () {
        if (!isDone) _markAsCompleted(action.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            // Card Layer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFF5F5F5) : Colors.white, // Dim if done
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDone ? Colors.grey : Colors.black, width: 2),
                boxShadow: isDone 
                    ? [] // No shadow if done
                    : const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF40FFA7) : Colors.transparent,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: isDone 
                            ? const Center(child: Icon(Icons.check, size: 16, color: Colors.black)) 
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                color: isDone ? Colors.grey : Colors.black,
                                decorationThickness: 3, // Thicker strike
                                decorationColor: Colors.black, // Visible strike
                                fontFamily: 'Roboto', // Ensure font consistency
                              ),
                              child: Text(action.title),
                            ),
                            if (action.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                action.description,
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: isDone ? Colors.grey[400] : Colors.black87
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Footer Tags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone ? Colors.grey[300] : const Color(0xFFFFF176),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDone ? Colors.grey : Colors.black, width: 1.5),
                        ),
                        child: Text(
                          isDone ? 'COMPLETED' : action.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            color: isDone ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

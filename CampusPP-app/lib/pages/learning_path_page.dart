import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../models/performance_model.dart';
import 'learning_path_detail_page.dart';
import '../widgets/analyzing_animation.dart';

class LearningPathPage extends StatefulWidget {
  const LearningPathPage({super.key});

  @override
  State<LearningPathPage> createState() => _LearningPathPageState();
}

class _LearningPathPageState extends State<LearningPathPage> {
  List<LearningPath>? _paths;
  bool _isLoading = true;
  bool _isGenerating = false;
  int _badgeCount = 0;
  List<String> _completedRoadmaps = [];

  @override
  void initState() {
    super.initState();
    _isGenerating = false;
    _fetchPaths();
  }

  Future<void> _fetchPaths() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final paths = await StudentService.getLearningPaths();
      if (mounted) {
        setState(() {
          _paths = paths;
          _isLoading = false;
          // Robust badge detection: Progress >= 90% or all steps completed
          final completed = paths.where((p) => p.progress >= 95 || p.steps.every((s) => s.status == 'completed')).toList();
          _badgeCount = completed.length;
          _completedRoadmaps = completed.map((p) => p.title).toList();
        });
      }
    } catch (e) {
      print('Error fetching paths: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePath() async {
    String? topic = await showDialog<String>(
      context: context,
      builder: (context) {
        String value = '';
        return AlertDialog(
          title: const Text('New Learning Goal'),
          content: TextField(
            onChanged: (v) => value = v,
            decoration: const InputDecoration(hintText: 'e.g. Physics, Python, History'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, value), child: const Text('Generate')),
          ],
        );
      },
    );

    if (topic != null && topic.isNotEmpty) {
      if (mounted) setState(() => _isGenerating = true);
      // Simulate "Generating" process for animation
      await Future.delayed(const Duration(seconds: 4)); 
      try {
        await StudentService.generateLearningPath(topic);
        await _fetchPaths(); 
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        await _fetchPaths();
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _deletePath(String id) async {
    try {
      await StudentService.deleteLearningPath(id);
      await _fetchPaths();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete(LearningPath path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(8, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCDD2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Roadmap?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${path.title}"? this action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePath(path.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text('My Learning Paths', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generatePath,
        label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isGenerating
        ? const AnalyzingAnimation(
            messages: [
              "Parsing Topic...",
              "Generating Roadmap...", 
              "Structuring Modules...",
              "Finalizing Path..."
            ],
          )
        : _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _paths == null || _paths!.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _paths!.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildPathCard(_paths![index]);
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No learning paths yet.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _generatePath,
            child: const Text('Create your first roadmap!'),
          ),
        ],
      ),
    );
  }

  Widget _buildPathCard(LearningPath path) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card Content
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LearningPathDetailPage(path: path),
              ),
            );
            _fetchPaths();
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(6, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Area with breathing room
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      path.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  path.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Progress Section
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: path.progress / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF40FFA7)),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${path.progress}%',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Unique Neobrutalist "Sticker" Delete Button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () => _confirmDelete(path),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8B94),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.delete_outline, color: Colors.black, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

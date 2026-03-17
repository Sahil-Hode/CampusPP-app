import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/feedback_service.dart';

/// Feature identifiers for feedback tagging
class FeedbackFeature {
  static const String mockInterview = 'mock_interview';
  static const String codeRunner = 'code_runner';
  static const String aiCouncil = 'ai_council';
  static const String threeDMentor = '3d_mentor';
}

/// Shows a feedback dialog at random intervals after feature usage.
/// Call this after a user completes a key action (e.g., ends an interview,
/// runs code, views AI council, or finishes a mentor session).
///
/// [context] - BuildContext
/// [feature] - One of [FeedbackFeature] constants
/// [featureDisplayName] - Human-readable name shown in the dialog
Future<void> maybeShowFeedbackDialog(
  BuildContext context, {
  required String feature,
  required String featureDisplayName,
  String? targetId,
}) async {
  final shouldShow = await FeedbackService.shouldShowFeedback();
  if (!shouldShow) return;
  if (!context.mounted) return;

  // Small delay so it doesn't feel jarring right after the action
  final delay = Duration(milliseconds: 800 + Random().nextInt(1200));
  await Future.delayed(delay);
  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _FeedbackDialog(
      feature: feature,
      featureDisplayName: featureDisplayName,
      targetId: targetId,
    ),
  );
}

class _FeedbackDialog extends StatefulWidget {
  final String feature;
  final String featureDisplayName;
  final String? targetId;

  const _FeedbackDialog({
    required this.feature,
    required this.featureDisplayName,
    this.targetId,
  });

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  static const _emojis = ['😤', '😕', '😐', '🙂', '🤩'];
  static const _labels = ['Awful', 'Poor', 'Okay', 'Good', 'Amazing'];
  static const _emojiColors = [
    Color(0xFFFF4D4D),
    Color(0xFFFF9F43),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D9FFF),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) return;
    setState(() => _submitting = true);

    try {
      await FeedbackService.submitFeedback(
        feature: widget.feature,
        rating: _selectedRating,
        comment: _commentCtrl.text.trim().isNotEmpty
            ? _commentCtrl.text.trim()
            : null,
        targetId: widget.targetId,
      );
      if (mounted) setState(() => _submitted = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(6, 6)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: _submitted ? _buildThankYou() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildThankYou() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(
          'THANKS!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your feedback helps us improve Campus++',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.close, size: 16),
            ),
          ),
        ),

        // Title
        Text(
          'HOW WAS IT?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AAFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Text(
            widget.featureDisplayName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Emoji rating row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final rating = i + 1;
            final isActive = _selectedRating == rating;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = rating),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 56 : 48,
                height: isActive ? 56 : 48,
                decoration: BoxDecoration(
                  color: isActive ? _emojiColors[i] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black,
                    width: isActive ? 3 : 2,
                  ),
                  boxShadow: isActive
                      ? [const BoxShadow(
                          color: Colors.black,
                          offset: Offset(3, 3),
                        )]
                      : [],
                ),
                child: Center(
                  child: Text(
                    _emojis[i],
                    style: TextStyle(fontSize: isActive ? 28 : 22),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Label for selected rating
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selectedRating > 0
              ? Text(
                  _labels[_selectedRating - 1],
                  key: ValueKey(_selectedRating),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _emojiColors[_selectedRating - 1],
                  ),
                )
              : const SizedBox(height: 20),
        ),
        const SizedBox(height: 16),

        // Optional comment
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: TextField(
            controller: _commentCtrl,
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Any thoughts? (optional)',
              hintStyle: GoogleFonts.poppins(
                color: Colors.black38,
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.all(12),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _selectedRating > 0 && !_submitting ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _selectedRating > 0 ? Colors.black : Colors.grey[300],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'SEND FEEDBACK',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

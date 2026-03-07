import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/code_runner_service.dart';
import 'github_oauth_page.dart';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/scala.dart';
import 'package:highlight/languages/lua.dart';
import 'package:highlight/languages/r.dart';
import 'package:highlight/languages/perl.dart';
import 'package:highlight/languages/sql.dart';

dynamic _getHighlightLang(String key) {
  switch (key) {
    case 'python3': return python;
    case 'nodejs': return javascript;
    case 'java': return java;
    case 'cpp17': return cpp;
    case 'c': return cpp;
    case 'csharp': return cs;
    case 'typescript': return typescript;
    case 'go': return go;
    case 'rust': return rust;
    case 'kotlin': return kotlin;
    case 'swift': return swift;
    case 'ruby': return ruby;
    case 'php': return php;
    case 'bash': return bash;
    case 'scala': return scala;
    case 'lua': return lua;
    case 'r': return r;
    case 'perl': return perl;
    case 'sql': return sql;
    default: return python;
  }
}

// ── IDE COLOUR PALETTE ──────────────────────────────────────────────────────
const _bg = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border = Color(0xFF30363D);
const _accent = Color(0xFF58A6FF);
const _accentGr = Color(0xFF3FB950);
const _accentRd = Color(0xFFF85149);
const _accentYl = Color(0xFFD29922);
const _text = Color(0xFFE6EDF3);
const _textMuted = Color(0xFF8B949E);
const _lineNum = Color(0xFF484F58);

// Language icon colours
const _langColors = {
  'python3': Color(0xFF3572A5),
  'nodejs': Color(0xFFF7DF1E),
  'java': Color(0xFFB07219),
  'cpp17': Color(0xFF00599C),
  'c': Color(0xFF555555),
  'csharp': Color(0xFF178600),
  'typescript': Color(0xFF3178C6),
  'go': Color(0xFF00ADD8),
  'rust': Color(0xFFDEA584),
  'kotlin': Color(0xFF7F52FF),
  'swift': Color(0xFFFA7343),
  'ruby': Color(0xFF701516),
  'php': Color(0xFF4F5D95),
  'bash': Color(0xFF89E051),
  'scala': Color(0xFFDC322F),
  'lua': Color(0xFF000080),
  'r': Color(0xFF198CE7),
  'perl': Color(0xFF0298C3),
  'sql': Color(0xFFE38C00),
};

// Default snippets per language
const _starterCode = {
  'python3':
      "# Python 3\nname = input('Enter name: ')\nprint(f'Hello, {name}!')\n",
  'nodejs':
      "// Node.js\nconst name = 'Campus++';\nconsole.log(`Hello, \${name}!`);\n",
  'java':
      "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, Campus++!\");\n    }\n}\n",
  'cpp17':
      "#include <iostream>\nusing namespace std;\n\nint main() {\n    cout << \"Hello, Campus++!\" << endl;\n    return 0;\n}\n",
  'c':
      "#include <stdio.h>\n\nint main() {\n    printf(\"Hello, Campus++!\\n\");\n    return 0;\n}\n",
  'csharp':
      "using System;\nclass Program {\n    static void Main() {\n        Console.WriteLine(\"Hello, Campus++!\");\n    }\n}\n",
  'typescript': "const msg: string = 'Hello, Campus++!';\nconsole.log(msg);\n",
  'go':
      "package main\nimport \"fmt\"\nfunc main() {\n    fmt.Println(\"Hello, Campus++!\")\n}\n",
  'rust': "fn main() {\n    println!(\"Hello, Campus++!\");\n}\n",
  'kotlin': "fun main() {\n    println(\"Hello, Campus++!\")\n}\n",
  'swift': "import Swift\nprint(\"Hello, Campus++!\")\n",
  'bash': "#!/bin/bash\necho \"Hello, Campus++!\"\n",
};

// ── EOF / "needs input" detection patterns ─────────────────────────────────
bool _needsMoreInput(String output) {
  final o = output.toLowerCase();
  return o.contains('eof') ||
      o.contains('end of input') ||
      o.contains('nosuchelementexception') ||
      o.contains('eoferror') ||
      o.contains('unexpected end') ||
      o.contains('stdin: eof');
}

class CodeRunnerPage extends StatefulWidget {
  const CodeRunnerPage({super.key});
  @override
  State<CodeRunnerPage> createState() => _CodeRunnerPageState();
}

class _CodeRunnerPageState extends State<CodeRunnerPage>
    with TickerProviderStateMixin {
  late CodeController _codeCtrl;
  final TextEditingController _terminalInput = TextEditingController();
  final TextEditingController _fileNameCtrl = TextEditingController();
  final ScrollController _terminalScroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  // GitHub state
  String? _githubToken;
  String? _githubUser;
  List<Map<String, dynamic>> _githubRepos = [];

  List<Map<String, dynamic>> _languages = [];
  Map<String, dynamic>? _selected;

  bool _loadingLangs = true;
  bool _running = false;
  bool _waitingForInput = false; // terminal is asking for input

  // Accumulated stdin across runs (newline separated)
  final List<String> _stdinLines = [];

  // Terminal display lines: each entry is {text, color, bold?}
  final List<_TermLine> _termLines = [];

  String _memory = '';
  String _cpuTime = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _codeCtrl = CodeController(
      text: '',
      language: python,
    );
    _fileNameCtrl.text = 'main.py';
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadLanguages();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _codeCtrl.dispose();
    _terminalInput.dispose();
    _fileNameCtrl.dispose();
    _terminalScroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── Language loading ───────────────────────────────────────────────────────
  Future<void> _loadLanguages() async {
    try {
      final langs = await CodeRunnerService.getLanguages();
      setState(() {
        _languages = langs;
        _loadingLangs = false;
        _selected = langs.firstWhere((l) => l['language'] == 'python3',
            orElse: () => langs.first);
        _codeCtrl.text = _starterCode[_selected!['language']] ?? '';
        _codeCtrl.language = _getHighlightLang(_selected!['language']);
        _fileNameCtrl.text = 'main${_selected!["ext"] ?? ".py"}';
      });
    } catch (e) {
      setState(() {
        _loadingLangs = false;
        _termLines.add(_TermLine('Error loading languages: $e', _accentRd));
      });
    }
  }

  void _selectLanguage(Map<String, dynamic> lang) {
    setState(() {
      _selected = lang;
      _codeCtrl.text = _starterCode[lang['language']] ?? '';
      _codeCtrl.language = _getHighlightLang(lang['language']);
      // Only update extension if user hasn't manually edited the name
      final ext = lang['ext'] as String? ?? '.py';
      if (_fileNameCtrl.text.isEmpty ||
          _fileNameCtrl.text == 'main${_selected?["ext"] ?? ".py"}') {
        _fileNameCtrl.text = 'main$ext';
      }
      _termLines.clear();
      _stdinLines.clear();
      _waitingForInput = false;
      _memory = '';
      _cpuTime = '';
    });
    Navigator.pop(context);
  }

  // ── Core run logic ─────────────────────────────────────────────────────────
  Future<void> _runCode() async {
    if (_codeCtrl.text.trim().isEmpty || _selected == null) return;
    HapticFeedback.lightImpact();

    // Fresh run: clear state
    setState(() {
      _running = true;
      _waitingForInput = false;
      _termLines.clear();
      _stdinLines.clear();
      _memory = '';
      _cpuTime = '';
    });

    _termLines.add(_TermLine(
        'Running ${_selected!['display']}...', _accentGr,
        bold: true));
    _termLines.add(_TermLine('', _textMuted)); // blank separator
    setState(() {});

    await _executeWithCurrentStdin();
  }

  /// Execute using whatever stdin we've accumulated so far.
  Future<void> _executeWithCurrentStdin() async {
    final stdin = _stdinLines.join('\n');
    try {
      final res = await CodeRunnerService.executeCode(
        language: _selected!['language'],
        code: _codeCtrl.text,
        stdin: stdin,
      );

      final raw = (res['output'] ?? '').toString();
      _memory = res['memory']?.toString() ?? '';
      _cpuTime = res['cpuTime']?.toString() ?? '';

      final needsInput = _needsMoreInput(raw);

      if (needsInput) {
        // ── Only show clean stdout (everything BEFORE the traceback) ──────
        // JDoodle appends the traceback after the program's partial output:
        //   "Enter name: \n  File ...\n    name = input(...)\nEOFError: ..."
        // We split on the first occurrence of any traceback marker.
        String cleanOutput = raw;
        for (final marker in [
          '\nTraceback',
          '\n  File "',
          '\nEOFError',
          '\nException'
        ]) {
          final idx = cleanOutput.indexOf(marker);
          if (idx != -1 && idx < cleanOutput.length) {
            cleanOutput = cleanOutput.substring(0, idx);
            break;
          }
        }
        cleanOutput = cleanOutput.trimRight();

        for (final line in cleanOutput.split('\n')) {
          _termLines.add(_TermLine(line, _text));
        }

        setState(() {
          _running = false;
          _waitingForInput = true;
        });
        _scrollTerminal();
        Future.delayed(const Duration(milliseconds: 200), () {
          _inputFocus.requestFocus();
        });
      } else {
        // ── Normal completion ─────────────────────────────────────────────
        final trimmed = raw.trimRight();
        final hasError = trimmed.toLowerCase().contains('traceback') ||
            trimmed.toLowerCase().contains('exception in thread') ||
            trimmed.toLowerCase().contains('error:');

        for (final line in trimmed.split('\n')) {
          _termLines.add(_TermLine(line, hasError ? _accentRd : _text));
        }
        _termLines.add(_TermLine('', _textMuted));
        _termLines.add(_TermLine(
          hasError
              ? 'Process exited with error'
              : 'Process exited with code 0   ⏱ ${_cpuTime}s   💾 ${_memory}KB',
          hasError ? _accentRd : _accentGr,
          bold: true,
        ));
        setState(() {
          _running = false;
          _waitingForInput = false;
          if (_cpuTime.isEmpty) _cpuTime = res['cpuTime']?.toString() ?? '';
          if (_memory.isEmpty) _memory = res['memory']?.toString() ?? '';
        });
        _scrollTerminal();

        // ++ AUTO DEBUG FLOW ++ //
        if (hasError) {
          _triggerAutoDebug(trimmed);
        }
      }
    } catch (e) {
    _termLines.add(_TermLine(
          e.toString().replaceFirst('Exception:', '').trim(), _accentRd));
      _termLines.add(_TermLine('Execution failed', _accentRd, bold: true));
      setState(() {
        _running = false;
        _waitingForInput = false;
      });
      _scrollTerminal();
    }
  }

  /// Called when user submits input from the terminal input bar.
  Future<void> _submitInput() async {
    if (!_waitingForInput) return;
    final val = _terminalInput.text;
    _terminalInput.clear();

    // Echo user input in terminal like a real shell
    _termLines.add(_TermLine('$val', _accent));

    // Accumulate
    _stdinLines.add(val);

    setState(() {
      _running = true;
      _waitingForInput = false;
    });

    // Re-run with all stdin so far
    await _executeWithCurrentStdin();
  }

  void _addTerminalInfo(String text) {
    setState(() => _termLines.add(_TermLine(text, _accent, bold: true)));
    _scrollTerminal();
  }

  void _addTerminalError(String text) {
    setState(() => _termLines.add(_TermLine(text, _accentRd, bold: true)));
    _scrollTerminal();
  }

  void _showAIModal(String title, String content, {String? newCode}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: _accent, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.jetBrainsMono(
                    color: _accent, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(content,
                style: GoogleFonts.jetBrainsMono(
                    color: _text, fontSize: 13, height: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.jetBrainsMono(color: _textMuted)),
          ),
          if (newCode != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accentGr),
              onPressed: () {
                setState(() {
                  _codeCtrl.text = newCode;
                });
                Navigator.pop(ctx);
              },
              child: Text('Accept Code',
                  style: GoogleFonts.jetBrainsMono(
                      color: _bg, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Future<void> _explainCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    _addTerminalInfo('Asking AI to explain code...');
    try {
      final res = await CodeRunnerService.explainCode(
          code: _codeCtrl.text, language: _selected?['language']);
      _showAIModal(
          'Explain Code', res['explanation'] ?? 'No explanation generated.');
      _addTerminalInfo('AI Explanation ready.');
    } catch (e) {
      _addTerminalError('AI Explain failed: $e');
    }
  }

  Future<void> _debugCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    _addTerminalInfo('Asking AI to debug code...');
    try {
      final res = await CodeRunnerService.debugCode(
          code: _codeCtrl.text, language: _selected?['language']);
      final sugg = res['suggestion'];
      if (sugg != null) {
        final exp = sugg['explanation'] ?? '';
        final fixed = sugg['fixed'];
        _showAIModal('Debug Code', 'Explanation:\n$exp\n\nCode Fix:\n$fixed',
            newCode: fixed);
      } else {
        _showAIModal('Debug Code', 'No bugs found or no suggestion provided.');
      }
      _addTerminalInfo('AI Debug ready.');
    } catch (e) {
      _addTerminalError('AI Debug failed: $e');
    }
  }

  Future<void> _reviewCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    _addTerminalInfo('Asking AI to review code...');
    try {
      final res = await CodeRunnerService.reviewCode(
          code: _codeCtrl.text, language: _selected?['language']);
      _showAIModal('Code Review', res['review'] ?? 'No review generated.');
      _addTerminalInfo('AI Review ready.');
    } catch (e) {
      _addTerminalError('AI Review failed: $e');
    }
  }

  Future<void> _improveCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    _addTerminalInfo('Asking AI to improve code...');
    try {
      final res = await CodeRunnerService.improveCode(
          code: _codeCtrl.text, language: _selected?['language']);
      _showAIModal('Improve Code',
          '${res['explanation']}\n\nImproved Code:\n${res['improved']}',
          newCode: res['improved']);
      _addTerminalInfo('AI Improvement ready.');
    } catch (e) {
      _addTerminalError('AI Improve failed: $e');
    }
  }

  Future<void> _generateChallenge() async {
    _addTerminalInfo('Generating a coding challenge...');
    try {
      final res = await CodeRunnerService.generateChallenge(
          language: _selected?['language'], difficulty: 'medium');
      final title = res['title'] ?? 'Challenge';
      final prob = res['problem'] ?? '';
      final exp =
          '${res['difficulty']?.toString().toUpperCase()} - $title\n\n$prob';
      _showAIModal('Practice Challenge', exp);
      _addTerminalInfo('AI Challenge ready.');
    } catch (e) {
      _addTerminalError('AI Challenge failed: $e');
    }
  }

  Future<void> _triggerAutoDebug(String errorText) async {
    _addTerminalInfo('Auto-analyzing error with AI...');
    try {
      final res = await CodeRunnerService.explainAndDebugCode(
          code: _codeCtrl.text,
          error: errorText,
          language: _selected?['language']);
      final exp = res['errorExplanation'] ?? '';
      final sugg = res['suggestion'];
      if (sugg != null) {
        final fixed = sugg['fixed'];
        final suggExp = sugg['explanation'] ?? '';
        _showAIModal('Auto Error Analysis',
            '$exp\n\nSuggested Fix:\n$suggExp\n\nCode:\n$fixed',
            newCode: fixed);
      } else {
        _showAIModal('Auto Error Analysis', exp);
      }
      _addTerminalInfo('AI Analysis ready.');
    } catch (e) {
      _addTerminalError('Auto AI Debug failed: $e');
    }
  }

  void _scrollTerminal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScroll.hasClients) {
        _terminalScroll.animateTo(
          _terminalScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Language picker ────────────────────────────────────────────────────────
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Select Language',
                  style: GoogleFonts.jetBrainsMono(
                      color: _text, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: _languages.length,
                itemBuilder: (_, i) {
                  final lang = _languages[i];
                  final isSelected = lang['language'] == _selected?['language'];
                  final dotColor = _langColors[lang['language']] ?? _accent;
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: dotColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: dotColor.withAlpha(80), width: 1.5),
                      ),
                      child: Center(
                        child: Text(lang['ext'] ?? '',
                            style: GoogleFonts.jetBrainsMono(
                                color: dotColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    title: Text(lang['display'] ?? '',
                        style: GoogleFonts.jetBrainsMono(
                            color: isSelected ? _accent : _text,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    subtitle: Text(lang['language'] ?? '',
                        style: GoogleFonts.jetBrainsMono(
                            color: _textMuted, fontSize: 11)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: _accentGr, size: 20)
                        : null,
                    tileColor:
                        isSelected ? _accent.withAlpha(15) : Colors.transparent,
                    onTap: () => _selectLanguage(lang),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rename file dialog ─────────────────────────────────────────────────────
  void _showRenameDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Rename File',
            style: GoogleFonts.jetBrainsMono(
                color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _fileNameCtrl,
          autofocus: true,
          style: GoogleFonts.jetBrainsMono(color: _text),
          decoration: InputDecoration(
            hintText: 'Enter file name',
            hintStyle: GoogleFonts.jetBrainsMono(color: _textMuted),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _border)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _accent)),
          ),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.jetBrainsMono(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentGr),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Rename',
                style: GoogleFonts.jetBrainsMono(
                    color: _bg, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── GitHub sheet ────────────────────────────────────────────────────────────
  void _showGithubSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.code_rounded,
                      color: Color(0xFFB39DDB), size: 22),
                  const SizedBox(width: 10),
                  Text('GitHub Integration',
                      style: GoogleFonts.jetBrainsMono(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              if (_githubToken == null) ...[
                Text(
                  'Connect your GitHub account to push code directly from the Campus++ IDE.',
                  style:
                      GoogleFonts.jetBrainsMono(color: _textMuted, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E40C9),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _launchGithubOAuth();
                    },
                    icon: const Icon(Icons.link, color: Colors.white),
                    label: Text('Connect to GitHub',
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5016),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accentGr.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: _accentGr, size: 20),
                      const SizedBox(width: 10),
                      Text('Connected as ${_githubUser ?? 'GitHub User'}',
                          style: GoogleFonts.jetBrainsMono(
                              color: _accentGr, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGr,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _pushCodeToGithub();
                    },
                    icon: const Icon(Icons.cloud_upload, color: _bg),
                    label: Text('Push Code to GitHub',
                        style: GoogleFonts.jetBrainsMono(
                            color: _bg,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _githubToken = null;
                        _githubUser = null;
                        _githubRepos = [];
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Disconnected from GitHub.',
                              style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                          backgroundColor: _accentRd,
                          duration: const Duration(seconds: 2)));
                    },
                    child: Text('Disconnect',
                        style: GoogleFonts.jetBrainsMono(color: _textMuted)),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Real OAuth: open in-app WebView and capture token
  Future<void> _launchGithubOAuth() async {
    final authUrl =
        'https://campuspp-f7qx.onrender.com/auth/github'
        '?fileName=${Uri.encodeComponent(_fileNameCtrl.text)}'
        '&language=${Uri.encodeComponent(_selected?['language'] ?? 'python3')}'
        '&returnUrl=/code-ide';

    final result = await Navigator.push<GithubAuthResult?>(
      context,
      MaterialPageRoute(
        builder: (_) => GithubOAuthPage(authUrl: authUrl),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _githubToken = result.token;
        _githubUser = result.username;
      });
      _addTerminalInfo('GitHub connected as ${result.username}.');
      // Pre-load repos in background
      _loadGithubRepos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connected as ${result.username}!',
              style: GoogleFonts.jetBrainsMono(fontSize: 12)),
          backgroundColor: _accentGr,
          duration: const Duration(seconds: 2)));
    }
  }

  // Load repos list
  Future<void> _loadGithubRepos() async {
    if (_githubToken == null) return;
    try {
      final repos = await CodeRunnerService.listGithubRepos(
          token: _githubToken!);
      if (mounted) {
        setState(() => _githubRepos = repos);
      }
    } catch (_) {}
  }

  // Push code — shows repo picker first
  Future<void> _pushCodeToGithub() async {
    if (_githubToken == null || _codeCtrl.text.trim().isEmpty) return;

    // Load repos if not already loaded
    if (_githubRepos.isEmpty) {
      _addTerminalInfo('Loading your repositories...');
      await _loadGithubRepos();
    }

    if (!mounted) return;

    // Show repo picker dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _GithubPushDialog(
        repos: _githubRepos,
        fileName: _fileNameCtrl.text,
        onPush: (repo, fileName, commitMsg) async {
          Navigator.pop(ctx);
          await _doPush(repo, fileName, commitMsg);
        },
        onCreateRepo: (repoName) async {
          Navigator.pop(ctx);
          await _createAndPush(repoName);
        },
      ),
    );
  }

  Future<void> _doPush(
      String repo, String fileName, String? commitMsg) async {
    _addTerminalInfo('Pushing $fileName to $repo...');
    try {
      final result = await CodeRunnerService.pushToGithub(
        token: _githubToken!,
        repo: repo,
        fileName: fileName,
        code: _codeCtrl.text,
        message: commitMsg,
      );
      final fileUrl = result['file']?['html_url'] as String?;
      _addTerminalInfo('Pushed! ${fileUrl ?? repo}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pushed to $repo!',
              style: GoogleFonts.jetBrainsMono(fontSize: 12)),
          backgroundColor: _accentGr,
          duration: const Duration(seconds: 3)));
    } catch (e) {
      _addTerminalError('GitHub push failed: $e');
    }
  }

  Future<void> _createAndPush(String repoName) async {
    _addTerminalInfo('Creating repo $repoName...');
    try {
      final repo = await CodeRunnerService.createGithubRepo(
          token: _githubToken!, name: repoName);
      final fullName = repo['full_name'] as String;
      _addTerminalInfo('Repo created: $fullName');
      await _doPush(fullName, _fileNameCtrl.text, null);
    } catch (e) {
      _addTerminalError('Repo creation failed: $e');
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: _bg),
      child: Scaffold(
        backgroundColor: _bg,
        body: _loadingLangs
            ? _buildSplash()
            : Column(
                children: [
                  _buildTopBar(),
                  _buildEditorToolbar(),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(flex: 6, child: _buildCodeEditor()),
                        _buildDivider(),
                        Expanded(flex: 4, child: _buildTerminalPanel()),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── SPLASH ─────────────────────────────────────────────────────────────────
  Widget _buildSplash() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code, color: _accent, size: 48),
          const SizedBox(height: 16),
          Text('Loading runtimes...',
              style:
                  GoogleFonts.jetBrainsMono(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 20),
          const SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                  color: _accent, backgroundColor: _surface)),
        ],
      ),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final dotColor = _langColors[_selected?['language']] ?? _accent;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          _iconBtn(Icons.arrow_back_ios_new,
              onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          // ── Editable file name ──
          Expanded(
            child: GestureDetector(
              onTap: () => _showRenameDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dotColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: dotColor.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: dotColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _fileNameCtrl.text.isEmpty
                            ? 'main${_selected?["ext"] ?? ".py"}'
                            : _fileNameCtrl.text,
                        style: GoogleFonts.jetBrainsMono(
                            color: _text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, color: _textMuted, size: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── GitHub push button ──
          GestureDetector(
            onTap: _showGithubSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _githubToken != null
                    ? const Color(0xFF2D5016)
                    : _surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _githubToken != null
                        ? _accentGr
                        : const Color(0xFF6E40C9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.code_rounded,
                    color: _githubToken != null
                        ? _accentGr
                        : const Color(0xFFB39DDB),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      _githubToken != null
                          ? (_githubUser ?? 'GitHub')
                          : 'GitHub',
                      style: GoogleFonts.jetBrainsMono(
                          color: _githubToken != null
                              ? _accentGr
                              : const Color(0xFFB39DDB),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _showLanguagePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selected?['display'] ?? 'Language',
                      style:
                          GoogleFonts.jetBrainsMono(color: _textMuted, fontSize: 12)),
                  const SizedBox(width: 6),
                  const Icon(Icons.unfold_more, color: _textMuted, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── EDITOR TOOLBAR ─────────────────────────────────────────────────────────
  Widget _buildEditorToolbar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          _tabLabel('EDITOR'),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome, color: _accent, size: 18),
            color: _surface,
            tooltip: 'AI Tools',
            onSelected: (val) {
              if (val == 'explain') _explainCode();
              if (val == 'debug') _debugCode();
              if (val == 'review') _reviewCode();
              if (val == 'improve') _improveCode();
              if (val == 'challenge') _generateChallenge();
            },
            itemBuilder: (context) => [
              _buildAiMenuItem(
                  'explain', Icons.lightbulb_outline, 'Explain Code'),
              _buildAiMenuItem(
                  'debug', Icons.bug_report_outlined, 'Debug Code'),
              _buildAiMenuItem(
                  'review', Icons.rate_review_outlined, 'Review Code'),
              _buildAiMenuItem('improve', Icons.auto_fix_high, 'Improve Code'),
              _buildAiMenuItem(
                  'challenge', Icons.extension, 'Practice Challenge'),
            ],
          ),
          const SizedBox(width: 6),
          _iconBtn(Icons.delete_outline, size: 16, tooltip: 'Clear',
              onPressed: () {
            setState(() {
              _codeCtrl.text = '';
            });
          }),
          const SizedBox(width: 6),
          _iconBtn(Icons.copy_outlined, size: 16, tooltip: 'Copy',
              onPressed: () {
            Clipboard.setData(ClipboardData(text: _codeCtrl.text));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Code copied!',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                backgroundColor: _surface,
                duration: const Duration(seconds: 1)));
          }),
        ],
      ),
    );
  }

  // ── CODE EDITOR ────────────────────────────────────────────────────────────
  Widget _buildCodeEditor() {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: CodeField(
        controller: _codeCtrl,
        textStyle: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.6),
        background: _bg,
        lineNumberStyle: LineNumberStyle(
          textStyle: GoogleFonts.jetBrainsMono(
              fontSize: 12, color: _lineNum, height: 1.6),
          background: _surface,
          width: 52,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ── DIVIDER & RUN BUTTON ───────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _surface,
        border: const Border.symmetric(horizontal: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          _tabLabel('TERMINAL', icon: Icons.terminal),
          if (_cpuTime.isNotEmpty) ...[
            const SizedBox(width: 12),
            _statPill('⏱ ${_cpuTime}s', _accentGr),
            const SizedBox(width: 6),
            _statPill('💾 ${_memory}KB', _accent),
          ],
          const Spacer(),
          // Clear terminal
          _iconBtn(
            Icons.cleaning_services_outlined,
            size: 15,
            tooltip: 'Clear terminal',
            onPressed: () => setState(() {
              _termLines.clear();
              _stdinLines.clear();
              _waitingForInput = false;
              _memory = '';
              _cpuTime = '';
            }),
          ),
          // RUN BUTTON
          GestureDetector(
            onTap: (_running || _waitingForInput) ? null : _runCode,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                  scale: _running ? _pulseAnim.value : 1.0, child: child),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: _running ? _accentGr.withAlpha(40) : _accentGr,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _running
                      ? []
                      : [
                          BoxShadow(
                              color: _accentGr.withAlpha(80), blurRadius: 10)
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_running)
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: _accentGr, strokeWidth: 2))
                    else
                      const Icon(Icons.play_arrow, color: _bg, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _running ? 'Running...' : 'Run',
                      style: GoogleFonts.jetBrainsMono(
                          color: _running ? _accentGr : _bg,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TERMINAL PANEL ─────────────────────────────────────────────────────────
  Widget _buildTerminalPanel() {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_running)
            LinearProgressIndicator(
                color: _accentGr, backgroundColor: _surface, minHeight: 2),

          // Output lines
          Expanded(
            child: _termLines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terminal, color: _lineNum, size: 36),
                        const SizedBox(height: 10),
                        Text('Run your code to see output here.',
                            style: GoogleFonts.jetBrainsMono(
                                color: _lineNum, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _terminalScroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    itemCount: _termLines.length,
                    itemBuilder: (_, i) {
                      final line = _termLines[i];
                      return Text(
                        line.text,
                        style: GoogleFonts.jetBrainsMono(
                          color: line.color,
                          fontSize: 13,
                          height: 1.6,
                          fontWeight:
                              line.bold ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    },
                  ),
          ),

          // ── INTERACTIVE INPUT BAR (shown only when program asks for input) ──
          if (_waitingForInput)
            Container(
              decoration: BoxDecoration(
                color: _surface,
                border: Border(
                  top: BorderSide(color: _accentYl.withAlpha(120), width: 2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text('›',
                      style: GoogleFonts.jetBrainsMono(
                          color: _accentYl,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _terminalInput,
                      focusNode: _inputFocus,
                      style:
                          GoogleFonts.jetBrainsMono(color: _text, fontSize: 14),
                      cursorColor: _accentYl,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Enter input and press ↵',
                        hintStyle: GoogleFonts.jetBrainsMono(
                            color: _lineNum, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _submitInput(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  GestureDetector(
                    onTap: _submitInput,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accentYl,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('↵ Send',
                          style: GoogleFonts.jetBrainsMono(
                              color: _bg,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _tabLabel(String label, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: _textMuted, size: 13),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: GoogleFonts.jetBrainsMono(
                color: _textMuted, fontSize: 10, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _statPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: GoogleFonts.jetBrainsMono(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _iconBtn(IconData icon,
      {double size = 18, String? tooltip, required VoidCallback onPressed}) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: _textMuted, size: size)),
      ),
    );
  }

  PopupMenuItem<String> _buildAiMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.jetBrainsMono(color: _text, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Terminal line model ────────────────────────────────────────────────────
class _TermLine {
  final String text;
  final Color color;
  final bool bold;
  const _TermLine(this.text, this.color, {this.bold = false});
}

// ── GitHub Push Dialog ─────────────────────────────────────────────────────
class _GithubPushDialog extends StatefulWidget {
  final List<Map<String, dynamic>> repos;
  final String fileName;
  final Future<void> Function(String repo, String fileName, String? commitMsg)
      onPush;
  final Future<void> Function(String repoName) onCreateRepo;

  const _GithubPushDialog({
    required this.repos,
    required this.fileName,
    required this.onPush,
    required this.onCreateRepo,
  });

  @override
  State<_GithubPushDialog> createState() => _GithubPushDialogState();
}

class _GithubPushDialogState extends State<_GithubPushDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedRepo;
  final _fileNameCtrl = TextEditingController();
  final _commitCtrl = TextEditingController();
  final _newRepoCtrl = TextEditingController();
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fileNameCtrl.text = widget.fileName;
    _commitCtrl.text = 'Update ${widget.fileName} via Campus++ IDE';
    if (widget.repos.isNotEmpty) {
      _selectedRepo = widget.repos.first['full_name'] as String?;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fileNameCtrl.dispose();
    _commitCtrl.dispose();
    _newRepoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload, color: _accentGr, size: 22),
                const SizedBox(width: 10),
                Text('Push to GitHub',
                    style: GoogleFonts.jetBrainsMono(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: _textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabCtrl,
            labelColor: _accent,
            unselectedLabelColor: _textMuted,
            indicatorColor: _accent,
            labelStyle: GoogleFonts.jetBrainsMono(fontSize: 12),
            tabs: const [Tab(text: 'EXISTING REPO'), Tab(text: 'NEW REPO')],
          ),
          // Tab content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Existing repo ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select repository',
                          style: GoogleFonts.jetBrainsMono(
                              color: _textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _border),
                        ),
                        child: widget.repos.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('No repositories found',
                                    style: GoogleFonts.jetBrainsMono(
                                        color: _textMuted, fontSize: 12)),
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRepo,
                                  isExpanded: true,
                                  dropdownColor: _surface,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  style: GoogleFonts.jetBrainsMono(
                                      color: _text, fontSize: 13),
                                  items: widget.repos
                                      .map((r) => DropdownMenuItem<String>(
                                            value:
                                                r['full_name'] as String?,
                                            child: Text(
                                                r['full_name'] as String? ??
                                                    '',
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedRepo = v),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text('File name',
                          style: GoogleFonts.jetBrainsMono(
                              color: _textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      _field(_fileNameCtrl, 'main.py'),
                      const SizedBox(height: 12),
                      Text('Commit message',
                          style: GoogleFonts.jetBrainsMono(
                              color: _textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      _field(_commitCtrl, 'Update via Campus++ IDE'),
                    ],
                  ),
                ),
                // ── New repo ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Repository name',
                          style: GoogleFonts.jetBrainsMono(
                              color: _textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      _field(_newRepoCtrl, 'my-campus-solutions'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Switch(
                            value: _isPrivate,
                            onChanged: (v) =>
                                setState(() => _isPrivate = v),
                            activeThumbColor: _accent,
                          ),
                          const SizedBox(width: 8),
                          Text('Private repository',
                              style: GoogleFonts.jetBrainsMono(
                                  color: _text, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A new repo will be created and your current code will be pushed as the first commit.',
                        style: GoogleFonts.jetBrainsMono(
                            color: _textMuted, fontSize: 11, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style:
                            GoogleFonts.jetBrainsMono(color: _textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGr,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (_tabCtrl.index == 0) {
                        // Push to existing repo
                        if (_selectedRepo == null) return;
                        widget.onPush(
                          _selectedRepo!,
                          _fileNameCtrl.text,
                          _commitCtrl.text.isEmpty ? null : _commitCtrl.text,
                        );
                      } else {
                        // Create new repo
                        final name = _newRepoCtrl.text.trim();
                        if (name.isEmpty) return;
                        widget.onCreateRepo(name);
                      }
                    },
                    icon: const Icon(Icons.cloud_upload, color: _bg, size: 18),
                    label: Text(
                        _tabCtrl.index == 0
                            ? 'Push Code'
                            : 'Create & Push',
                        style: GoogleFonts.jetBrainsMono(
                            color: _bg, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.jetBrainsMono(color: _text, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: _bg,
        hintText: hint,
        hintStyle: GoogleFonts.jetBrainsMono(color: _lineNum, fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: _accent)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

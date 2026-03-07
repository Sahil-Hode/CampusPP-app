import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/code_runner_service.dart';

// ── IDE COLOUR PALETTE ──────────────────────────────────────────────────────
const _bg       = Color(0xFF0D1117);
const _surface  = Color(0xFF161B22);
const _border   = Color(0xFF30363D);
const _accent   = Color(0xFF58A6FF);
const _accentGr = Color(0xFF3FB950);
const _accentRd = Color(0xFFF85149);
const _accentYl = Color(0xFFD29922);
const _text     = Color(0xFFE6EDF3);
const _textMuted= Color(0xFF8B949E);
const _lineNum  = Color(0xFF484F58);

// Language icon colours
const _langColors = {
  'python3':    Color(0xFF3572A5),
  'nodejs':     Color(0xFFF7DF1E),
  'java':       Color(0xFFB07219),
  'cpp17':      Color(0xFF00599C),
  'c':          Color(0xFF555555),
  'csharp':     Color(0xFF178600),
  'typescript': Color(0xFF3178C6),
  'go':         Color(0xFF00ADD8),
  'rust':       Color(0xFFDEA584),
  'kotlin':     Color(0xFF7F52FF),
  'swift':      Color(0xFFFA7343),
  'ruby':       Color(0xFF701516),
  'php':        Color(0xFF4F5D95),
  'bash':       Color(0xFF89E051),
  'scala':      Color(0xFFDC322F),
  'lua':        Color(0xFF000080),
  'r':          Color(0xFF198CE7),
  'perl':       Color(0xFF0298C3),
  'sql':        Color(0xFFE38C00),
};

// Default snippets per language
const _starterCode = {
  'python3':    "# Python 3\nname = input('Enter name: ')\nprint(f'Hello, {name}!')\n",
  'nodejs':     "// Node.js\nconst name = 'Campus++';\nconsole.log(`Hello, \${name}!`);\n",
  'java':       "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, Campus++!\");\n    }\n}\n",
  'cpp17':      "#include <iostream>\nusing namespace std;\n\nint main() {\n    cout << \"Hello, Campus++!\" << endl;\n    return 0;\n}\n",
  'c':          "#include <stdio.h>\n\nint main() {\n    printf(\"Hello, Campus++!\\n\");\n    return 0;\n}\n",
  'csharp':     "using System;\nclass Program {\n    static void Main() {\n        Console.WriteLine(\"Hello, Campus++!\");\n    }\n}\n",
  'typescript': "const msg: string = 'Hello, Campus++!';\nconsole.log(msg);\n",
  'go':         "package main\nimport \"fmt\"\nfunc main() {\n    fmt.Println(\"Hello, Campus++!\")\n}\n",
  'rust':       "fn main() {\n    println!(\"Hello, Campus++!\");\n}\n",
  'kotlin':     "fun main() {\n    println(\"Hello, Campus++!\")\n}\n",
  'swift':      "import Swift\nprint(\"Hello, Campus++!\")\n",
  'bash':       "#!/bin/bash\necho \"Hello, Campus++!\"\n",
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
  final TextEditingController _codeCtrl        = TextEditingController();
  final TextEditingController _terminalInput   = TextEditingController();
  final ScrollController       _codeScroll     = ScrollController();
  final ScrollController       _terminalScroll = ScrollController();
  final FocusNode              _inputFocus     = FocusNode();

  List<Map<String, dynamic>> _languages = [];
  Map<String, dynamic>?      _selected;

  bool _loadingLangs    = true;
  bool _running         = false;
  bool _waitingForInput = false;  // terminal is asking for input

  // Accumulated stdin across runs (newline separated)
  final List<String> _stdinLines = [];

  // Terminal display lines: each entry is {text, color, bold?}
  final List<_TermLine> _termLines = [];

  String _memory  = '';
  String _cpuTime = '';

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadLanguages();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _codeCtrl.dispose();
    _terminalInput.dispose();
    _codeScroll.dispose();
    _terminalScroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── Language loading ───────────────────────────────────────────────────────
  Future<void> _loadLanguages() async {
    try {
      final langs = await CodeRunnerService.getLanguages();
      setState(() {
        _languages    = langs;
        _loadingLangs = false;
        _selected = langs.firstWhere(
            (l) => l['language'] == 'python3', orElse: () => langs.first);
        _codeCtrl.text = _starterCode[_selected!['language']] ?? '';
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
      _selected             = lang;
      _codeCtrl.text        = _starterCode[lang['language']] ?? '';
      _termLines.clear();
      _stdinLines.clear();
      _waitingForInput      = false;
      _memory               = '';
      _cpuTime              = '';
    });
    Navigator.pop(context);
  }

  // ── Core run logic ─────────────────────────────────────────────────────────
  Future<void> _runCode() async {
    if (_codeCtrl.text.trim().isEmpty || _selected == null) return;
    HapticFeedback.lightImpact();

    // Fresh run: clear state
    setState(() {
      _running         = true;
      _waitingForInput = false;
      _termLines.clear();
      _stdinLines.clear();
      _memory  = '';
      _cpuTime = '';
    });

    _termLines.add(_TermLine('▶  Running ${_selected!['display']}...', _accentGr, bold: true));
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
        code:     _codeCtrl.text,
        stdin:    stdin,
      );

      final raw    = (res['output'] ?? '').toString();
      _memory  = res['memory']?.toString()  ?? '';
      _cpuTime = res['cpuTime']?.toString() ?? '';

      final needsInput = _needsMoreInput(raw);

      if (needsInput) {
        // ── Only show clean stdout (everything BEFORE the traceback) ──────
        // JDoodle appends the traceback after the program's partial output:
        //   "Enter name: \n  File ...\n    name = input(...)\nEOFError: ..."
        // We split on the first occurrence of any traceback marker.
        String cleanOutput = raw;
        for (final marker in ['\nTraceback', '\n  File "', '\nEOFError', '\nException']) {
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
          _running         = false;
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
              ? '✖  Process exited with error'
              : '✔  Process exited with code 0   ⏱ ${_cpuTime}s   💾 ${_memory}KB',
          hasError ? _accentRd : _accentGr,
          bold: true,
        ));
        setState(() {
          _running         = false;
          _waitingForInput = false;
          if (_cpuTime.isEmpty) _cpuTime = res['cpuTime']?.toString() ?? '';
          if (_memory.isEmpty)  _memory  = res['memory']?.toString()  ?? '';
        });
        _scrollTerminal();
      }
    } catch (e) {
      _termLines.add(_TermLine(e.toString().replaceFirst('Exception:', '').trim(), _accentRd));
      _termLines.add(_TermLine('✖  Execution failed', _accentRd, bold: true));
      setState(() {
        _running         = false;
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
    _termLines.add(_TermLine('◆  $val', _accent));

    // Accumulate
    _stdinLines.add(val);

    setState(() {
      _running         = true;
      _waitingForInput = false;
    });

    // Re-run with all stdin so far
    await _executeWithCurrentStdin();
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
              width: 40, height: 4,
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
                  final lang      = _languages[i];
                  final isSelected = lang['language'] == _selected?['language'];
                  final dotColor  = _langColors[lang['language']] ?? _accent;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: dotColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dotColor.withAlpha(80), width: 1.5),
                      ),
                      child: Center(
                        child: Text(lang['ext'] ?? '',
                            style: GoogleFonts.jetBrainsMono(
                                color: dotColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    title: Text(lang['display'] ?? '',
                        style: GoogleFonts.jetBrainsMono(
                            color: isSelected ? _accent : _text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(lang['language'] ?? '',
                        style: GoogleFonts.jetBrainsMono(color: _textMuted, fontSize: 11)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: _accentGr, size: 20)
                        : null,
                    tileColor: isSelected ? _accent.withAlpha(15) : Colors.transparent,
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
          Text('Loading runtimes...', style: GoogleFonts.jetBrainsMono(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 20),
          const SizedBox(width: 180, child: LinearProgressIndicator(color: _accent, backgroundColor: _surface)),
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
        left: 12, right: 12, bottom: 10,
      ),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          _iconBtn(Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: dotColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: dotColor.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('main${_selected?['ext'] ?? '.py'}',
                    style: GoogleFonts.jetBrainsMono(
                        color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Spacer(),
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
                      style: GoogleFonts.jetBrainsMono(color: _textMuted, fontSize: 12)),
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
          _iconBtn(Icons.delete_outline, size: 16, tooltip: 'Clear', onPressed: () {
            setState(() { _codeCtrl.text = ''; });
          }),
          const SizedBox(width: 6),
          _iconBtn(Icons.copy_outlined, size: 16, tooltip: 'Copy', onPressed: () {
            Clipboard.setData(ClipboardData(text: _codeCtrl.text));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Code copied!', style: GoogleFonts.jetBrainsMono(fontSize: 12)),
              backgroundColor: _surface, duration: const Duration(seconds: 1)));
          }),
        ],
      ),
    );
  }

  // ── CODE EDITOR ────────────────────────────────────────────────────────────
  Widget _buildCodeEditor() {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        controller: _codeScroll,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGutter(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
                  child: TextField(
                    controller: _codeCtrl,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    style: GoogleFonts.jetBrainsMono(fontSize: 14, color: _text, height: 1.6),
                    decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    cursorColor: _accent,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGutter() {
    final lines = '\n'.allMatches(_codeCtrl.text).length + 1;
    return Container(
      width: 48,
      color: _surface,
      padding: const EdgeInsets.only(top: 4, bottom: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(lines, (i) => Text('${i + 1}',
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: _lineNum, height: 1.6))),
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
          _iconBtn(Icons.cleaning_services_outlined, size: 15, tooltip: 'Clear terminal',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: _running ? _accentGr.withAlpha(40) : _accentGr,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _running ? [] : [BoxShadow(color: _accentGr.withAlpha(80), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_running)
                      const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(color: _accentGr, strokeWidth: 2))
                    else
                      const Icon(Icons.play_arrow, color: _bg, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _running ? 'Running...' : 'Run',
                      style: GoogleFonts.jetBrainsMono(
                          color: _running ? _accentGr : _bg,
                          fontSize: 13, fontWeight: FontWeight.bold),
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
            LinearProgressIndicator(color: _accentGr, backgroundColor: _surface, minHeight: 2),

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
                            style: GoogleFonts.jetBrainsMono(color: _lineNum, fontSize: 12)),
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
                          fontWeight: line.bold ? FontWeight.bold : FontWeight.normal,
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
                  Text('›', style: GoogleFonts.jetBrainsMono(
                      color: _accentYl, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _terminalInput,
                      focusNode: _inputFocus,
                      style: GoogleFonts.jetBrainsMono(color: _text, fontSize: 14),
                      cursorColor: _accentYl,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Enter input and press ↵',
                        hintStyle: GoogleFonts.jetBrainsMono(color: _lineNum, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _submitInput(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  GestureDetector(
                    onTap: _submitInput,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accentYl,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('↵ Send',
                          style: GoogleFonts.jetBrainsMono(
                              color: _bg, fontSize: 12, fontWeight: FontWeight.bold)),
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
        child: Padding(padding: const EdgeInsets.all(6),
            child: Icon(icon, color: _textMuted, size: size)),
      ),
    );
  }
}

// ── Terminal line model ────────────────────────────────────────────────────
class _TermLine {
  final String text;
  final Color  color;
  final bool   bold;
  const _TermLine(this.text, this.color, {this.bold = false});
}

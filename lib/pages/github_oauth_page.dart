import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

// Result returned when OAuth completes
class GithubAuthResult {
  final String token;
  final String username;
  GithubAuthResult({required this.token, required this.username});
}

class GithubOAuthPage extends StatefulWidget {
  final String authUrl;
  const GithubOAuthPage({super.key, required this.authUrl});

  @override
  State<GithubOAuthPage> createState() => _GithubOAuthPageState();
}

class _GithubOAuthPageState extends State<GithubOAuthPage> {
  bool _loading = true;
  bool _captured = false;

  /// The backend redirects to: /code-ide#github_token=gho_xxx&github_user=johndoe
  /// or the full URL: https://campuspp-f7qx.onrender.com/code-ide#...
  bool _isCallbackUrl(String url) {
    return url.contains('github_token=') ||
        url.contains('/code-ide') ||
        url.contains('#github_token');
  }

  void _parseAndClose(String url) {
    if (_captured) return;
    _captured = true;

    // Extract hash fragment --- works whether full URL or path
    String fragment = '';
    final hashIdx = url.indexOf('#');
    if (hashIdx != -1) {
      fragment = url.substring(hashIdx + 1);
    }

    // Parse as query params (key=value&key=value)
    final params = Uri.splitQueryString(fragment);
    final token = params['github_token'];
    final user = params['github_user'];

    if (token != null && token.isNotEmpty && mounted) {
      Navigator.pop(
        context,
        GithubAuthResult(token: token, username: user ?? 'GitHub User'),
      );
    } else if (mounted) {
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: Text(
          'Connect GitHub',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  color: Color(0xFF58A6FF),
                  backgroundColor: Color(0xFF30363D),
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.authUrl),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent:
              'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          clearCache: true,
          clearSessionCache: true,
        ),
        onLoadStart: (ctrl, url) {
          setState(() => _loading = true);
          if (url != null && _isCallbackUrl(url.toString())) {
            _parseAndClose(url.toString());
          }
        },
        onLoadStop: (ctrl, url) async {
          setState(() => _loading = false);
          if (url != null && _isCallbackUrl(url.toString())) {
            _parseAndClose(url.toString());
            return;
          }
          // Also check the current URL via JS (handles hash-only navigation)
          final currentUrl = await ctrl.getUrl();
          if (currentUrl != null && _isCallbackUrl(currentUrl.toString())) {
            _parseAndClose(currentUrl.toString());
          }
        },
        onUpdateVisitedHistory: (ctrl, url, isReload) {
          if (url != null && _isCallbackUrl(url.toString())) {
            _parseAndClose(url.toString());
          }
        },
        shouldOverrideUrlLoading: (ctrl, action) async {
          final url = action.request.url?.toString() ?? '';
          if (_isCallbackUrl(url)) {
            _parseAndClose(url);
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}

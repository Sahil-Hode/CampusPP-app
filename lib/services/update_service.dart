import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  // Replace with the raw URL of your version.json on your GitHub repository
  static const String versionUrl =
      'https://raw.githubusercontent.com/Sahil-Hode/CampusPP-app/main/version.json';

  /// Check for application updates on startup
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(versionUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'] as String;
        final apkUrl = data['apk_url'] as String;
        final message = data['message'] as String;
        final forceUpdate = data['force_update'] as bool? ?? false;

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(
              context,
              latestVersion,
              message,
              apkUrl,
              forceUpdate,
            );
          }
        } else {
          print('[UpdateService] App is up to date ($currentVersion)');
        }
      }
    } catch (e) {
      print('[UpdateService] Error checking for updates: $e');
    }
  }

  /// Compare semantic versioning strings (e.g. "1.0.0" < "1.0.1")
  static bool _isUpdateAvailable(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      // Fallback simple compare if parse fails
      return current != latest;
    }
  }

  /// Show the neo-brutalist custom update dialog
  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String message,
    String apkUrl,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // block dismiss if forced
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) => _UpdateDialogWidget(
        version: version,
        message: message,
        apkUrl: apkUrl,
        forceUpdate: forceUpdate,
      ),
    );
  }
}

class _UpdateDialogWidget extends StatefulWidget {
  final String version;
  final String message;
  final String apkUrl;
  final bool forceUpdate;

  const _UpdateDialogWidget({
    Key? key,
    required this.version,
    required this.message,
    required this.apkUrl,
    required this.forceUpdate,
  }) : super(key: key);

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'A new version is available!';

  Future<void> _downloadAndInstallApp() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading update...';
      _progress = 0.0;
    });

    try {
      final externalDir = await getExternalStorageDirectory();
      // Store in standard download location or external path for file sharing
      final savePath = '${externalDir?.path ?? (await getApplicationDocumentsDirectory()).path}/update_v${widget.version}.apk';

      final request = http.Request('GET', Uri.parse(widget.apkUrl));
      final http.StreamedResponse response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download APK: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 1; // Avoid div by 0
      int downloadedBytes = 0;

      final file = File(savePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        setState(() {
          _progress = downloadedBytes / contentLength;
        });
      }

      await sink.close();

      setState(() {
        _statusMessage = 'Launching Installer...';
        _isDownloading = false;
        _progress = 1.0;
      });

      // Request OpenFilex to open the APK to trigger Android App Installer
      final result = await OpenFilex.open(savePath);

      if (result.type != ResultType.done) {
        setState(() {
          _statusMessage = "Install Failed. Try manually installing from Downloads.";
          _isDownloading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Download failed: ${e.toString().split(':')[0]}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hardware back-button intercept if forced update
    return WillPopScope(
      onWillPop: () async => !widget.forceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4), // Bright Yellow
            borderRadius: BorderRadius.circular(20),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5CAE9), // Accent Lavender
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  size: 32,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'UPDATE AVAILABLE',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'v${widget.version}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                widget.message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Progress Bar Area
              if (_isDownloading || _progress > 0) ...[
                Text(
                  _statusMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!widget.forceUpdate && !_isDownloading)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'LATER',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  if (!widget.forceUpdate && !_isDownloading) 
                    const SizedBox(width: 12),
                    
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isDownloading ? null : _downloadAndInstallApp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDownloading ? Colors.grey[400] : const Color(0xFFA8E6CF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: _isDownloading ? 2 : 2.5),
                          boxShadow: [
                            if (!_isDownloading)
                              const BoxShadow(color: Colors.black, offset: Offset(3, 3))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isDownloading ? 'Downloading...' : 'UPDATE NOW 🚀',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
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
}

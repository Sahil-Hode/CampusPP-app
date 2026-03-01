import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ar_generation_service.dart';
import 'ar_model_detail_page.dart';

class ARModelItem {
  final String? id; // MongoDB _id from backend
  final String title;
  final String path;
  final IconData icon;
  final Color color;

  ARModelItem({
    this.id,
    required this.title,
    required this.path,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'title': title,
    'path': path,
  };

  /// Parse from backend API response (GET /api/tripo3d/models)
  factory ARModelItem.fromApiJson(Map<String, dynamic> json) {
    final modelPath = json['pbrModel'] ?? json['modelUrl'] ?? '';
    debugPrint('[AR] fromApiJson: name=${json['name']}, '
        'status=${json['status']}, '
        'pbrModel=${json['pbrModel'] != null ? 'YES (${(json['pbrModel'] as String).length} chars)' : 'null'}, '
        'modelUrl=${json['modelUrl']}, '
        'resolvedPath=${modelPath.isNotEmpty ? 'YES' : 'EMPTY'}');
    return ARModelItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['name'] ?? json['title'] ?? 'Untitled Model',
      path: modelPath,
      icon: Icons.view_in_ar,
      color: const Color(0xFFFBE7C6),
    );
  }

  /// Parse from local SharedPreferences JSON
  factory ARModelItem.fromJson(Map<String, dynamic> json) {
    return ARModelItem(
      id: json['id'],
      title: json['title'],
      path: json['path'],
      icon: Icons.view_in_ar,
      color: const Color(0xFFFBE7C6),
    );
  }
}

class ARViewerPage extends StatefulWidget {
  const ARViewerPage({super.key});

  @override
  State<ARViewerPage> createState() => _ARViewerPageState();
}

class _ARViewerPageState extends State<ARViewerPage> {
  bool _isLoading = false;
  List<ARModelItem> models = [
    ARModelItem(
      title: 'Solar System',
      path: 'assets/models/solar_system_animation.glb',
      icon: Icons.public,
      color: const Color(0xFFA8E6CF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadModelsFromBackend();
  }

  /// Fetch all models from the backend API (GET /api/tripo3d/models)
  /// Falls back to SharedPreferences if backend is unreachable
  Future<void> _loadModelsFromBackend() async {
    try {
      final apiModels = await ARGenerationService.getAllModels();
      if (mounted && apiModels.isNotEmpty) {
        setState(() {
          models.addAll(
            apiModels.map((item) => ARModelItem.fromApiJson(item)).toList(),
          );
        });
      }
    } catch (_) {
      // Fallback to locally saved models if backend is unreachable
      await _loadSavedModelsFromPrefs();
    }
  }

  Future<void> _loadSavedModelsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? modelsJson = prefs.getString('saved_ar_models');
    if (modelsJson != null) {
      final List<dynamic> decoded = jsonDecode(modelsJson);
      if (mounted) {
        setState(() {
          models.addAll(decoded.map((item) => ARModelItem.fromJson(item)).toList());
        });
      }
    }
  }

  Future<void> _saveModel(ARModelItem newModel) async {
    // Save locally as fallback cache
    final prefs = await SharedPreferences.getInstance();

    List<ARModelItem> currentSaved = [];
    final String? existingModelsStr = prefs.getString('saved_ar_models');

    if (existingModelsStr != null) {
      final List<dynamic> decoded = jsonDecode(existingModelsStr);
      currentSaved = decoded.map((item) => ARModelItem.fromJson(item)).toList();
    }

    currentSaved.add(newModel);

    final String encoded =
        jsonEncode(currentSaved.map((m) => m.toJson()).toList());
    await prefs.setString('saved_ar_models', encoded);

    if (mounted) {
      setState(() {
        models.add(newModel);
      });
    }
  }

  /// Delete a model from the backend and local list
  Future<void> _deleteModel(int index) async {
    final model = models[index];

    // Don't allow deleting the built-in Solar System model
    if (model.id == null && model.path.startsWith('assets/')) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Model',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${model.title}"?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from backend if we have a MongoDB _id
      if (model.id != null) {
        await ARGenerationService.deleteModel(model.id!);
      }

      // Remove from local list
      setState(() {
        models.removeAt(index);
      });

      // Update SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final localModels =
          models.where((m) => !m.path.startsWith('assets/')).toList();
      final String encoded =
          jsonEncode(localModels.map((m) => m.toJson()).toList());
      await prefs.setString('saved_ar_models', encoded);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${model.title} deleted',
                  style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to delete: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  Future<String?> _promptForModelName() async {
    String modelName = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Name your 3D Model', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g., Coffee Mug',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => modelName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, modelName.trim().isEmpty ? 'My 3D Model' : modelName.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Generate', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Take a Photo', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _processImageAndGenerateModel(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Upload from Gallery', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _processImageAndGenerateModel(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImageAndGenerateModel(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image from the selected source
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    // Ask user for a name before uploading
    final modelTitle = await _promptForModelName();
    if (modelTitle == null) return; // User cancelled
    
    setState(() {
      _isLoading = true;
    });

    try {
      final file = File(image.path);
      
      // Automatically convert/resize image to JPEG format to avoid massive upload sizes
      final bytes = await file.readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);
      
      if (decodedImage == null) throw Exception("Failed to decode image");
      
      // Resize the image if it's too large, drastically accelerating upload times & preventing connection reset
      if (decodedImage.width > 1024 || decodedImage.height > 1024) {
        decodedImage = img.copyResize(decodedImage, 
          width: decodedImage.width > decodedImage.height ? 1024 : null,
          height: decodedImage.height >= decodedImage.width ? 1024 : null,
        );
      }
      
      final compressedBytes = img.encodeJpg(decodedImage, quality: 85);
      
      // Save the JPG to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_model_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);
      
      int sizeInBytes = tempFile.lengthSync();
      double sizeInMb = sizeInBytes / (1024 * 1024);
      
      if (sizeInMb > 20) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is too large. Maximum size is 20 MB.')),
        );
        return;
      }

      final result = await ARGenerationService.generateModelFromImage(
        tempFile,
        name: modelTitle,
      );
      
      if (!mounted) return;
      if (result != null) {
        debugPrint('[AR] Generate result keys: ${result.keys.toList()}');
        debugPrint('[AR] pbrModel: ${result['pbrModel']}');
        debugPrint('[AR] modelUrl: ${result['modelUrl']}');
        final modelUrl = result['pbrModel'] ?? result['modelUrl'] ?? '';
        final modelId = result['_id']?.toString() ?? result['id']?.toString();
        debugPrint('[AR] Resolved modelUrl: $modelUrl');

        if (modelUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Model generated but no download URL yet. Check back shortly.')),
          );
          return;
        }
        
        // Save the new model
        final newModel = ARModelItem(
          id: modelId,
          title: modelTitle,
          path: modelUrl,
          icon: Icons.view_in_ar,
          color: const Color(0xFFFBE7C6),
        );
        
        await _saveModel(newModel);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ARModelDetailPage(
              modelPath: modelUrl,
              title: modelTitle,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate model: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5), // Match dashboard theme
      appBar: AppBar(
        title: Text(
          'AR Models',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showImageSourcePicker,
        backgroundColor: Colors.black,
        icon: _isLoading 
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: Text(
          _isLoading ? 'Generating Model...' : 'Generate 3D Model',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: RefreshIndicator(
                color: Colors.black,
                onRefresh: () async {
                  setState(() {
                    // Keep only the built-in Solar System model
                    models.removeWhere((m) => !m.path.startsWith('assets/'));
                  });
                  await _loadModelsFromBackend();
                },
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return GestureDetector(
                      onTap: () {
                        if (model.path.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${model.title} is still processing. Pull down to refresh.',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ARModelDetailPage(
                              modelPath: model.path,
                              title: model.title,
                            ),
                          ),
                        );
                      },
                    child: Container(
                      decoration: BoxDecoration(
                        color: model.color,
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
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: Icon(model.icon,
                                      size: 40, color: Colors.black),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    model.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Delete button — only for non-built-in models
                          if (!model.path.startsWith('assets/'))
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _deleteModel(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.black, width: 1.5),
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.black),
                        const SizedBox(height: 20),
                        Text(
                          'Converting image to 3D...\nThis may take a few moments.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

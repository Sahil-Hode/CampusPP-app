import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/student_profile_model.dart';
import '../services/student_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _languageController;
  late TextEditingController _classesController;
  
  StudentProfile? _profile;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  bool _isUploadingResume = false;
  String? _avatarOverride;
  String? _resumeFileName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _languageController = TextEditingController();
    _classesController = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _languageController.dispose();
    _classesController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await StudentService.getFullStudentProfile();
      setState(() {
        _profile = profile;
        _avatarOverride = null;
        _nameController.text = profile.name;
        _languageController.text = profile.language;
        _classesController.text = profile.classes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    final profile = _profile;
    if (profile == null) return;

    final result = await Navigator.push<StudentProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: profile),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _profile = result;
        _nameController.text = result.name;
        _languageController.text = result.language;
        _classesController.text = result.classes;
        _avatarOverride = null;
        _resumeFileName = null;
      });
    }
  }

  ImageProvider _buildAvatarImage() {
    final src = _avatarOverride ??
        _profile?.avatarUrl ??
        'https://api.dicebear.com/7.x/avataaars/png?seed=Felix';
    if (src.startsWith('data:image')) {
      final base64Data = src.split(',').last;
      return MemoryImage(base64Decode(base64Data));
    }
    return NetworkImage(src);
  }

  Future<void> _uploadProfilePhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploadingPhoto = true);

      final data = await StudentService.uploadProfilePhoto(result.files.single.path!);
      final photo = data['profilePhoto'];
      if (photo is String && photo.isNotEmpty) {
        setState(() => _avatarOverride = photo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _uploadResume() async {
    if (_isUploadingResume) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isUploadingResume = true;
        _resumeFileName = result.files.single.name;
      });

      await StudentService.uploadResume(result.files.single.path!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading resume: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingResume = false);
      }
    }
  }

  void _showResumeText() {
    final text = _profile?.resumeText ?? '';
    if (text.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Text'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5), // Mint background
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                      // Avatar Display (Read Only)
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 3),
                            image: DecorationImage(
                              image: _buildAvatarImage(),
                              fit: BoxFit.cover
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if ((_profile?.resumeText ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showResumeText,
                            icon: const Icon(Icons.visibility, color: Colors.white),
                            label: const Text(
                              'View Resume',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                      Text(
                        _profile?.studentId ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      _buildNeuTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),

                      // Language Field
                      _buildNeuTextField(
                        controller: _languageController,
                        label: 'Preferred Language',
                        icon: Icons.language,
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),

                       // Classes Field
                      _buildNeuTextField(
                        controller: _classesController,
                        label: 'Class/Year',
                        icon: Icons.class_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),
                      
                      // Read-only Email
                       _buildNeuTextField(
                        controller: TextEditingController(text: _profile?.email),
                        label: 'Email',
                        icon: Icons.email_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),

                      // Read-only Phone number
                       _buildNeuTextField(
                        controller: TextEditingController(text: _profile?.phoneNo),
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),

                      // Read-only Institute
                       _buildNeuTextField(
                        controller: TextEditingController(text: _profile?.instituteName),
                        label: 'Institute',
                        icon: Icons.school_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 24),

                      // Read-only Course
                       _buildNeuTextField(
                        controller: TextEditingController(text: _profile?.course),
                        label: 'Course',
                        icon: Icons.book_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 40),

                      // Edit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () async {
                            await AuthService.logout();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                                (route) => false,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

}

Widget _buildNeuTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool readOnly = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: readOnly ? Colors.grey[200] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: readOnly
              ? []
              : const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          validator: (value) {
            if (!readOnly && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class EditProfilePage extends StatefulWidget {
  final StudentProfile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _languageController;
  late TextEditingController _classesController;
  late TextEditingController _phoneNoController;
  late TextEditingController _courseController;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isUploadingResume = false;
  String? _avatarOverride;
  String? _resumeFileName;
  static const String _defaultAvatar =
      'https://api.dicebear.com/7.x/avataaars/png?seed=Felix';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _languageController = TextEditingController(text: widget.profile.language);
    _classesController = TextEditingController(text: widget.profile.classes);
    _phoneNoController = TextEditingController(text: widget.profile.phoneNo);
    _courseController = TextEditingController(text: widget.profile.course);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _languageController.dispose();
    _classesController.dispose();
    _phoneNoController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  ImageProvider _buildAvatarImage() {
    final src = _avatarOverride ?? widget.profile.avatarUrl;
    if (src.startsWith('data:image')) {
      final base64Data = src.split(',').last;
      return MemoryImage(base64Decode(base64Data));
    }
    return NetworkImage(src);
  }

  void _removeAvatar() {
    setState(() {
      _avatarOverride = _defaultAvatar;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed. Upload a new photo to save.'),
      ),
    );
  }

  Future<void> _uploadProfilePhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploadingPhoto = true);

      final data = await StudentService.uploadProfilePhoto(result.files.single.path!);
      final photo = data['profilePhoto'];
      if (photo is String && photo.isNotEmpty) {
        setState(() => _avatarOverride = photo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _uploadResume() async {
    if (_isUploadingResume) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isUploadingResume = true;
        _resumeFileName = result.files.single.name;
      });

      await StudentService.uploadResume(result.files.single.path!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading resume: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingResume = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await StudentService.updateProfile(
        _nameController.text,
        _languageController.text,
        _classesController.text,
        _courseController.text,
        _phoneNoController.text,
      );

      final updated = StudentProfile(
        name: _nameController.text,
        language: _languageController.text,
        classes: _classesController.text,
        email: widget.profile.email,
        studentId: widget.profile.studentId,
        avatarUrl: _avatarOverride ?? widget.profile.avatarUrl,
        instituteName: widget.profile.instituteName,
        course: _courseController.text,
        phoneNo: _phoneNoController.text,
        instituteId: widget.profile.instituteId,
        dateOfJoin: widget.profile.dateOfJoin,
        resumeText: widget.profile.resumeText,
        resumeUploadedAt: widget.profile.resumeUploadedAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 3),
                          image: DecorationImage(
                            image: _buildAvatarImage(),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: GestureDetector(
                          onTap: _removeAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF43F5E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 330;
                    final buttonHeight = isNarrow ? 42.0 : 48.0;
                    final fontSize = isNarrow ? 11.0 : 13.0;
                    final iconSize = isNarrow ? 16.0 : 20.0;
                    final horizontalPad = isNarrow ? 6.0 : 10.0;

                    Widget buildBtn({
                      required VoidCallback? onPressed,
                      required Widget icon,
                      required String label,
                    }) {
                      return SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: onPressed,
                          icon: icon,
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: buildBtn(
                            onPressed: _isUploadingPhoto ? null : _uploadProfilePhoto,
                            icon: _isUploadingPhoto
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Icon(Icons.photo_camera, color: Colors.white, size: iconSize),
                            label: 'Edit Photo',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildBtn(
                            onPressed: _isUploadingResume ? null : _uploadResume,
                            icon: _isUploadingResume
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Icon(Icons.upload_file, color: Colors.white, size: iconSize),
                            label: 'Upload Resume',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_resumeFileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _resumeFileName!,
                    style: const TextStyle(color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 24),
                _buildNeuTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 24),
                _buildNeuTextField(
                  controller: _languageController,
                  label: 'Preferred Language',
                  icon: Icons.language,
                ),
                const SizedBox(height: 24),
                _buildNeuTextField(
                  controller: _classesController,
                  label: 'Class/Year',
                  icon: Icons.class_outlined,
                ),
                const SizedBox(height: 24),
                _buildNeuTextField(
                  controller: _courseController,
                  label: 'Course',
                  icon: Icons.book_outlined,
                ),
                const SizedBox(height: 24),
                _buildNeuTextField(
                  controller: _phoneNoController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

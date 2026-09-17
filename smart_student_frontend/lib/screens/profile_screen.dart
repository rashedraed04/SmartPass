import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'package:smart_student_frontend/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional, if provided fetch that user's read-only profile
  
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isReadOnly;
  late String _targetUserId;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();
  
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    final currentUid = authService.currentUserId;
    // Determine if read-only
    if (widget.userId != null && widget.userId != currentUid) {
      _isReadOnly = true;
      _targetUserId = widget.userId!;
    } else {
      _isReadOnly = false;
      _targetUserId = currentUid ?? '';
    }
    
    _userEmail = authService.currentUserEmail ?? 'user@test.com';

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final endpoint = (_isReadOnly && _targetUserId.isNotEmpty)
          ? 'users/$_targetUserId/'
          : 'users/me/';
      final response = await apiService.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _nameController.text = data['name'] ?? data['username'] ?? 'مستخدم';
        _majorController.text = data['major'] ?? 'علوم الحاسوب';
        _yearController.text = data['year'] ?? 'السنة الرابعة';
        _gpaController.text = data['gpa'] ?? '3.4';
        
        if (data['email'] != null) {
          _userEmail = data['email'];
        }
      } else {
        _nameController.text = authService.currentUserName ?? 'مستخدم';
        _majorController.text = authService.currentUserMajor ?? 'علوم الحاسوب';
        _yearController.text = 'السنة الرابعة';
        _gpaController.text = '3.4';
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await apiService.put('users/me/', {
        'major': _majorController.text.trim(),
      });
      
      if (response.statusCode == 200) {
        await authService.getCurrentUser();
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _yearController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => '';

    if (_isLoading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    String initials = "م";
    if (_nameController.text.isNotEmpty) {
       final parts = _nameController.text.trim().split(' ');
       initials = parts.length > 1 ? parts[0][0] + parts[1][0] : parts[0][0];
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.userId != null 
            ? AppBar(
                title: Text(t('profile_title')),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                foregroundColor: Theme.of(context).appBarTheme.iconTheme?.color,
                leading: const BackButton(),
            ) : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Avatar Placeholder untouched
                CircleAvatar(
                  radius: 48,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildTextField(
                  controller: _nameController,
                  label: t('profile_full_name'),
                  icon: Icons.person_outline,
                  readOnly: _isReadOnly,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                Text(
                  _userEmail,
                  style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 32),
                
                _buildTextField(
                  controller: _majorController,
                  label: t('profile_major'),
                  icon: Icons.school_outlined,
                  readOnly: _isReadOnly,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _yearController,
                  label: t('profile_year'),
                  icon: Icons.calendar_today_outlined,
                  readOnly: _isReadOnly,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _gpaController,
                  label: t('profile_gpa'),
                  icon: Icons.grade_outlined,
                  readOnly: _isReadOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                
                if (!_isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'حفظ التعديلات',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                  
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.right,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        textAlign: textAlign,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: textAlign == TextAlign.center ? null : label,
          labelStyle: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          hintText: textAlign == TextAlign.center ? label : null,
          hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          prefixIcon: textAlign == TextAlign.center ? null : Icon(icon, color: const Color(0xFF3B82F6), size: 22),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(14),
             borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
        ),
        validator: (val) {
          if (!readOnly && (val == null || val.trim().isEmpty)) {
            return 'يرجى إدخال $label';
          }
          return null;
        },
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'package:smart_student_frontend/services/auth_service.dart';
import 'dart:convert';

/// Department options: code → Arabic label
const Map<String, String> _kDepartments = {
  'CS': 'علوم الحاسوب',
  'CYBER': 'الأمن السيبراني',
  'CIS': 'نظم المعلومات الحاسوبية',
  'AI': 'الذكاء الاصطناعي',
  'BIT': 'تقنية المعلومات والأعمال',
  'DATA SCIENCE': 'علم البيانات',
};

class AdminProfileEditScreen extends StatefulWidget {
  const AdminProfileEditScreen({super.key});

  @override
  State<AdminProfileEditScreen> createState() => _AdminProfileEditScreenState();
}

class _AdminProfileEditScreenState extends State<AdminProfileEditScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedDepartment; // key from _kDepartments

  bool _isLoading = true;
  bool _isSaving = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _fetchProfile() async {
    try {
      final response = await apiService.get('users/me/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _nameController.text = data['name'] ?? data['username'] ?? '';

        final stored = (data['major'] as String? ?? '').toUpperCase();
        if (_kDepartments.containsKey(stored)) {
          _selectedDepartment = stored;
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في جلب البيانات: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final response = await apiService.put('users/me/', {
        'major': _selectedDepartment ?? '',
      });

      if (response.statusCode == 200) {
        await authService.getCurrentUser();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'تم التحديث بنجاح',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic color tokens derived from the global theme
    final Color accent = colorScheme.primary;
    final Color scaffoldBg = theme.scaffoldBackgroundColor;
    final Color cardBg = isDark
        ? const Color(0xFF1B2236)
        : colorScheme.surfaceContainerHighest;
    final Color borderColor = isDark
        ? const Color(0xFF2C3246)
        : colorScheme.outlineVariant;
    final Color textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color textSecondary =
        theme.textTheme.bodySmall?.color ?? Colors.grey;
    final Color dropdownBg = isDark
        ? const Color(0xFF131724)
        : colorScheme.surface;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          leading: BackButton(color: textPrimary),
          title: Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: borderColor),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: accent),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar ───────────────────────────────────────────
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [accent, const Color(0xFF1D4ED8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 52,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          authService.currentUserEmail ?? '',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Section label ────────────────────────────────────
                      _sectionLabel('المعلومات الشخصية', accent, textSecondary),
                      const SizedBox(height: 14),

                      // ── Name field ───────────────────────────────────────
                      _fieldLabel('الاسم', Icons.person_outline_rounded, accent, textPrimary),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: _nameController,
                        hint: 'أدخل الاسم الكامل',
                        prefixIcon: Icons.person_rounded,
                        accent: accent,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'يرجى إدخال الاسم';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // ── Department dropdown ──────────────────────────────
                      _fieldLabel('القسم', Icons.school_outlined, accent, textPrimary),
                      const SizedBox(height: 8),
                      _buildDepartmentDropdown(
                        accent: accent,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        dropdownBg: dropdownBg,
                      ),

                      const SizedBox(height: 48),

                      // ── Save button ──────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            disabledBackgroundColor:
                                accent.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'حفظ',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String title, Color accent, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, IconData icon, Color accent, Color textPrimary) {
    return Row(
      children: [
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required Color accent,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textSecondary, fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: accent, size: 20)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown({
    required Color accent,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color dropdownBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selectedDepartment == null && _formKey.currentState != null
              ? Colors.red.shade400
              : borderColor,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDepartment,
        isExpanded: true,
        dropdownColor: dropdownBg,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: textSecondary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          prefixIcon: Icon(Icons.school_rounded, color: accent, size: 20),
        ),
        hint: Text(
          'اختر القسم',
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
        style: TextStyle(color: textPrimary, fontSize: 15),
        validator: (val) {
          if (val == null || val.isEmpty) return 'يرجى اختيار القسم';
          return null;
        },
        onChanged: (val) => setState(() => _selectedDepartment = val),
        items: _kDepartments.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  entry.value,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

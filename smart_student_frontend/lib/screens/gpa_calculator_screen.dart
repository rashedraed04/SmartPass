import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class _CourseRow {
  final TextEditingController nameController;
  final TextEditingController hoursController;

  _CourseRow()
      : nameController = TextEditingController(),
        hoursController = TextEditingController();

  void dispose() {
    nameController.dispose();
    hoursController.dispose();
  }
}

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  // New Controllers for Offline Input
  final _currentGpaController = TextEditingController();
  final _successfulHoursController = TextEditingController();
  final _targetGpaController = TextEditingController();
  
  final List<_CourseRow> _courses = [_CourseRow(), _CourseRow()];

  // ── Grade Scale ────────────────────────────────────────────────────────────
  final Map<String, double> _gradeScale = {
    'A': 4.0,
    'A-': 3.75,
    'B+': 3.5,
    'B': 3.0,
    'B-': 2.75,
    'C+': 2.5,
    'C': 2.0,
    'C-': 1.75,
    'D+': 1.5,
    'D': 1.0,
  };

  // ── Distribution Algorithm ─────────────────────────────────────────────────
  Map<int, String>? _generateGrades({
    required double requiredAvg,
    required List<int> courseHours,
  }) {
    final random = Random();
    final gradeKeys = _gradeScale.keys.toList();
    int totalHours = courseHours.reduce((a, b) => a + b);
    
    Map<int, String>? bestCombo;
    double bestAvg = 0.0;

    // Try finding a valid combination
    for (int attempt = 0; attempt < 1000; attempt++) {
      Map<int, String> currentCombo = {};
      double totalPoints = 0;
      
      for (int i = 0; i < courseHours.length; i++) {
        String grade = gradeKeys[random.nextInt(gradeKeys.length)];
        currentCombo[i] = grade;
        totalPoints += (_gradeScale[grade]! * courseHours[i]);
      }
      
      double currentAvg = totalPoints / totalHours;
      
      if (currentAvg >= requiredAvg) {
        return currentCombo;
      }
      
      if (currentAvg > bestAvg) {
        bestAvg = currentAvg;
        bestCombo = currentCombo;
      }
    }
    
    return bestCombo; // Return best found if none met the target
  }

  void _addCourse() {
    setState(() => _courses.add(_CourseRow()));
  }

  void _removeCourse(int index) {
    if (_courses.length <= 1) return;
    _courses[index].dispose();
    setState(() => _courses.removeAt(index));
  }

  // ── Math Logic ─────────────────────────────────────────────────────────────
  Map<String, double> calculateGpaRequirements({
    required double currentGPA,
    required int successfulHours,
    required double targetGPA,
    required int semesterHours,
  }) {
    // Safety check to prevent dividing by zero if the user hasn't added courses yet
    if (semesterHours == 0) {
      return {
        'requiredAverage': 0.0,
        'maxAchievableGpa': currentGPA,
      };
    }

    // 1. Calculate the total hours you will have after this semester
    int totalHoursFuture = successfulHours + semesterHours;

    // 2. Calculate the "Quality Points" you already have
    double currentPoints = currentGPA * successfulHours;

    // 3. Calculate the total points needed to hit the target
    double targetPoints = targetGPA * totalHoursFuture;

    // 4. Calculate the required average for this semester
    double pointsNeededThisSemester = targetPoints - currentPoints;
    double requiredAverage = pointsNeededThisSemester / semesterHours;

    // 5. Calculate the absolute MAX GPA possible (If the student gets a 4.0 in every class)
    double maxPointsThisSemester = 4.0 * semesterHours;
    double maxAchievableGpa = (currentPoints + maxPointsThisSemester) / totalHoursFuture;

    return {
      'requiredAverage': requiredAverage,
      'maxAchievableGpa': maxAchievableGpa,
    };
  }

  // ── Analysis Flow ──────────────────────────────────────────────────────────
  void _runAnalysis() {
    // 1. Validate and Collect Top Headers
    final currentGPA = double.tryParse(_currentGpaController.text.trim());
    final successfulHours = int.tryParse(_successfulHoursController.text.trim());
    final targetGpa = double.tryParse(_targetGpaController.text.trim());

    if (currentGPA == null || successfulHours == null || targetGpa == null) {
      _showSimpleDialog(
        title: 'gpa_missing_data'.tr(),
        message: 'gpa_missing_data_msg'.tr(),
        isError: true,
      );
      return;
    }

    // 2. Collect Semester Hours from dynamic list
    int totalSemesterHours = 0;
    List<int> courseHoursList = [];
    for (var course in _courses) {
      final h = int.tryParse(course.hoursController.text.trim()) ?? 0;
      totalSemesterHours += h;
      courseHoursList.add(h);
    }

    // Scenario C: No semester hours
    if (totalSemesterHours == 0) {
      _showSimpleDialog(
        title: 'gpa_no_hours'.tr(),
        message: 'gpa_no_hours_msg'.tr(),
        isError: true,
      );
      return;
    }

    // 3. Calculate
    final results = calculateGpaRequirements(
      currentGPA: currentGPA,
      successfulHours: successfulHours,
      targetGPA: targetGpa,
      semesterHours: totalSemesterHours,
    );
    
    double requiredAverage = results['requiredAverage']!;
    double maxAchievableGpa = results['maxAchievableGpa']!;

    // 4. UI Feedback
    if (requiredAverage > 4.0) {
      // Scenario B: Impossible
      _showSimpleDialog(
        title: 'gpa_ambitious'.tr(),
        message: 'هذا الهدف مستحيل رياضياً في فصل واحد. أعلى معدل يمكنك الوصول إليه هذا الفصل هو ${maxAchievableGpa.toStringAsFixed(2)}',
        isWarning: true,
      );
    } else {
      // Scenario A: Safe
      _showGradesDialog(requiredAverage, courseHoursList);
    }
  }

  void _showGradesDialog(double requiredAverage, List<int> courseHoursList) {
    Map<int, String> currentGrades = _generateGrades(
      requiredAvg: requiredAverage,
      courseHours: courseHoursList,
    ) ?? {};

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return StatefulBuilder(builder: (context, setDialogState) {
          return Directionality(
            textDirection: Directionality.of(context),
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF003B00) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Text('gpa_goal_prefix'.tr(), style: TextStyle(fontSize: 18, color: isDark ? Colors.white : const Color(0xFF003B00))),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF004D00) : const Color(0xFFE2E8F0)),
                        itemBuilder: (ctx, i) {
                          final name = _courses[i].nameController.text.trim();
                          final displayName = name.isEmpty ? 'مادة ${i + 1}' : name;
                          final grade = currentGrades[i] ?? '-';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(displayName, style: TextStyle(fontSize: 15, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF003B00))),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                grade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${'gpa_required_sem'.tr()}: ${requiredAverage.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      currentGrades = _generateGrades(
                        requiredAvg: requiredAverage,
                        courseHours: courseHoursList,
                      ) ?? {};
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text('gpa_other_options'.tr()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('gpa_ok'.tr()),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showSimpleDialog({
    required String title,
    required String message,
    bool isError = false,
    bool isWarning = false,
  }) {
    IconData icon = Icons.info_outline_rounded;
    Color color = Theme.of(context).primaryColor;

    if (isError) {
      icon = Icons.error_outline_rounded;
      color = const Color(0xFFEF4444);
    } else if (isWarning) {
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Directionality(
          textDirection: Directionality.of(context),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF003B00) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: color, fontSize: 18)),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF003B00)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('gpa_ok'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _currentGpaController.dispose();
    _successfulHoursController.dispose();
    _targetGpaController.dispose();
    for (final c in _courses) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF001600) : const Color(0xFFF4F6FB),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'title_gpa'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF003B00),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: const BackButton(),
          iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF003B00)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Section (Offline Input Form) ──────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF002200) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'gpa_title'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF003B00),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _HeaderInputField(
                      controller: _currentGpaController,
                      label: 'gpa_current'.tr(),
                      hint: 'gpa_hint_current'.tr(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _HeaderInputField(
                      controller: _successfulHoursController,
                      label: 'gpa_hours'.tr(),
                      hint: 'gpa_hint_hours'.tr(),
                      isInteger: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _HeaderInputField(
                      controller: _targetGpaController,
                      label: 'gpa_target'.tr(),
                      hint: 'gpa_hint_target'.tr(),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Semester Courses Section ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _addCourse,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                  Text(
                    'gpa_courses'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF003B00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Course rows
              ...List.generate(
                _courses.length,
                (i) => _CourseRowWidget(
                  row: _courses[i],
                  onDelete: () => _removeCourse(i),
                  isDark: isDark,
                ),
              ),

              const SizedBox(height: 32),

              // ── Analyze Button ───────────────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _runAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    'gpa_analyze'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────────────

class _HeaderInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isInteger;
  final bool isDark;

  const _HeaderInputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isInteger = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(
              decimal: !isInteger, signed: false),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            fillColor: isDark ? const Color(0xFF003B00) : const Color(0xFFF8FAFC),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF004D00) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF004D00) : const Color(0xFFE2E8F0)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: TextStyle(fontSize: 16, color: isDark ? Colors.white : const Color(0xFF003B00)),
        ),
      ],
    );
  }
}

class _CourseRowWidget extends StatelessWidget {
  final _CourseRow row;
  final VoidCallback onDelete;
  final bool isDark;

  const _CourseRowWidget({required this.row, required this.onDelete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, color: Color(0xFFEF4444), size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Credit hours field
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: row.hoursController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: _inputDecor('Hours', isDark),
                style: TextStyle(
                    fontSize: 14, color: isDark ? Colors.white : const Color(0xFF003B00)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Course name field
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: row.nameController,
                textAlign: TextAlign.start,
                decoration: _inputDecor('Course Name', isDark),
                style: TextStyle(
                    fontSize: 14, color: isDark ? Colors.white : const Color(0xFF003B00)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String hint, bool isDark) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        filled: true,
        fillColor: isDark ? const Color(0xFF002200) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF006B00), width: 1.5),
        ),
      );
}



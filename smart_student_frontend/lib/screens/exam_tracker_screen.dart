import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'package:smart_student_frontend/services/auth_service.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

class ExamTrackerScreen extends StatefulWidget {
  const ExamTrackerScreen({super.key});

  @override
  State<ExamTrackerScreen> createState() => _ExamTrackerScreenState();
}

class _ExamTrackerScreenState extends State<ExamTrackerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedType = 'Midterm';

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showAddExamSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'add_new_exam'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'exam_name'.tr(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        prefixIcon: Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                            label: Text(_selectedDate == null
                                ? 'select_date'.tr()
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: Theme.of(context).colorScheme.copyWith(
                                        primary: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setModalState(() {
                                  _selectedDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                            label: Text(_selectedTime == null
                                ? 'select_time'.tr()
                                : _selectedTime!.format(context)),
                            onPressed: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        dialHandColor: Theme.of(context).colorScheme.primary,
                                      ),
                                      colorScheme: Theme.of(context).colorScheme.copyWith(
                                        primary: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedTime != null) {
                                setModalState(() {
                                  _selectedTime = pickedTime;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'location'.tr(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        prefixIcon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'exam_type'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: ['Midterm', 'Final', 'Quiz']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setModalState(() => _selectedDate = pickedDate);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _selectedDate == null
                                  ? 'select_date'.tr()
                                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setModalState(() => _selectedTime = pickedTime);
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _selectedTime == null
                                  ? 'select_time'.tr()
                                  : _selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () => _submitExam(context),
                      child: Text('save_exam'.tr(), style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitExam(BuildContext context) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_enter_course_name'.tr())),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_select_date_and_time'.tr())),
      );
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      await apiService.post('exams/', {
        'course_name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _selectedType,
        'date': combinedDateTime.toIso8601String(),
      });
      _nameController.clear();
      _locationController.clear();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _selectedType = 'Midterm';
      });
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_to_add_exam'.tr()}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = authService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text('exam_tracker'.tr()),
      ),
      body: userId == null
          ? Center(child: Text('user_not_logged_in'.tr()))
          : FutureBuilder(
              future: apiService.get('exams/'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('error_loading_exams'.tr()));
                }

                List<dynamic> docs = [];
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    final decoded = jsonDecode((snapshot.data as dynamic).body);
                    if (decoded is List) docs = decoded;
                  } catch (_) {}
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text('no_exams_scheduled'.tr(), style: const TextStyle(fontSize: 18)),
                  );
                }

                docs.sort((a, b) {
                  final dtA = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime.now();
                  final dtB = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime.now();
                  return dtA.compareTo(dtB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index] as Map<String, dynamic>;
                    final docId = data['id']?.toString() ?? '';
                    final String name = data['course_name'] ?? '';
                    final String location = data['location'] ?? 'قاعة الامتحانات';
                    final String type = data['type'] ?? 'Midterm';
                    final DateTime examDateTime = DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
                    
                    final Duration diff = examDateTime.difference(DateTime.now());
                    final bool isPast = diff.isNegative;
                    final bool isMoreThan3Days = diff.inDays > 3;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            location,
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Theme.of(context).textTheme.bodySmall?.color),
                                  onPressed: () async {
                                    try {
                                      await apiService.delete('exams/$docId/');
                                      setState(() {});
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${'error_deleting'.tr()}: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    type,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (isPast)
                                      Text(
                                        "exam_passed".tr(),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      Text(
                                        'time_remaining'.tr(args: [diff.inDays.toString(), (diff.inHours % 24).toString()]),
                                        style: TextStyle(
                                          color: isMoreThan3Days
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          TimeOfDay.fromDateTime(examDateTime).format(context),
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.access_time,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                            size: 12),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${examDateTime.day}/${examDateTime.month}/${examDateTime.year}",
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.calendar_today,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                            size: 12),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => _showAddExamSheet(context),
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}

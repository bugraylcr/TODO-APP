import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'todo.dart';
import 'task.dart' as task_model;
import 'package:intl/intl.dart';

class Task {
  final int id;
  final String title;
  final task_model.TaskCategory category;
  final String? time;
  final String notes;
  final String date;

  Task({
    required this.id,
    required this.title,
    required this.category,
    this.time,
    required this.notes,
    required this.date,
  });
}

class AddTaskPage extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskPage({super.key, required this.onTaskAdded});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();
  task_model.TaskCategory? _selectedCategory;

  String? _titleError;
  String? _dateError;
  String? _timeError;
  String? _notesError;

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    bool isValid = true;

    setState(() {
      _titleError = _titleController.text.isEmpty ? 'Title is required' : null;
      _dateError = _dateController.text.isEmpty ? 'Date is required' : null;
      _timeError = _timeController.text.isEmpty ? 'Time is required' : null;
      
      if (_notesController.text.isEmpty) {
        _notesError = 'Notes are required';
        isValid = false;
      } else if (_notesController.text.length < 3) {
        _notesError = 'Notes must be at least 3 characters';
        isValid = false;
      } else {
        _notesError = null;
      }
    });

    return isValid && _titleError == null && _dateError == null && _timeError == null;
  }

  Future<void> _onAddTask() async {
    if (_validateFields()) {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch,
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        time: _timeController.text.isNotEmpty ? _timeController.text.trim() : null,
        notes: _notesController.text.trim(),
        date: _dateController.text,
      );

      try {
        await Supabase.instance.client.from('todo_tasks').insert({
          'task_title': newTask.title,
          'task_notes': newTask.notes,
          'task_date': newTask.date,
          'task_time': newTask.time,
          'task_category': newTask.category.name.toLowerCase(),
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TodoListPage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFEBE2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Task',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                cursorColor: const Color.fromRGBO(0, 0, 0, 0.7),
                keyboardType: TextInputType.text,
                style: const TextStyle(
                  color: Color(0xFF383E4D),
                ),
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  labelStyle: TextStyle(
                    color: const Color.fromRGBO(56, 62, 77, 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  ),
                  errorText: _titleError,
                  errorStyle: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Category',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _categoryButton(task_model.TaskCategory.study, Icons.book),
                  _categoryButton(task_model.TaskCategory.event, Icons.calendar_today),
                  _categoryButton(task_model.TaskCategory.achievement, Icons.emoji_events),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _dateController,
                readOnly: true,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Color.fromRGBO(10, 10, 10, 0.502),
                ),
                decoration: InputDecoration(
                  labelText: 'Date',
                  labelStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    color: const Color.fromRGBO(56, 62, 77, 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  errorText: _dateError,
                  errorStyle: const TextStyle(color: Colors.red),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.black54),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color.fromRGBO(239, 235, 226, 1),
                              ),
                            ),
                            child: Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CalendarDatePicker(
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2025, 12, 31),
                                    onDateChanged: (date) {
                                      setState(() {
                                        _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                                      });
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                          ),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _timeController,
                readOnly: true,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Color(0xFF383E4D),
                ),
                decoration: InputDecoration(
                  labelText: 'Time',
                  labelStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    color: const Color.fromRGBO(56, 62, 77, 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  errorText: _timeError,
                  errorStyle: const TextStyle(color: Colors.red),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time, color: Colors.black54),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: const Color.fromRGBO(239, 235, 226, 1),
                                onPrimary: Colors.black,
                                surface: const Color.fromRGBO(239, 235, 226, 1),
                                onSurface: Colors.black,
                                secondaryContainer: const Color.fromRGBO(239, 235, 226, 1),
                              ),
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: Colors.white,
                                hourMinuteColor: const Color.fromRGBO(239, 235, 226, 1),
                                hourMinuteTextColor: Colors.black,
                                dialBackgroundColor: Colors.white,
                                dialHandColor: const Color.fromRGBO(239, 235, 226, 1),
                                dialTextColor: Colors.black,
                                entryModeIconColor: Colors.black,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() {
                          _timeController.text = time.format(context);
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _notesController,
                cursorColor: const Color.fromRGBO(0, 0, 0, 0.7),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                style: const TextStyle(
                  color: Color(0xFF383E4D),
                ),
                decoration: InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(
                    color: const Color.fromRGBO(56, 62, 77, 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  errorText: _notesError,
                  errorStyle: const TextStyle(color: Colors.red),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onAddTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(239, 235, 226, 1),
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'ADD TASK',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryButton(task_model.TaskCategory category, IconData icon) {
    final bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          print('Selected category: ${category.name.toLowerCase()}');
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromRGBO(0, 0, 0, 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.black : const Color.fromRGBO(0, 0, 0, 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: Colors.black,
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}

DateTime parseDate(String dateString) {
  try {
    return DateFormat('yyyy-MM-dd').parse(dateString);
  } catch (e) {
    print('Error parsing date: $e');
    return DateTime.now();
  }
}

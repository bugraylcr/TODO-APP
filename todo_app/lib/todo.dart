
import 'package:flutter/material.dart';
import 'addtask.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'task.dart' show TaskCategory, TaskCategoryExtension;

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tasks = [];
  final List<Task> _completedTasks = [];
  Task? _lastDeletedTask;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await supabase.from('todo_tasks').select();
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching tasks: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTasks() async {
    if (_lastDeletedTask != null) {
      
      await supabase.from('todo_tasks').delete().eq('id', _lastDeletedTask!.id);
      await supabase.from('todo_tasks').insert({
        'task_title': _lastDeletedTask?.title,
        'task_notes': _lastDeletedTask?.notes,
        'task_date': _lastDeletedTask?.date,
        'task_time': _lastDeletedTask?.taskTime,
      });
    }
  }

  Task? _lastMovedTask;
  bool? _lastMovedWasCompleted;

  void _toggleTaskStatus(Task task) {
    setState(() {
      _lastMovedTask = task;
      _lastMovedWasCompleted = task.completed;

      if (task.completed) {
        _completedTasks.removeWhere((t) => t.id == task.id);
        _tasks.add(task.toMap());
      } else {
        _tasks.removeWhere((t) => t['id'] == task.id);
        _completedTasks.add(task.copyWith(completed: true));
      }
    });
    _saveTasks();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          task.completed ? 'Task marked as uncompleted' : 'Task marked as completed',
        ),
        duration: const Duration(milliseconds: 1500),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color.fromARGB(255, 228, 218, 218).withOpacity(0.4),
          onPressed: _undoLastMove,
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _undoLastMove() {
    if (_lastMovedTask == null || _lastMovedWasCompleted == null) return;

    setState(() {
      if (_lastMovedWasCompleted!) {
        _tasks.removeWhere((t) => t['id'] == _lastMovedTask!.id);
        _completedTasks.add(_lastMovedTask!.copyWith(completed: true));
      } else {
        _completedTasks.removeWhere((t) => t.id == _lastMovedTask!.id);
        _tasks.add(_lastMovedTask!.toMap());
      }

      _lastMovedTask = null;
      _lastMovedWasCompleted = null;
    });
    _saveTasks();
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      await supabase.from('todo_tasks').delete().eq('id', taskId);
      _fetchTasks(); 
    } catch (error) {
      print('Error deleting task: $error');
    }
  }

  dynamic _addTask(Task task) async {
    try {
      await supabase.from('todo_tasks').insert({
        'task_title': task.title,
        'task_notes': task.notes,
        'task_date': task.date, 
        'task_time': task.time ?? '',
        'task_category': task.category.index, 
      });
      await _fetchTasks();
    } catch (error) {
      print('Error adding task: $error');
    }
    return null;
  }

  void onTaskAdded(Task task) {
    setState(() {
      _tasks.add({
        'id': task.id,
        'task_title': task.title,
        'task_notes': task.notes,
        'task_date': task.date, 
        'task_time': task.time,
        'task_category': task.category.index,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFEBE2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            SystemNavigator.pop();
          },
        ),
        centerTitle: true,
        title: const Text(
          'My Todo List',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Uncompleted',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF383E4D),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final taskMap = _tasks[index];
                      final taskDateString = taskMap['task_date']?.toString() ?? '';
                      
                      
                      print('Raw category value from database: ${taskMap['task_category']}');
                      
                    
                      TaskCategory category;
                      final categoryValue = taskMap['task_category'];
                      
                      if (categoryValue is int) {
                        if (categoryValue >= 0 && categoryValue < TaskCategory.values.length) {
                          category = TaskCategory.values[categoryValue];
                        } else {
                          category = TaskCategory.study;
                        }
                      } else if (categoryValue is String && categoryValue.isNotEmpty) {
                        
                        if (int.tryParse(categoryValue) != null) {
                          final index = int.parse(categoryValue);
                          category = TaskCategory.values[index];
                        } else {
                          
                          switch(categoryValue.toLowerCase()) {
                            case 'study':
                              category = TaskCategory.study;
                              break;
                            case 'event':
                              category = TaskCategory.event;
                              break;
                            case 'achievement':
                              category = TaskCategory.achievement;
                              break;
                            default:
                              category = TaskCategory.study;
                          }
                        }
                      } else {
                        category = TaskCategory.study;
                      }
                      
                     
                      print('Converted category: $category');
                          
                      final task = Task(
                        id: taskMap['id'],
                        title: taskMap['task_title'] as String,
                        category: category,
                        notes: taskMap['task_notes'] as String,
                        completed: taskMap['task_completed'] == 1,
                        taskDate: taskDateString.isNotEmpty
                            ? DateTime.parse(taskDateString)
                            : DateTime.now(),
                        taskTime: taskMap['task_time'] ?? '',
                        date: taskDateString,
                        time: taskMap['task_time'] ?? '',
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TodoItem(
                          task: task,
                          onToggle: _toggleTaskStatus,
                          onDelete: _deleteTask,
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF383E4D),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _completedTasks.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TodoItem(
                          task: _completedTasks[index],
                          onToggle: _toggleTaskStatus,
                          onDelete: _deleteTask,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFEFEBE2),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTaskPage(onTaskAdded: (task) {
                 
                  _addTask(Task(
                    id: task.id,
                    title: task.title,
                    category: task.category,
                    time: task.time,
                    notes: task.notes,
                    date: task.date,
                  ));
                }),
              ),
            );
          },
          label: const Text(
            'ADD TASK',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class TodoItem extends StatelessWidget {
  final Task task;
  final Function(Task) onToggle;
  final Function(int) onDelete;

  const TodoItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  IconData _getCategoryIcon(TaskCategory category) { 
    switch (category) {
      case TaskCategory.study:
        return Icons.book;
      case TaskCategory.event:
        return Icons.calendar_today;
      case TaskCategory.achievement:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromRGBO(56, 62, 77, 0.1),
          child: Icon(
            _getCategoryIcon(task.category),
            color: const Color(0xFF383E4D),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: const Color(0xFF383E4D),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: task.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            if (task.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final TextPainter textPainter = TextPainter(
                    text: TextSpan(
                      text: task.notes,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color.fromRGBO(56, 62, 77, 0.5),
                        fontSize: 14,
                      ),
                    ),
                    maxLines: 2,
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: constraints.maxWidth);

                  final bool hasOverflow = textPainter.didExceedMaxLines;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.notes,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Color.fromRGBO(56, 62, 77, 0.5),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasOverflow) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                          
                          },
                          child: const Text(
                            'More',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Color(0xFF383E4D),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
        subtitle: task.time != null && task.time!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  task.time!,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color.fromRGBO(56, 62, 77, 0.5),
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task.completed,
              activeColor: const Color.fromARGB(80, 117, 97, 51),
              onChanged: (_) => onToggle(task),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color.fromARGB(255, 88, 87, 87)),
              onPressed: () => onDelete(task.id),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}

class Task {
  final int id;
  final String title;
  final TaskCategory category;
  final String? time;
  final String notes;
  final bool completed;
  final DateTime? taskDate;
  final String? taskTime;
  final String date;

  Task({
    required this.id,
    required this.title,
    required this.category,
    this.time,
    required this.notes,
    this.completed = false,
    this.taskDate,
    this.taskTime,
    required this.date,
  });

  Task copyWith({
    int? id,
    String? title,
    TaskCategory? category,
    String? time,
    String? notes,
    bool? completed,
    DateTime? taskDate,
    String? taskTime,
    String? date,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      taskDate: taskDate ?? this.taskDate,
      taskTime: taskTime ?? this.taskTime,
      date: date ?? this.date,
    );
  }

  Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['task_title'],
      category: TaskCategoryExtension.fromIndex(map['task_category'] as int),
      time: map['task_time'],
      notes: map['task_notes'],
      date: map['task_date'],
      completed: map['task_completed'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_title': title,
      'task_category': category.index,
      'task_time': time,
      'task_notes': notes,
      'task_completed': completed,
      'task_date': date, 
    };
  }
}

class TaskRepository {
  Future<List<List<Task>>> loadTasks() async {
    await Future.delayed(const Duration(seconds: 1));
    return [[], []];
  }

  Future<void> saveTasks(List<Task> tasks, List<Task> completedTasks) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}

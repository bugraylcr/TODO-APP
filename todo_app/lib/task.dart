enum TaskCategory {
  study,    // index: 0
  event,    // index: 1
  achievement  // index: 2
}

extension TaskCategoryExtension on TaskCategory {
  static TaskCategory fromIndex(int index) {
    if (index >= 0 && index < TaskCategory.values.length) {
      return TaskCategory.values[index];
    }
    return TaskCategory.study; // Varsayılan değer
  }

  int get index => this.index;

  String get name {
    switch (this) {
      case TaskCategory.study:
        return 'study';
      case TaskCategory.event:
        return 'event';
      case TaskCategory.achievement:
        return 'achievement';
    }
  }

  static TaskCategory fromString(String category) {
    switch (category) {
      case 'event':
        return TaskCategory.event;
      case 'achievement':
        return TaskCategory.achievement;
      case 'study':
      default:
        return TaskCategory.study;
    }
  }
}

class Task {
  final int id;
  final String title;
   final TaskCategory category ;  // enum'u burada kullanıyoruz
  final String? time;
  final String notes;
  final String date;
  final bool completed;

  Task({ // burası bir  constructor 
    required this.id,
    required this.title,
    required this.category,
    this.time,
    required this.notes,
    required this.date,
    required this.completed,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      category: TaskCategoryExtension.fromString(json['category'] as String),
      time: json['time'] as String?,
      notes: json['notes'] as String,
      date: json['date'] as String,
      completed: json['completed'] == 1,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    print('Creating Task from map: $map'); // Debug için
    final categoryIndex = map['task_category'] as int? ?? 0;
    print('Category index: $categoryIndex'); // Debug için
    
    return Task(
      id: map['id'],
      title: map['task_title'],
      category: TaskCategoryExtension.fromIndex(categoryIndex),
      time: map['task_time'],
      notes: map['task_notes'],
      date: map['task_date'],
      completed: map['task_completed'] == 1,
    );
  }
 
 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'time': time,
      'notes': notes,
      'date': date,
      'completed': completed ? 1 : 0,
    };
  }
}

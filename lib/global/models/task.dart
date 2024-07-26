import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Task {
  final String id;
  final String name;
  final String description;
  final String priority;
  final DateTime deadline;
  final bool isCompleted;
  final bool isCollaborationTask; // Indicates if the task is a collaboration task
  final bool isCompletedPending; // Pending completion status
  final bool isDeletePending; // Pending deletion status
  final bool completedByBoth; // Indicates if both users have confirmed completion
  final List<String>? collaborators; // List of collaborator usernames
  final bool? isCollaborative; // Indicates if the task is collaborative
  final String? assigneeProfilePictureUrl;
  final String? assignerProfilePictureUrl;

  Task({
    required this.id,
    required this.name,
    required this.description,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
    this.isCollaborationTask = false,
    this.isCompletedPending = false,
    this.isDeletePending = false,
    this.completedByBoth = false,
    required this.collaborators,
    required this.isCollaborative,
    this.assigneeProfilePictureUrl,
    this.assignerProfilePictureUrl,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'Low',
      deadline: (data['deadline'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      isCollaborationTask: data['isCollaborationTask'] ?? false,
      isCompletedPending: data['isCompletedPending'] ?? false,
      isDeletePending: data['isDeletePending'] ?? false,
      completedByBoth: data['completedByBoth'] ?? false,
      collaborators: List<String>.from(data['collaborators'] ?? []),
      isCollaborative: data['isCollaborative'] ?? false,
      assigneeProfilePictureUrl: data['assigneeProfilePictureUrl'] ?? '',
      assignerProfilePictureUrl: data['assignerProfilePictureUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priority': priority,
      'deadline': Timestamp.fromDate(deadline),
      'isCompleted': isCompleted,
      'isCollaborationTask': isCollaborationTask,
      'isCompletedPending': isCompletedPending,
      'isDeletePending': isDeletePending,
      'completedByBoth': completedByBoth,
      'collaborators': collaborators ?? [],
      'isCollaborative': isCollaborative,
      'assigneeProfilePictureUrl': assigneeProfilePictureUrl,
      'assignerProfilePictureUrl': assignerProfilePictureUrl,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory Task.fromJson(Map<String, dynamic> json, String id) {
    return Task(
      id: id,
      name: json['name'],
      description: json['description'],
      priority: json['priority'],
      deadline: (json['deadline'] as Timestamp).toDate(),
      isCompleted: json['isCompleted'],
      isCollaborationTask: json['isCollaborationTask'] ?? false,
      isCompletedPending: json['isCompletedPending'] ?? false,
      isDeletePending: json['isDeletePending'] ?? false,
      completedByBoth: json['completedByBoth'] ?? false,
      collaborators: List<String>.from(json['collaborators'] ?? []),
      isCollaborative: json['isCollaborative'],
      assigneeProfilePictureUrl: json['assigneeProfilePictureUrl'],
      assignerProfilePictureUrl: json['assignerProfilePictureUrl'],
    );
  }

  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      priority: map['priority'],
      deadline: (map['deadline'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'],
      isCollaborationTask: map['isCollaborationTask'] ?? false,
      isCompletedPending: map['isCompletedPending'] ?? false,
      isDeletePending: map['isDeletePending'] ?? false,
      completedByBoth: map['completedByBoth'] ?? false,
      collaborators: List<String>.from(map['collaborators'] ?? []),
      isCollaborative: map['isCollaborative'],
      assigneeProfilePictureUrl: map['assigneeProfilePictureUrl'],
      assignerProfilePictureUrl: map['assignerProfilePictureUrl'],
    );
  }

  Task copyWith({
    String? id,
    String? name,
    String? description,
    String? priority,
    DateTime? deadline,
    bool? isCompleted,
    bool? isCollaborationTask,
    bool? isCompletedPending,
    bool? isDeletePending,
    bool? completedByBoth,
    List<String>? collaborators,
    bool? isCollaborative,
    String? assigneeProfilePictureUrl,
    String? assignerProfilePictureUrl,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      isCollaborationTask: isCollaborationTask ?? this.isCollaborationTask,
      isCompletedPending: isCompletedPending ?? this.isCompletedPending,
      isDeletePending: isDeletePending ?? this.isDeletePending,
      completedByBoth: completedByBoth ?? this.completedByBoth,
      collaborators: collaborators ?? this.collaborators,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      assigneeProfilePictureUrl: assigneeProfilePictureUrl ?? this.assigneeProfilePictureUrl,
      assignerProfilePictureUrl: assignerProfilePictureUrl ?? this.assignerProfilePictureUrl,
    );
  }

  

  static CollectionReference getUserTasksCollection(User user) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks');
  }

  static CollectionReference getUserCompletedTasksCollection(User user) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('completed_tasks');
  }
}

// Add the task, get user tasks, completed tasks, move task to completed, and undo task completion methods as before.

void moveTaskToCompleted(Task task, User user) async {
  final tasksCollection = Task.getUserTasksCollection(user);
  final completedTasksCollection = Task.getUserCompletedTasksCollection(user);

  await tasksCollection.doc(task.id).delete();
  await completedTasksCollection.doc(task.id).set(task.copyWith(isCompleted: true).toMap());
}

void undoTaskCompletion(Task task, User user) async {
  final tasksCollection = Task.getUserTasksCollection(user);
  final completedTasksCollection = Task.getUserCompletedTasksCollection(user);

  await completedTasksCollection.doc(task.id).delete();
  await tasksCollection.doc(task.id).set(task.copyWith(isCompleted: false).toMap());
}

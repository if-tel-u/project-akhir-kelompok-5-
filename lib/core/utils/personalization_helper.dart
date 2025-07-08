import '../../data/models/user_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/task_model.dart';

/// Helper class to enhance personalization across the app
class PersonalizationHelper {
  /// Returns a personalized greeting based on time of day
  static String getPersonalizedGreeting(String userName) {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return '🌅 Good morning, $userName!';
    } else if (hour < 17) {
      return '☀️ Good afternoon, $userName!';
    } else {
      return '🌙 Good evening, $userName!';
    }
  }

  /// Returns a personalized productivity message based on completed tasks
  static String getProductivityMessage(int completedTasksCount) {
    if (completedTasksCount == 0) {
      return "Let's start being productive today.";
    } else if (completedTasksCount < 3) {
      return "You're making progress! Keep it up.";
    } else if (completedTasksCount < 5) {
      return "Great work today! You're being quite productive.";
    } else {
      return "Excellent work today! You're incredibly productive!";
    }
  }

  /// Filters projects where the current user is a member
  static List<ProjectModel> getCurrentUserProjects(
    List<ProjectModel> allProjects,
  ) {
    final currentUserId = UserModel.currentUser.id;
    return allProjects
        .where((project) => project.isUserMember(currentUserId))
        .toList();
  }

  /// Gets the user's role in a specific project (Admin, Member, etc.)
  static String getUserRoleInProject(ProjectModel project) {
    final currentUserId = UserModel.currentUser.id;

    if (project.creatorId == currentUserId) {
      return 'Creator';
    } else if (project.isUserAdmin(currentUserId)) {
      return 'Admin';
    } else {
      return 'Member';
    }
  }

  /// Gets priority tasks that need attention soon
  static List<TaskModel> getPriorityTasks(List<TaskModel> tasks) {
    final now = DateTime.now();

    // Get tasks due in the next 48 hours
    return tasks
        .where(
          (task) =>
              !task.isCompleted &&
              task.dueDate != null &&
              task.dueDate!.difference(now).inHours <= 48,
        )
        .toList();
  }

  /// Returns appropriate label for task due date
  static String getTaskDueDateLabel(TaskModel task) {
    if (task.dueDate == null) return '';

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference < 7) {
      return 'Due in $difference days';
    } else {
      return 'Due on ${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }
}

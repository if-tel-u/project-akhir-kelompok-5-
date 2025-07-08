import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/project_task_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/thread_model.dart';
import '../../../providers/loading_state_provider.dart';
import '../providers/home_provider.dart';
import '../../taskroom/providers/task_provider.dart';
import '../../taskroom/providers/project_task_provider.dart';
import '../../taskroom/providers/project_provider.dart';
import '../../thread/providers/thread_provider.dart';
import '../../../core/utils/personalization_helper.dart';
import 'priority_tasks_widget.dart';
// Import aliases to resolve TaskPriority conflict
import '../../../data/models/task_model.dart' as task_model;

class ReminderWidget extends StatefulWidget {
  const ReminderWidget({super.key});

  @override
  State<ReminderWidget> createState() => _ReminderWidgetState();
}

class _ReminderWidgetState extends State<ReminderWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final loadingStateProvider = Provider.of<LoadingStateProvider>(
        context,
        listen: false,
      );
      Future.microtask(() {
        if (mounted) {
          homeProvider.setTaskProvider(taskProvider);
          homeProvider.setLoadingStateProvider(loadingStateProvider);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<
      HomeProvider,
      TaskProvider,
      ProjectTaskProvider,
      ProjectProvider,
      ThreadProvider
    >(
      builder: (
        context,
        homeProvider,
        taskProvider,
        projectTaskProvider,
        projectProvider,
        threadProvider,
        child,
      ) {
        if (homeProvider.isLoading) {
          return const _LoadingReminderState();
        }
        if (homeProvider.hasError) {
          return _ErrorReminderState(
            errorMessage: homeProvider.errorMessage ?? 'Unknown error occurred',
            onRetry: () => homeProvider.refreshHomeData(),
          );
        }
        final todayDeadlines = homeProvider.todayDeadlines;
        final uncompletedDailyTasks = homeProvider.uncompletedDailyTasks;
        final completedTasksThisWeek = homeProvider.tasksCompletedThisWeek;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.notifications_active, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Important for you', style: AppTextStyles.heading3),
                ],
              ),
              const SizedBox(height: 16),
              // Subcard 1: Direct Mention
              _buildDirectMentionCard(context, threadProvider, projectProvider),
              const SizedBox(height: 16),
              // Subcard 2: Assignment Notification
              _buildAssignmentCard(
                context,
                projectTaskProvider,
                projectProvider,
              ),
              const SizedBox(height: 16),
              // ReminderBot
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤖 ReminderBot',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      todayDeadlines.isEmpty
                          ? 'You have no deadlines today. Enjoy your day!'
                          : 'You have ${todayDeadlines.length} deadline${todayDeadlines.length > 1 ? 's' : ''} today. Stay focused!',
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (todayDeadlines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...todayDeadlines
                          .take(2)
                          .map((task) => _buildDeadlineItem(task))
                          ,
                      if (todayDeadlines.length > 2) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _showReminderBotPopup(context, todayDeadlines);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'more',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Priority Tasks Section (using separate widget)
              const PriorityTasksWidget(),

              const SizedBox(height: 16),
              // What's Going On Section
              Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('What\'s Going On', style: AppTextStyles.heading3),
                ],
              ),
              const SizedBox(height: 16),
              // Daily tasks remaining
              if (uncompletedDailyTasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining today: ${uncompletedDailyTasks.length} daily task${uncompletedDailyTasks.length > 1 ? 's' : ''}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          GestureDetector(
                            onTap:
                                () => _showWhatsGoingOnPopup(
                                  context,
                                  uncompletedDailyTasks,
                                ),
                            child: Row(
                              children: const [
                                Text(
                                  'more',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Activity Log
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✅ You completed $completedTasksThisWeek your personal task${completedTasksThisWeek != 1 ? 's' : ''} this week',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectMentionCard(
    BuildContext context,
    ThreadProvider threadProvider,
    ProjectProvider projectProvider,
  ) {
    final mentions = <MessageModel>[];
    threadProvider.threadMessages.forEach((threadId, messages) {
      mentions.addAll(
        messages.where(
          (msg) => msg.mentions.any(
            (mention) =>
                mention.userId == UserModel.currentUser.id ||
                mention.mentionText == '@all',
          ),
        ),
      );
    });

    mentions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayedMentions = mentions.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
          255,
          27,
          196,
          27,
        ).withOpacity(0.2), // Ubah warna ke primary (biru)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Direct Mentions', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          if (displayedMentions.isEmpty)
            const Text('No mentions yet.', style: AppTextStyles.bodyMedium)
          else
            Column(
              children: [
                for (var message in displayedMentions)
                  _buildMentionItem(
                    context,
                    message,
                    threadProvider,
                    projectProvider,
                  ),
                if (mentions.length > 2)
                  GestureDetector(
                    onTap:
                        () => _showMentionsDialog(
                          context,
                          mentions,
                          threadProvider,
                          projectProvider,
                        ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'more',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMentionItem(
    BuildContext context,
    MessageModel message,
    ThreadProvider threadProvider,
    ProjectProvider projectProvider,
  ) {
    final thread = threadProvider.threads.firstWhere(
      (t) => t.id == message.threadId,
      orElse:
          () => ThreadModel(
            id: '',
            name: 'Unknown',
            type: ThreadType.project,
            members: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
    );
    final parentThread =
        thread.parentThreadId != null
            ? threadProvider.threads.firstWhere(
              (t) => t.id == thread.parentThreadId!,
              orElse: () => thread,
            )
            : thread;
    final project = projectProvider.getProjectById(
      parentThread.projectId ?? '',
    );
    final threadName =
        project != null ? '${project.name} > ${thread.name}' : thread.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${message.sender.name} mentioned you in Thread $threadName :',
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '"${message.content}"',
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/thread',
                arguments: message.threadId,
              );
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    ProjectTaskProvider projectTaskProvider,
    ProjectProvider projectProvider,
  ) {
    final assignedTasks = projectTaskProvider.assignedTasks;
    assignedTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final displayedTasks = assignedTasks.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(
          0.2,
        ), // Ubah warna ke secondary (misalnya hijau)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assigned Tasks', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          if (displayedTasks.isEmpty)
            const Text(
              'No assigned tasks yet.',
              style: AppTextStyles.bodyMedium,
            )
          else
            Column(
              children: [
                for (var task in displayedTasks)
                  _buildTaskItem(context, task, projectProvider),
                if (assignedTasks.length > 2)
                  GestureDetector(
                    onTap:
                        () => _showTasksDialog(
                          context,
                          assignedTasks,
                          projectProvider,
                        ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'more',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    ProjectTaskModel task,
    ProjectProvider projectProvider,
  ) {
    final project = projectProvider.getProjectById(task.projectId);
    final assigner = project?.members.firstWhere(
      (member) => member.userId == task.assignerId,
      orElse:
          () => ProjectMember(
            userId: task.assignerId,
            user: UserModel(id: task.assignerId, name: 'Unknown', email: ''),
            role: ProjectRole.member,
            joinedAt: DateTime.now(),
          ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${assigner?.user.name} assigned you: "${task.title}" from ${project?.name ?? 'Unknown Project'}',
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Due: ${DateFormat('d MMM yyyy').format(task.dueDate)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/project-detail',
                arguments: task.projectId,
              );
            },
            child: const Text('View Task'),
          ),
        ],
      ),
    );
  }

  void _showMentionsDialog(
    BuildContext context,
    List<MessageModel> mentions,
    ThreadProvider threadProvider,
    ProjectProvider projectProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Mentions', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          mentions
                              .map(
                                (message) => _buildMentionItem(
                                  context,
                                  message,
                                  threadProvider,
                                  projectProvider,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTasksDialog(
    BuildContext context,
    List<ProjectTaskModel> tasks,
    ProjectProvider projectProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Assigned Tasks', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          tasks
                              .map(
                                (task) => _buildTaskItem(
                                  context,
                                  task,
                                  projectProvider,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeadlineItem(TaskModel task) {
    return Builder(
      builder:
          (context) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _getPriorityColor(task.priority),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getPriorityColor(task.priority),
                    ),
                  ),
                ),
                if (task.dueTime != null)
                  Text(
                    task.dueTime!.format(context),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildDailyTaskItem(TaskModel task) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔥 ${task.streak}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (task.streak > 0)
                  Text(
                    ' day${task.streak > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(task_model.TaskPriority? priority) {
    switch (priority) {
      case task_model.TaskPriority.high:
        return Colors.red;
      case task_model.TaskPriority.medium:
        return Colors.orange;
      case task_model.TaskPriority.low:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // Build priority task item widget with due date label from PersonalizationHelper
  Widget _buildPriorityTaskItem(TaskModel task, BuildContext context) {
    final dueDateLabel = PersonalizationHelper.getTaskDueDateLabel(task);
    final isOverdue = dueDateLabel == 'Overdue';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.withAlpha(20) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isOverdue ? Colors.red.withAlpha(100) : Colors.grey.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.access_time,
            size: 16,
            color: isOverdue ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  dueDateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey[700],
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              final taskProvider = Provider.of<TaskProvider>(
                context,
                listen: false,
              );

              if (value != null) {
                if (value) {
                  taskProvider.completeTask(task.id);
                } else {
                  taskProvider.uncompleteTask(task.id);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPriorityTasksPopup(
    BuildContext context,
    List<TaskModel> priorityTasks,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Priority Tasks'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: priorityTasks.length,
                itemBuilder: (context, index) {
                  return _buildPriorityTaskItem(priorityTasks[index], context);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showReminderBotPopup(BuildContext context, List<TaskModel> tasks) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Deadlines", style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          tasks
                              .map((task) => _buildDeadlineItem(task))
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWhatsGoingOnPopup(BuildContext context, List<TaskModel> tasks) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Tasks', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          tasks
                              .map((task) => _buildDailyTaskItem(task))
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Loading state widget
class _LoadingReminderState extends StatelessWidget {
  const _LoadingReminderState();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your tasks and deadlines...'),
            ],
          ),
        ),
      ),
    );
  }
}

// Error state widget
class _ErrorReminderState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorReminderState({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load reminders',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

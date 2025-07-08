import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../providers/home_provider.dart';
import '../../../core/utils/personalization_helper.dart';
import '../../taskroom/providers/task_provider.dart';

class PriorityTasksWidget extends StatelessWidget {
  const PriorityTasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        final priorityTasks = PersonalizationHelper.getPriorityTasks([
          ...homeProvider.todayDeadlines,
          ...homeProvider.upcomingDeadlines,
        ]);

        if (priorityTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ High Priority Tasks',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'These tasks need your attention in the next 48 hours',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...priorityTasks
                  .take(3)
                  .map((task) => _buildPriorityTaskItem(context, task)),
              if (priorityTasks.length > 3)
                GestureDetector(
                  onTap: () => _showPriorityTasksPopup(context, priorityTasks),
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
          ),
        );
      },
    );
  }

  // Build priority task item widget with due date label from PersonalizationHelper
  Widget _buildPriorityTaskItem(BuildContext context, TaskModel task) {
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
              if (value != null) {
                final taskProvider = Provider.of<TaskProvider>(
                  context,
                  listen: false,
                );
                // Use completeTask or markTaskAsComplete based on your API
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
                  return _buildPriorityTaskItem(context, priorityTasks[index]);
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
}

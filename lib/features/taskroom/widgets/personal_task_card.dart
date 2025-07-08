import 'package:flutter/material.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class PersonalTaskCard extends StatelessWidget {
  const PersonalTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Assume we have no tasks for the empty state example
  final taskProvider = Provider.of<TaskProvider>(context);
  final bool hasPersonalTasks = taskProvider.tasks.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person, color: AppColors.secondary),
                SizedBox(width: 8),
                Text('Your Personal Task', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 16),
            
            if (hasPersonalTasks)
              // Show personal tasks list
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Access your task'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to personal task detail
                   Navigator.pushNamed(context, '/personal-task');
                },
              )
            else
              // Show empty state
              SizedBox(
                height: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('+ Let\'s get moving.', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Looks a little empty in here. Add your first personal task and make it yours.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Add personal task
                        Navigator.pushNamed(context, '/create-task');
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
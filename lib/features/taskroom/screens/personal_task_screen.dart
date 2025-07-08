import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/daily_task_list.dart';
import '../widgets/deadline_task_list.dart';

class PersonalTaskScreen extends StatefulWidget {
  const PersonalTaskScreen({super.key});

  @override
  State<PersonalTaskScreen> createState() => _PersonalTaskScreenState();
}

class _PersonalTaskScreenState extends State<PersonalTaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Personal Tasks'),
        actions: [
          // Tambahkan action button hanya jika ada completed deadline tasks
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              final hasCompletedDeadlines = provider.deadlineTasks.any(
                (task) => task.isCompleted,
              );

              return hasCompletedDeadlines
                  ? IconButton(
                    icon: const Icon(Icons.cleaning_services),
                    tooltip: 'Remove completed tasks',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Clean Completed Tasks'),
                              content: const Text(
                                'Remove all completed deadline tasks?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Provider.of<TaskProvider>(
                                      context,
                                      listen: false,
                                    ).cleanCompletedDeadlineTasks();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Completed tasks removed',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Clean'),
                                ),
                              ],
                            ),
                      );
                    },
                  )
                  : SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.repeat), text: 'Daily Activities'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Deadline Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Daily Tasks Tab
          DailyTaskList(),

          // Deadline Tasks Tab
          DeadlineTaskList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-task');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/navigation/bottom_nav_bar.dart';
import '../../../data/models/user_model.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/project_list_widget.dart';
import '../widgets/reminder_widget.dart';
import '../../../core/utils/responsive_utils.dart';
import '../providers/home_provider.dart';
import '../../taskroom/providers/task_provider.dart';
import '../../../providers/loading_state_provider.dart';
import '../../../core/utils/personalization_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize providers after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    // Use context.mounted to prevent setState after dispose
    if (!mounted) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final loadingStateProvider = Provider.of<LoadingStateProvider>(
      context,
      listen: false,
    );

    // Set providers
    homeProvider.setTaskProvider(taskProvider);
    homeProvider.setLoadingStateProvider(loadingStateProvider);

    // Load initial data (in a future to avoid setState during build)
    Future.microtask(() async {
      await homeProvider.loadHomeData();
    });
  }

  // Pull to refresh functionality
  Future<void> _handleRefresh() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await homeProvider.refreshHomeData();
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, _) {
            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                // Set physics to AlwaysScrollableScrollPhysics to enable pull-to-refresh even when content is small
                physics: const AlwaysScrollableScrollPhysics(),
                padding: ResponsiveUtils.getScreenPadding(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.getCardWidth(context),
                      // Ensure minimum height for the RefreshIndicator to work
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome section with personalized greeting
                        Text(
                          PersonalizationHelper.getPersonalizedGreeting(
                            UserModel.currentUser.name,
                          ),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Consumer<HomeProvider>(
                          builder: (context, provider, _) {
                            // Show personalized productivity message based on completed tasks
                            return Text(
                              PersonalizationHelper.getProductivityMessage(
                                provider.tasksCompletedThisWeek,
                              ),
                              style: const TextStyle(fontSize: 16),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Calendar widget
                        const CalendarWidget(),
                        const SizedBox(height: 24),

                        // Project list section
                        const ProjectListWidget(),
                        const SizedBox(height: 24),
                        // Reminder section
                        const ReminderWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;

          switch (index) {
            case 0:
              // Already on Home
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/taskroom');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/thread');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Buka dialog atau screen untuk menambahkan task/project
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Create New'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.task),
                        title: const Text('Create Task'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/create-task');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.folder),
                        title: const Text('Create Project'),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to create project
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

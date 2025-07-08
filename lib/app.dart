// File: lib/app.dart (Updated with Project Integration)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/themes/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/taskroom/screens/taskroom_screen.dart';
import 'features/thread/screens/thread_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'providers/loading_state_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/taskroom/providers/task_provider.dart';
import 'features/taskroom/providers/project_provider.dart'; // NEW
import 'features/thread/providers/thread_provider.dart';
import 'features/taskroom/screens/create_task_screen.dart';
import 'features/taskroom/screens/personal_task_screen.dart';
import 'features/taskroom/screens/create_project_screen.dart'; // NEW
import 'features/taskroom/screens/project_detail_screen.dart';
import 'features/taskroom/screens/create_task_in_project_screen.dart'; // NEW
import 'features/taskroom/screens/edit_task_in_project_screen.dart';
import 'features/taskroom/providers/project_task_provider.dart';
import 'features/taskroom/screens/project_settings_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/profile/screens/notifications_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'config/app_scroll_behavior.dart';
import 'features/auth/providers/auth_provider.dart';

class TaskVerseApp extends StatefulWidget {
  const TaskVerseApp({super.key});

  @override
  State<TaskVerseApp> createState() => _TaskVerseAppState();
}

class _TaskVerseAppState extends State<TaskVerseApp> {
  @override
  void initState() {
    super.initState();
    // Jadwalkan cek daily reset untuk daily tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Perlu runlater karena provider belum tersedia di initState
      Future.microtask(() async {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final projectProvider = Provider.of<ProjectProvider>(
          context,
          listen: false,
        );
        final threadProvider = Provider.of<ThreadProvider>(
          context,
          listen: false,
        );
        final projectTaskProvider = Provider.of<ProjectTaskProvider>(
          context,
          listen: false,
        );
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final loadingStateProvider = Provider.of<LoadingStateProvider>(
          context,
          listen: false,
        );
        final homeProvider = Provider.of<HomeProvider>(
          context,
          listen: false,
        ); // Connect loading state provider to other providers
        projectProvider.setLoadingStateProvider(loadingStateProvider);
        homeProvider.setLoadingStateProvider(loadingStateProvider);
        taskProvider.setLoadingStateProvider(
          loadingStateProvider,
        ); // Cek auth status
        loadingStateProvider.setModuleLoading(
          'auth',
          message: 'Checking authentication status...',
        );
        await authProvider
            .checkAuthStatus(); // Let the splash screen handle navigation
        loadingStateProvider.setModuleLoaded('auth');

        // Initialize task provider
        loadingStateProvider.setModuleLoading(
          'tasks',
          message: 'Initializing tasks...',
        );
        taskProvider.checkDailyReset();
        taskProvider.scheduleMidnightCleanup();
        loadingStateProvider.setModuleLoaded('tasks');

        // Initialize project provider
        loadingStateProvider.setModuleLoading(
          'projects',
          message: 'Initializing projects...',
        );
        projectProvider.setThreadProvider(threadProvider);
        await projectProvider.fetchProjects();
        projectTaskProvider.setProjectProvider(projectProvider);
        loadingStateProvider.setModuleLoaded('projects');

        // Initialize thread provider
        loadingStateProvider.setModuleLoading(
          'threads',
          message: 'Initializing threads...',
        );
        await threadProvider.fetchThreads();
        loadingStateProvider.setModuleLoaded('threads');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskVerse',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/taskroom': (context) => const TaskRoomScreen(),
        '/thread': (context) => const ThreadScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/personal-task': (context) => const PersonalTaskScreen(),
        '/create-task': (context) => const CreateTaskScreen(),
        '/create-project': (context) => const CreateProjectScreen(),
        '/create-task-in-project':
            (context) => const CreateTaskInProjectScreen(), // NEW
        '/edit-task-in-project': (context) => const EditTaskInProjectScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(), // NEW
        '/project-settings':
            (context) => ProjectSettingsScreen(
              projectId: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
      onGenerateRoute: (settings) {
        // CRITICAL: Handle dynamic routes with parameters
        if (settings.name?.startsWith('/project-detail') == true) {
          final projectId = settings.arguments as String?;
          if (projectId != null) {
            return MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: projectId),
              settings: settings,
            );
          }
        }
        return null;
      },
    );
  }
}

// File: lib/main.dart (Updated with Project Provider)

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/navigation_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/taskroom/providers/task_provider.dart';
import 'features/taskroom/providers/project_provider.dart'; // NEW
import 'features/thread/providers/thread_provider.dart';
import 'app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()), // NEW
        ChangeNotifierProvider(create: (_) => ThreadProvider()),
      ],
      child: const TaskVerseApp(),
    ),
  );
}
*/

// File: lib/features/taskroom/screens/taskroom_screen.dart (Updated FAB)

/*
PERUBAHAN PADA FAB DI TASKROOM_SCREEN.dart:

floatingActionButton: UiUtils.pulseAnimation(
  child: FloatingActionButton(
    onPressed: () {
      // Show dialog to choose between Personal Task or Project Task
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create New'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: AppColors.secondary),
                ),
                title: const Text('Create Personal Task'),
                subtitle: const Text('Private task for you only'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-task');
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.group, color: AppColors.primary),
                ),
                title: const Text('Create Project Task'),
                subtitle: const Text('Collaborative workspace with team'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-project');
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
),
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../taskroom/providers/project_provider.dart';
import '../../../core/utils/personalization_helper.dart';

class ProjectListWidget extends StatefulWidget {
  const ProjectListWidget({super.key});

  @override
  _ProjectListWidgetState createState() => _ProjectListWidgetState();
}

class _ProjectListWidgetState extends State<ProjectListWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Helper function to get color based on role
  Color _getRoleColor(String role) {
    switch (role) {
      case 'Creator':
        return AppColors.primary.withAlpha(25);
      case 'Admin':
        return AppColors.primary.withAlpha(25);
      case 'Member':
        return AppColors.secondary.withAlpha(25);
      default:
        return Colors.grey.withAlpha(25);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleProjectAction(
    BuildContext context,
    String projectId,
    String projectName,
  ) {
    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );
    final project = projectProvider.getProjectById(projectId);
    final isAdmin =
        project != null && project.isUserAdmin(UserModel.currentUser.id);

    if (isAdmin) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Project'),
              content: Text('Are you sure you want to delete "$projectName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    projectProvider.deleteProject(projectId);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Leave Project'),
              content: Text('Are you sure you want to leave "$projectName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    projectProvider.removeMemberFromProject(
                      projectId,
                      UserModel.currentUser.id,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Leave',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        // Use PersonalizationHelper to get only projects for current user
        final userProjects = PersonalizationHelper.getCurrentUserProjects(
          projectProvider.projects,
        );
        final hasProjects = userProjects.isNotEmpty;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.folder, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Your Project List',
                          style: AppTextStyles.heading3,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (projectProvider.isLoading)
                  const SizedBox(
                    height: 80,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Loading projects...',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (projectProvider.errorMessage != null)
                  SizedBox(
                    height: 120, // Increased height to fit content
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 24,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Failed to load projects',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              projectProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: () => projectProvider.fetchProjects(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (hasProjects)
                  Column(
                    children: [
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: userProjects.length,
                          itemBuilder: (context, index) {
                            final project = userProjects[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  project.name,
                                  style: AppTextStyles.bodyLarge,
                                ),
                                subtitle: Row(
                                  children: [
                                    const Icon(Icons.assignment, size: 16),
                                    Text(' ${project.taskCount} Task'),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 16,
                                    ),
                                    Text(' ${project.threadCount} Thread'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(
                                          PersonalizationHelper.getUserRoleInProject(
                                            project,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        PersonalizationHelper.getUserRoleInProject(
                                          project,
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              project.isUserAdmin(
                                                    UserModel.currentUser.id,
                                                  )
                                                  ? AppColors.primary
                                                  : AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed:
                                          () => _handleProjectAction(
                                            context,
                                            project.id,
                                            project.name,
                                          ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 16),
                                  ],
                                ),
                                onTap: () {
                                  print(
                                    '🔧 Navigating to project detail: ${project.id} (${project.name})',
                                  );
                                  Navigator.pushNamed(
                                    context,
                                    '/project-detail',
                                    arguments: project.id,
                                  ).then((_) {
                                    projectProvider.fetchProjects();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _animation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off_outlined,
                              size: 60,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Projects Yet!',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                'Let’s kick off your first project! Create one now and start collaborating with your team.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _controller.forward(from: 0); // Reset animasi
                                Navigator.pushNamed(
                                  context,
                                  '/create-project',
                                ).then((_) {
                                  projectProvider.fetchProjects();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Start Your First Project'),
                            ),
                          ],
                        ),
                      ),
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

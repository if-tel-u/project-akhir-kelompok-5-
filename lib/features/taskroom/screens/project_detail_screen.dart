import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
// Add Logger import
import '../../../data/models/project_model.dart';
import '../../../data/models/project_task_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/project_provider.dart';
import '../providers/project_task_provider.dart';
import '../widgets/project_task_card_task.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../helpers/thread_integration_help.dart';
import '../../thread/providers/thread_provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProjectModel? project;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // PERBAIKAN: Validasi projectId sebelum dipanggil
    if (widget.projectId.isEmpty) {
      print('❌ ProjectDetailScreen: Empty projectId received in initState');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/taskroom');
        }
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final projectProvider = Provider.of<ProjectProvider>(
        context,
        listen: false,
      );
      final foundProject = projectProvider.getProjectById(widget.projectId);

      if (foundProject != null) {
        setState(() {
          project = foundProject;
        });
        // Fetch project tasks
        Provider.of<ProjectTaskProvider>(
          context,
          listen: false,
        ).fetchTasksByProjectId(widget.projectId);
      } else {
        print(
          '❌ ProjectDetailScreen: Project with ID "${widget.projectId}" not found',
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/taskroom');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/taskroom');
            },
          ),
        ),
        body: const EmptyStateWidget(
          message:
              'Project not found\nTry creating a new project to get started',
          icon: Icons.error_outline,
        ),
      );
    }

    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: screenHeight * 0.22,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double top = constraints.biggest.height;
                  final bool isCollapsed =
                      top <=
                      kToolbarHeight + MediaQuery.of(context).padding.top;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: isCollapsed ? 0 : 10,
                          left: 12,
                          right: 12,
                          bottom: isCollapsed ? 10 : kToolbarHeight,
                        ),
                        child: Row(
                          crossAxisAlignment:
                              isCollapsed
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/taskroom',
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      isCollapsed ? 20 : screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                                child: Text(
                                  project!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Container(
                  height: kToolbarHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontFamily: 'Montserrat',
                    ),
                    unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'Montserrat',
                    ),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Tasks'),
                      Tab(text: 'Members'),
                    ],
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(screenWidth, screenHeight),
                  _buildTasksTab(screenWidth, screenHeight),
                  _buildMembersTab(screenWidth, screenHeight),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildProjectFAB(),
    );
  }

  Widget _buildOverviewTab(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project!.description != null) ...[
            Text(
              'Description',
              style: AppTextStyles.heading3.copyWith(
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.045,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                project!.description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: screenWidth * 0.035,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
          ],
          Text(
            'Quick Actions',
            style: AppTextStyles.heading3.copyWith(
              fontFamily: 'Montserrat',
              fontSize: screenWidth * 0.045,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  emoji: '💬',
                  title: 'Open Thread',
                  subtitle: 'Join project discussion',
                  onTap: () => _openProjectThread(),
                  screenWidth: screenWidth,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: _buildActionCard(
                  emoji: '📋',
                  title: 'Add Task',
                  subtitle: 'Create new project task',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/create-task-in-project',
                      arguments: project!.id,
                    ).then((result) {
                      if (result == true) {
                        Provider.of<ProjectTaskProvider>(
                          context,
                          listen: false,
                        ).fetchTasksByProjectId(project!.id);
                      }
                    });
                  },
                  screenWidth: screenWidth,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            'Recent Activity',
            style: AppTextStyles.heading3.copyWith(
              fontFamily: 'Montserrat',
              fontSize: screenWidth * 0.045,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          _buildActivityList(screenWidth),
        ],
      ),
    );
  }

  Widget _buildTasksTab(double screenWidth, double screenHeight) {
    return Consumer<ProjectTaskProvider>(
      builder: (context, taskProvider, _) {
        if (taskProvider.loadingState == ProjectTaskLoadingState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (taskProvider.loadingState == ProjectTaskLoadingState.error) {
          return EmptyStateWidget(
            message: taskProvider.errorMessage ?? 'Failed to load tasks',
            icon: Icons.error,
          );
        }
        final tasks = taskProvider.tasks;
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  Text(
                    'Project Tasks',
                    style: AppTextStyles.heading3.copyWith(
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create-task-in-project',
                        arguments: project!.id,
                      ).then((result) {
                        if (result == true) {
                          Provider.of<ProjectTaskProvider>(
                            context,
                            listen: false,
                          ).fetchTasksByProjectId(project!.id);
                        }
                      });
                    },
                    icon: Icon(Icons.add, size: screenWidth * 0.045),
                    label: Text(
                      'Add Task',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  tasks.isNotEmpty
                      ? _buildProjectTasksList(tasks, screenWidth)
                      : EmptyStateWidget(
                        message:
                            'Oops, still echoing silence...\nCreate a task to get started!',
                        icon: Icons.task_alt,
                        actionText: 'Add Task',
                        onAction: () {
                          Navigator.pushNamed(
                            context,
                            '/create-task-in-project',
                            arguments: project!.id,
                          ).then((result) {
                            if (result == true) {
                              Provider.of<ProjectTaskProvider>(
                                context,
                                listen: false,
                              ).fetchTasksByProjectId(project!.id);
                            }
                          });
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersTab(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Members (${project!.members.length})',
                style: AppTextStyles.heading3.copyWith(
                  fontFamily: 'Montserrat',
                  fontSize: screenWidth * 0.045,
                ),
              ),
              const Spacer(),
              if (project!.isUserAdmin(UserModel.currentUser.id))
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddMemberDialog();
                  },
                  icon: Icon(Icons.person_add, size: screenWidth * 0.045),
                  label: Text(
                    'Add Member',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: project!.members.length,
            itemBuilder: (context, index) {
              final member = project!.members[index];
              return _buildMemberCard(member, screenWidth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.primary.withOpacity(0.2),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFF0C9371).withAlpha(128),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: screenWidth * 0.08)),
            SizedBox(height: screenWidth * 0.02),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.035,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.03,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(double screenWidth) {
    // TODO: Replace with backend activities or remove this section if not needed
    return const Text('No recent activity');
  }

  Widget _buildProjectTasksList(
    List<ProjectTaskModel> tasks,
    double screenWidth,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: screenWidth * 0.02),
          child: ProjectTaskCard(task: tasks[index]),
        );
      },
    );
  }

  Widget _buildMemberCard(ProjectMember member, double screenWidth) {
    final isCurrentUser = member.userId == UserModel.currentUser.id;
    final canManageMembers = project!.isUserAdmin(UserModel.currentUser.id);

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF0C9371).withAlpha(128),
      child: ListTile(
        contentPadding: EdgeInsets.all(screenWidth * 0.03),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: screenWidth * 0.05,
          child: Text(
            member.user.name[0].toUpperCase(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              fontSize: screenWidth * 0.035,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.user.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: screenWidth * 0.035,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentUser) ...[
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.015,
                  vertical: screenWidth * 0.005,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    fontSize: screenWidth * 0.025,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          member.user.email,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
            fontFamily: 'Montserrat',
            fontSize: screenWidth * 0.03,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenWidth * 0.01,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleText(member.role),
                style: AppTextStyles.caption.copyWith(
                  color: _getRoleColor(member.role),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  fontSize: screenWidth * 0.025,
                ),
              ),
            ),
            if (canManageMembers && !isCurrentUser)
              PopupMenuButton(
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'change_role',
                        child: Text('Change Role'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove Member'),
                      ),
                    ],
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeMember(member);
                  } else if (value == 'change_role') {
                    _showChangeRoleDialog(member);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectFAB() {
    return FloatingActionButton(
      onPressed: () {
        _showProjectActionsDialog();
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.more_horiz, color: Colors.white),
    );
  }

  void _showProjectActionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Text('💬', style: TextStyle(fontSize: 24)),
                  title: const Text('Open Project Thread'),
                  onTap: () {
                    Navigator.pop(context);
                    _openProjectThread();
                  },
                ),
                ListTile(
                  leading: const Text('📋', style: TextStyle(fontSize: 24)),
                  title: const Text('Add Project Task'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/create-task-in-project',
                      arguments: project!.id,
                    ).then((result) {
                      if (result == true) {
                        Provider.of<ProjectTaskProvider>(
                          context,
                          listen: false,
                        ).fetchTasksByProjectId(project!.id);
                      }
                    });
                  },
                ),
                if (project!.isUserAdmin(UserModel.currentUser.id)) ...[
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Project Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/project-settings',
                        arguments: project!.id,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Future<void> _openProjectThread() async {
    if (!mounted) return;

    final threadProvider = Provider.of<ThreadProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );

    // Store BuildContext before async gap
    final currentContext = context;

    // Kalau threadId null, bikin thread baru
    if (project!.threadId == null || project!.threadId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Creating project thread...')),
      );

      try {
        final newThread = await ThreadIntegrationHelper.createProjectThread(
          project: project!,
          threadProvider: threadProvider,
        );

        // Create new project data with updated thread info
        final updatedProject = ProjectModel(
          id: project!.id,
          name: project!.name,
          description: project!.description,
          creator: project!.creator,
          creatorId: project!.creatorId,
          status: project!.status,
          members: project!.members,
          taskCount: project!.taskCount,
          threadCount: project!.threadCount + 1,
          threadId: newThread.id,
          createdAt: project!.createdAt,
          updatedAt: DateTime.now(),
        );

        // Update project in backend
        await projectProvider.updateAndRefresh(updatedProject);

        if (!mounted) return;

        // Refresh local state
        setState(() {
          project = updatedProject;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Failed to create project thread')),
        );
        return;
      }
    }

    // Validasi threadId
    if (project!.threadId == null || project!.threadId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Failed to create project thread')),
      );
      return;
    }

    // Pastiin thread ada di ThreadProvider
    final mainThreadExists = threadProvider.threads.any(
      (thread) => thread.id == project!.threadId,
    );
    if (!mainThreadExists) {
      print(
        '❌ ProjectDetailScreen: Main thread with ID ${project!.threadId} not found in ThreadProvider',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project thread not found')));
      return;
    }

    // Cari sub-thread dari project thread - PERBAIKAN UTAMA
    print(
      '🔍 ProjectDetailScreen: Fetching sub-threads for threadId: ${project!.threadId}',
    );
    final subThreads = threadProvider.getSubThreads(project!.threadId!);
    print(
      '🔍 ProjectDetailScreen: Found ${subThreads.length} sub-threads: ${subThreads.map((t) => t.name).toList()}',
    );

    // PERBAIKAN: Gunakan logika yang sama dengan ThreadAreaWidget
    late dynamic targetSubThread;

    if (subThreads.isNotEmpty) {
      // Cari #general dulu
      final generalSubThread =
          subThreads
              .where((t) => t.name.toLowerCase() == '#general')
              .firstOrNull;

      if (generalSubThread != null) {
        targetSubThread = generalSubThread;
        print(
          '🔍 ProjectDetailScreen: Found #general sub-thread: ${targetSubThread.id}',
        );
      } else {
        // Kalau #general gak ada, ambil sub-thread pertama
        targetSubThread = subThreads.first;
        print(
          '🔍 ProjectDetailScreen: #general not found, using first sub-thread: ${targetSubThread.name} (${targetSubThread.id})',
        );
      }
    } else {
      // Kalau gak ada sub-threads sama sekali, fallback ke main thread
      print(
        '⚠️ ProjectDetailScreen: No sub-threads found, falling back to main thread',
      );
      targetSubThread = threadProvider.threads.firstWhere(
        (thread) => thread.id == project!.threadId!,
      );
    }

    print(
      '🔍 ProjectDetailScreen: Selected thread to open: ${targetSubThread.name} (ID: ${targetSubThread.id})',
    );

    // Select thread - PERBAIKAN: pastikan select thread yang benar
    threadProvider.selectThread(targetSubThread.id);

    // PERBAIKAN: Gunakan navigasi yang konsisten dengan ThreadAreaWidget
    final currentRoute = ModalRoute.of(context)?.settings.name;
    print('🔍 ProjectDetailScreen: Current route: $currentRoute');

    if (currentRoute == '/thread') {
      print(
        '🔧 ProjectDetailScreen: Already on ThreadScreen, popping until ThreadScreen',
      );
      Navigator.popUntil(context, (route) => route.settings.name == '/thread');
    } else {
      print(
        '🔧 ProjectDetailScreen: Pushing to ThreadScreen with arguments: ${targetSubThread.id}',
      );
      Navigator.pushNamed(context, '/thread', arguments: targetSubThread.id);
    }
  }

  void _showAddMemberDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add member functionality - Coming Soon')),
    );
  }

  void _showChangeRoleDialog(ProjectMember member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Change role for ${member.user.name} - Coming Soon'),
      ),
    );
  }

  void _removeMember(ProjectMember member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${member.user.name} from this project?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  final projectProvider = Provider.of<ProjectProvider>(
                    context,
                    listen: false,
                  );
                  projectProvider.removeMemberFromProject(
                    project!.id,
                    member.userId,
                  );
                  setState(() {
                    project = projectProvider.getProjectById(widget.projectId);
                  });
                },
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  Color _getRoleColor(ProjectRole role) {
    switch (role) {
      case ProjectRole.admin:
        return AppColors.error;
      case ProjectRole.member:
        return AppColors.primary;
      case ProjectRole.viewer:
        return AppColors.success;
    }
  }

  String _getRoleText(ProjectRole role) {
    switch (role) {
      case ProjectRole.admin:
        return 'Admin';
      case ProjectRole.member:
        return 'Member';
      case ProjectRole.viewer:
        return 'Viewer';
    }
  }
}

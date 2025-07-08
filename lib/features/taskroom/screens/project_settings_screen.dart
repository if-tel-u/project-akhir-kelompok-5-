import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/thread_model.dart';
import '../providers/project_provider.dart';
import '../providers/project_task_provider.dart';
import '../../thread/providers/thread_provider.dart';
import '../../thread/providers/thread_extensions.dart'; // Import the extensions
import '../../taskroom/helpers/thread_integration_help.dart';

class ProjectSettingsScreen extends StatefulWidget {
  final String projectId;

  const ProjectSettingsScreen({super.key, required this.projectId});

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  ProjectModel? project;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newMemberEmailController = TextEditingController();
  final _newThreadNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(
        context,
        listen: false,
      );
      setState(() {
        project = projectProvider.getProjectById(widget.projectId);
        if (project != null) {
          _nameController.text = project!.name;
          _descriptionController.text = project!.description ?? '';
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _newMemberEmailController.dispose();
    _newThreadNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Validasi projectId
    if (widget.projectId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Settings'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: Text('Invalid project ID')),
      );
    }

    if (project == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Settings'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: Text('Project not found')),
      );
    }

    final isAdmin = project!.isUserAdmin(UserModel.currentUser.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: screenHeight * 0.15,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Settings: ${project!.name}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Settings
                  Text('General', style: AppTextStyles.heading3),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Project Name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: isAdmin,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: isAdmin,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  if (isAdmin)
                    ElevatedButton(
                      onPressed: _saveProjectDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.03),

                  // Manage Members
                  if (isAdmin) ...[
                    Text('Members', style: AppTextStyles.heading3),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _newMemberEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Add Member (Email)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ElevatedButton(
                      onPressed: _addMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add Member',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: project!.members.length,
                      itemBuilder:
                          (context, index) => _buildMemberCard(
                            project!.members[index],
                            screenWidth,
                          ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],

                  // Manage Threads
                  Text('Threads', style: AppTextStyles.heading3),
                  SizedBox(height: screenHeight * 0.02),
                  if (isAdmin && project!.threadId != null) ...[
                    TextFormField(
                      controller: _newThreadNameController,
                      decoration: const InputDecoration(
                        labelText: 'New Sub-Thread Name (e.g., #design)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ElevatedButton(
                      onPressed: _createSubThread,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create Sub-Thread',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                  Consumer<ThreadProvider>(
                    builder: (context, threadProvider, _) {
                      final subThreads = threadProvider.getSubThreads(
                        project!.threadId ?? '',
                      );
                      return subThreads.isEmpty
                          ? const Text('No sub-threads available')
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: subThreads.length,
                            itemBuilder:
                                (context, index) => _buildThreadCard(
                                  subThreads[index],
                                  screenWidth,
                                ),
                          );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Danger Zone
                  if (isAdmin) ...[
                    Text(
                      'Danger Zone',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      onPressed: _deleteProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete Project',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProjectDetails() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name cannot be empty')),
      );
      return;
    }
    final success = await Provider.of<ProjectProvider>(
      context,
      listen: false,
    ).updateProject(widget.projectId, {
      'name': _nameController.text,
      'description':
          _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
    });
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Project updated' : 'Failed to update project'),
      ),
    );

    if (success) {
      setState(() {
        project = Provider.of<ProjectProvider>(
          context,
          listen: false,
        ).getProjectById(widget.projectId);
      });
    }
  }

  Future<void> _addMember() async {
    final email = _newMemberEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    // TODO: Replace with actual backend call to get userId by email
    // For now, show error
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User lookup by email not implemented')),
    );
    return;
  }

  Future<void> _createSubThread() async {
    final threadName = _newThreadNameController.text.trim();
    if (threadName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thread name cannot be empty')),
      );
      return;
    }

    if (project!.threadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No main thread found for this project')),
      );
      return;
    }

    if (!ThreadIntegrationHelper.hasThreadPermission(
      project: project!,
      userId: UserModel.currentUser.id,
      action: ThreadAction.write, // Ganti dari 'edit' ke 'write'
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to create threads'),
        ),
      );
      return;
    }

    final threadProvider = Provider.of<ThreadProvider>(context, listen: false);
    await threadProvider.createSubThread(
      parentId: project!.threadId!,
      name: threadName.startsWith('#') ? threadName : '#$threadName',
      description: 'Discussion thread for $threadName',
      members:
          project!.members
              .map(
                (m) =>
                    ThreadIntegrationHelper.convertProjectMemberToThreadMember(
                      m,
                    ),
              )
              .toList(),
    );

    final subThreads = threadProvider.getSubThreads(project!.threadId!);
    await Provider.of<ProjectProvider>(
      context,
      listen: false,
    ).updateProject(widget.projectId, {'thread_count': subThreads.length});

    _newThreadNameController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sub-thread created')));
  }

  Future<void> _deleteProject() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Project'),
            content: Text(
              'Are you sure you want to delete ${project!.name}? This will also delete all tasks and threads.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final projectTaskProvider = Provider.of<ProjectTaskProvider>(
                    context,
                    listen: false,
                  );
                  final tasks =
                      projectTaskProvider.tasks
                          .where((t) => t.projectId == widget.projectId)
                          .toList();
                  for (var task in tasks) {
                    await projectTaskProvider.deleteProjectTask(task.id);
                  }

                  final success = await Provider.of<ProjectProvider>(
                    context,
                    listen: false,
                  ).deleteProject(widget.projectId);

                  if (success) {
                    Navigator.pushReplacementNamed(context, '/taskroom');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete project')),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  // Helper methods to update thread data through the provider
  Future<void> _updateThreadData(
    String threadId, {
    String? name,
    String? description,
  }) async {
    final threadProvider = Provider.of<ThreadProvider>(context, listen: false);
    final threadIndex = threadProvider.threads.indexWhere(
      (t) => t.id == threadId,
    );
    if (threadIndex == -1) return;

    final thread = threadProvider.threads[threadIndex];

    // Use the extension method to update thread info
    final updatedThread = thread.copyWith(
      name: name ?? thread.name,
      description: description ?? thread.description,
      updatedAt: DateTime.now(),
    );

    // Call the extension method instead of manually updating
    await threadProvider.updateThreadInfo(threadId, updatedThread);
  }

  Future<void> _deleteThreadData(String threadId) async {
    final threadProvider = Provider.of<ThreadProvider>(context, listen: false);

    // Use the extension method to remove the thread
    await threadProvider.removeThread(threadId);

    // Update project thread count
    if (mounted) {
      final remainingSubThreads = threadProvider.getSubThreads(
        project!.threadId ?? '',
      );
      await Provider.of<ProjectProvider>(context, listen: false).updateProject(
        widget.projectId,
        {'thread_count': remainingSubThreads.length},
      );
    }
  }

  Widget _buildMemberCard(ProjectMember member, double screenWidth) {
    final isCurrentUser = member.userId == UserModel.currentUser.id;
    final isAdmin = project!.isUserAdmin(UserModel.currentUser.id);

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
            ),
          ),
        ),
        title: Text(
          member.user.name,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontSize: screenWidth * 0.035,
          ),
        ),
        subtitle: Text(
          member.user.email,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
            fontFamily: 'Montserrat',
            fontSize: screenWidth * 0.03,
          ),
        ),
        trailing:
            isAdmin && !isCurrentUser
                ? PopupMenuButton(
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
                    if (value == 'change_role') {
                      _showChangeRoleDialog(member);
                    } else if (value == 'remove') {
                      _removeMember(member);
                    }
                  },
                )
                : null,
      ),
    );
  }

  Widget _buildThreadCard(ThreadModel thread, double screenWidth) {
    final isAdmin = project!.isUserAdmin(UserModel.currentUser.id);

    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF0C9371).withAlpha(128),
      child: ListTile(
        contentPadding: EdgeInsets.all(screenWidth * 0.03),
        title: Text(
          thread.name,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontSize: screenWidth * 0.035,
          ),
        ),
        subtitle: Text(
          thread.description ?? 'No description',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
            fontFamily: 'Montserrat',
            fontSize: screenWidth * 0.03,
          ),
        ),
        trailing:
            isAdmin
                ? PopupMenuButton(
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename Thread'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Thread'),
                        ),
                      ],
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameThreadDialog(thread);
                    } else if (value == 'delete') {
                      _deleteThread(thread);
                    }
                  },
                )
                : null,
      ),
    );
  }

  void _showChangeRoleDialog(ProjectMember member) {
    showDialog(
      context: context,
      builder: (context) {
        ProjectRole? selectedRole = member.role;
        return AlertDialog(
          title: Text('Change Role for ${member.user.name}'),
          content: StatefulBuilder(
            builder:
                (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile(
                      title: const Text('Admin'),
                      value: ProjectRole.admin,
                      groupValue: selectedRole,
                      onChanged:
                          (value) => setState(
                            () => selectedRole = value as ProjectRole,
                          ),
                    ),
                    RadioListTile(
                      title: const Text('Member'),
                      value: ProjectRole.member,
                      groupValue: selectedRole,
                      onChanged:
                          (value) => setState(
                            () => selectedRole = value as ProjectRole,
                          ),
                    ),
                    RadioListTile(
                      title: const Text('Viewer'),
                      value: ProjectRole.viewer,
                      groupValue: selectedRole,
                      onChanged:
                          (value) => setState(
                            () => selectedRole = value as ProjectRole,
                          ),
                    ),
                  ],
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final projectProvider = Provider.of<ProjectProvider>(
                  context,
                  listen: false,
                );

                final currentProject = projectProvider.getProjectById(
                  widget.projectId,
                );
                if (currentProject != null) {
                  final updatedMembers =
                      currentProject.members.map((m) {
                        if (m.userId == member.userId) {
                          return m.copyWith(role: selectedRole);
                        }
                        return m;
                      }).toList();

                  projectProvider.projects[projectProvider.projects.indexWhere(
                    (p) => p.id == widget.projectId,
                  )] = currentProject.copyWith(
                    members: updatedMembers,
                    updatedAt: DateTime.now(),
                  );
                  // Remove notifyListeners() call
                  // projectProvider.notifyListeners();

                  await ThreadIntegrationHelper.updateMemberRoleInProjectThreads(
                    projectId: widget.projectId,
                    userId: member.userId,
                    newRole: selectedRole!,
                    threadProvider: Provider.of<ThreadProvider>(
                      context,
                      listen: false,
                    ),
                  );

                  setState(() {
                    project = projectProvider.getProjectById(widget.projectId);
                  });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Role updated')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update role')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeMember(ProjectMember member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${member.user.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final success = await Provider.of<ProjectProvider>(
                    context,
                    listen: false,
                  ).removeMemberFromProject(widget.projectId, member.userId);
                  if (success) {
                    setState(() {
                      project = Provider.of<ProjectProvider>(
                        context,
                        listen: false,
                      ).getProjectById(widget.projectId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Member removed')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to remove member')),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  void _showRenameThreadDialog(ThreadModel thread) {
    final renameController = TextEditingController(text: thread.name);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Thread'),
            content: TextFormField(
              controller: renameController,
              decoration: const InputDecoration(labelText: 'Thread Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = renameController.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thread name cannot be empty'),
                      ),
                    );
                    return;
                  }
                  if (!ThreadIntegrationHelper.hasThreadPermission(
                    project: project!,
                    userId: UserModel.currentUser.id,
                    action: ThreadAction.deleteThread,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You do not have permission to rename threads',
                        ),
                      ),
                    );
                    return;
                  }
                  final threadProvider = Provider.of<ThreadProvider>(
                    context,
                    listen: false,
                  );
                  await _updateThreadData(
                    thread.id,
                    name: newName.startsWith('#') ? newName : '#$newName',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thread renamed')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteThread(ThreadModel thread) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Thread'),
            content: Text('Are you sure you want to delete ${thread.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (!ThreadIntegrationHelper.hasThreadPermission(
                    project: project!,
                    userId: UserModel.currentUser.id,
                    action: ThreadAction.deleteThread,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You do not have permission to delete threads',
                        ),
                      ),
                    );
                    return;
                  }

                  await _deleteThreadData(thread.id);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thread deleted')),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }

  void _checkMountedBeforeUsingContext() {
    // This is a placeholder method to document the pattern
    // Whenever we have an async operation, before using BuildContext after that:
    //   if (!mounted) return;

    // This ensures that we don't try to use the BuildContext of a widget that's
    // no longer in the tree, which would cause errors.
  }
}

// We can't extend ThreadProvider here because notifyListeners() is protected
// Instead of the extension, we'll modify the ThreadProvider class directly in the appropriate file.
// For now, let's create methods in the screen that will call the provider methods.

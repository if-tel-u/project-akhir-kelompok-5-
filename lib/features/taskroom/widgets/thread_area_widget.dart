import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/project_provider.dart';
import '../../thread/providers/thread_provider.dart';

class ThreadAreaWidget extends StatelessWidget {
  const ThreadAreaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectProvider, ThreadProvider>(
      builder: (context, projectProvider, threadProvider, child) {
        final userProjects = projectProvider.userProjects;
        final projectThreads = threadProvider.rootProjectThreads;
        
        final userProjectThreads = projectThreads.where((thread) => 
          userProjects.any((project) => project.id == thread.projectId)
        ).toList();

        // Urutkan thread berdasarkan aktivitas terbaru
        userProjectThreads.sort((a, b) {
          final aMessage = threadProvider.getLatestSubThreadMessage(a.id).message;
          final bMessage = threadProvider.getLatestSubThreadMessage(b.id).message;
          final aTime = aMessage?.createdAt ?? a.updatedAt;
          final bTime = bMessage?.createdAt ?? b.updatedAt;
          return bTime.compareTo(aTime); // Descending (terbaru di atas)
        });

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.chat, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Thread Area', style: AppTextStyles.heading3),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (userProjectThreads.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: userProjectThreads.length,
                      itemBuilder: (context, index) {
                        final thread = userProjectThreads[index];
                        final project = userProjects.firstWhere(
                          (p) => p.id == thread.projectId,
                          orElse: () => userProjects.first,
                        );

                        return Selector<ThreadProvider, ({MessageModel? message, String? subThreadName})>(
                          selector: (_, provider) => provider.getLatestSubThreadMessage(thread.id),
                          builder: (_, result, __) {
                            final summaryMessage = result.message;
                            final subThreadName = result.subThreadName;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: summaryMessage?.isUnread == true
                                    ? Border.all(color: Colors.red, width: 2)
                                    : null,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: InkWell(
                                onTap: () {
                                  // Ambil semua sub-threads
                                  final subThreads = threadProvider.getSubThreads(thread.id);
                                  
                                  // Kalau ada aktivitas (pesan), navigasi ke sub-thread terbaru
                                  if (subThreadName != null && subThreads.isNotEmpty) {
                                    final targetSubThread = subThreads.firstWhere(
                                      (t) => t.name == subThreadName,
                                      orElse: () => subThreads.first,
                                    );
                                    threadProvider.selectThread(targetSubThread.id);
                                    Navigator.pushNamed(context, '/thread', arguments: targetSubThread.id);
                                  } else {
                                    // Kalau gak ada aktivitas, default ke #general
                                    final defaultSubThread = subThreads.firstWhere(
                                      (t) => t.name == '#general',
                                      orElse: () => subThreads.first, // Fallback ke sub-thread pertama kalau #general gak ada
                                    );
                                    threadProvider.selectThread(defaultSubThread.id);
                                    Navigator.pushNamed(context, '/thread', arguments: defaultSubThread.id);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.folder,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '# Thread : ${project.name}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: project.isUserAdmin(UserModel.currentUser.id) 
                                              ? Colors.blue 
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            project.isUserAdmin(UserModel.currentUser.id)
                                                ? 'You are admin of this project'
                                                : '${project.members.length} members in this project',
                                            style: const TextStyle(fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (summaryMessage != null) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Badge notifikasi untuk pesan unread
                                          if (summaryMessage.isUnread)
                                            Container(
                                              margin: const EdgeInsets.only(right: 8, top: 2),
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Text(
                                                '!',
                                                style: TextStyle(color: Colors.white, fontSize: 10),
                                              ),
                                            ),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: summaryMessage.isUnread ? Colors.black : Colors.grey[600],
                                                  fontWeight: summaryMessage.isUnread ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: subThreadName != null ? '$subThreadName: ' : '',
                                                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                                  ),
                                                  TextSpan(text: '${summaryMessage.sender.name}: '),
                                                  ...summaryMessage.mentions.map((m) => TextSpan(
                                                    text: m.mentionText,
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                      backgroundColor: Color.fromARGB(255, 200, 220, 255),
                                                    ),
                                                  )),
                                                  TextSpan(
                                                    text: summaryMessage.content.replaceAll(RegExp(r'@\w+'), ''),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Text(
                                        'No messages yet',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        summaryMessage != null
                                            ? _getRelativeTime(summaryMessage.createdAt)
                                            : _getRelativeTime(thread.updatedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ] else if (userProjects.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sync,
                          color: Colors.blue,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Setting up project threads...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Project threads will appear here once they are created.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Oops, still echoing silence...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start a project to unlock team threads.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year.toString().substring(2)}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
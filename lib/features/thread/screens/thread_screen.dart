import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'dart:io';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../shared/navigation/bottom_nav_bar.dart';
import '../providers/thread_provider.dart';
import '../widgets/member_list_widget.dart';
import '../widgets/thread_drawer_widget.dart';
import '../widgets/message_item_widget.dart';
import '../widgets/thread_dialogs.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final int _currentIndex = 2; // Thread selected
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    // Fetch threads dan select thread berdasarkan arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final threadProvider = Provider.of<ThreadProvider>(context, listen: false);
      final threadId = ModalRoute.of(context)?.settings.arguments as String? ?? 'hq-1-1';
      threadProvider.selectThread(threadId);
      threadProvider.fetchThreads();
      _scrollToBottom();
    });

    // Tambah listener untuk scroll ke bawah setiap ada pesan baru
    Provider.of<ThreadProvider>(context, listen: false).addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Scroll to bottom when new message arrives
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThreadProvider>(
      builder: (context, threadProvider, _) {
        final selectedThread = threadProvider.selectedThread;
        final threadName = selectedThread?.name ?? '#thread';
        final threadPath = selectedThread != null 
            ? threadProvider.getThreadPath(selectedThread.id)
            : '#thread';
        final messages = threadProvider.selectedThreadMessages;
        final isSearching = threadProvider.searchQuery.isNotEmpty;
        
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(threadName, style: const TextStyle(fontSize: 18)),
                    // Search indicator
                    if (isSearching) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${messages.length} found',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (threadPath != threadName)
                  Text(
                    threadPath,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: isSearching ? AppColors.primary : null,
                ),
                onPressed: () {
                  ThreadDialogs.showSearchDialog(context, threadProvider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.people),
                onPressed: () {
                  threadProvider.toggleMembersSidebar();
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  ThreadDialogs.showMoreOptions(context, threadProvider);
                },
              ),
            ],
          ),
          drawer: ThreadDrawerWidget(provider: threadProvider),
          body: Row(
            children: [
              // Chat area
              Expanded(
                child: Column(
                  children: [
                    // Search results banner (jika sedang search)
                    if (isSearching)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: AppColors.primary.withOpacity(0.1),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Searching for "${threadProvider.searchQuery}" - ${messages.length} results',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                threadProvider.clearSearch();
                              },
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Messages area
                    Expanded(
                      child: messages.isEmpty
                          ? isSearching 
                              ? _buildNoSearchResults(threadProvider.searchQuery)
                              : _buildEmptyState(threadName)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isCurrentUser = message.sender.id == '1'; // UserModel.currentUser.id
                                final showSenderInfo = index == 0 || 
                                    messages[index - 1].sender.id != message.sender.id ||
                                    message.createdAt.difference(messages[index - 1].createdAt).inMinutes > 5;
                                
                                return MessageItemWidget(
                                  message: message,
                                  isCurrentUser: isCurrentUser,
                                  showSenderInfo: showSenderInfo,
                                  threadProvider: threadProvider,
                                  searchQuery: threadProvider.searchQuery,
                                );
                              },
                            ),
                    ),
                    
                    // Message input area
                    _buildMessageInputArea(threadProvider),
                  ],
                ),
              ),
              
              // Members sidebar (animated)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: threadProvider.showMembersSidebar ? 240 : 0,
                child: threadProvider.showMembersSidebar
                    ? const MemberListWidget()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == _currentIndex) return;
              
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/home');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/taskroom');
                  break;
                case 2:
                  // Already on Thread
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/profile');
                  break;
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String threadName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to $threadName',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'This is the beginning of your conversation.\nStart by sending a message!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages found',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'No messages match "$searchQuery"\nTry different keywords',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ThreadProvider>().clearSearch();
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputArea(ThreadProvider threadProvider) {
    final selectedThread = threadProvider.selectedThread;
    final threadName = selectedThread?.name ?? '#thread';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Type a message in $threadName...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (text) => _sendMessage(threadProvider),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: () {
              // Emoji picker - implementasi bisa ditambahkan nanti
            },
          ),
          IconButton(
            icon: const Icon(Icons.image, color: AppColors.secondary),
            onPressed: () => _showImagePicker(context, threadProvider),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppColors.secondary),
            onPressed: () => _showFilePicker(context, threadProvider),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: () => _sendMessage(threadProvider),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ThreadProvider threadProvider) {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    threadProvider.sendMessage(content: content);
    _messageController.clear();
    
    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _showImagePicker(BuildContext context, ThreadProvider threadProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to take a new photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (image != null) {
                    await threadProvider.sendImageMessage(
                      imageFile: File(image.path),
                      caption: null,
                    );
                    _scrollToBottom();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to take photo: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select image from your gallery'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (image != null) {
                    await threadProvider.sendImageMessage(
                      imageFile: File(image.path),
                      caption: null,
                    );
                    _scrollToBottom();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to select image: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilePicker(BuildContext context, ThreadProvider threadProvider) async {
    try {
      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.any,
        allowMultiple: false,
        withData: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Show confirmation
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Send File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${result.files.single.name}'),
                Text('Size: ${_formatFileSize(result.files.single.size)}'),
                const SizedBox(height: 16),
                const Text('Send this file to the thread?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          await threadProvider.sendFileMessage(
            file: file,
            caption: null,
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select file: $e')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)}MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)}GB';
  }
}
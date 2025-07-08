import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/app_colors.dart';
import '../../../config/themes/app_text_styles.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      provider.fetchNotifications(unreadOnly: _showUnreadOnly);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Notifications', showBackButton: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Show Unread Only',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontFamily: 'Montserrat',
                  ),
                ),
                Switch(
                  value: _showUnreadOnly,
                  onChanged: (value) {
                    setState(() => _showUnreadOnly = value);
                    Provider.of<NotificationProvider>(
                      context,
                      listen: false,
                    ).fetchNotifications(unreadOnly: value);
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Text(
                      provider.error!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontFamily: 'Montserrat',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (provider.notifications.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: provider.notifications.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          notification.isRead
                              ? Icons.notifications
                              : Icons.notifications_active,
                          color:
                              notification.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                        ),
                        title: Text(
                          notification.sender.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        subtitle: Text(
                          '${notification.content} • In ${notification.threadName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'Montserrat',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          if (!notification.isRead) {
                            await provider.markAsRead(notification.id);
                          }
                          if (mounted) {
                            Navigator.pushNamed(
                              context,
                              '/thread',
                              arguments: notification.threadId,
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

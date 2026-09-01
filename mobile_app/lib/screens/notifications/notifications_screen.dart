import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.alerts),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadNotifications(forceRefresh: true),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && notifications.isEmpty) {
            return const LoadingWidget(message: 'Loading safety notifications...');
          }

          if (provider.errorMessage != null && notifications.isEmpty) {
            return AppErrorWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.loadNotifications(forceRefresh: true),
            );
          }

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.policeBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 56,
                        color: AppColors.policeBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Notifications Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You will receive real-time alerts when high-risk crime zones or SOS emergencies are triggered nearby.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final isSOS = item.type.toUpperCase() == 'SOS';
                final isCrimeAlert = item.type.toUpperCase() == 'CRIME_ALERT';

                final iconColor = isSOS
                    ? AppColors.sosRed
                    : isCrimeAlert
                        ? AppColors.warning
                        : AppColors.policeBlue;

                return Card(
                  color: item.isRead
                      ? (isDark ? AppColors.cardDark : AppColors.cardLight)
                      : (isDark ? const Color(0xFF282835) : const Color(0xFFF2F5FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: item.isRead
                          ? (isDark ? Colors.white10 : Colors.black12)
                          : iconColor.withValues(alpha: 0.5),
                      width: item.isRead ? 1 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => provider.markAsRead(item.id),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSOS
                                  ? Icons.emergency_rounded
                                  : isCrimeAlert
                                      ? Icons.warning_amber_rounded
                                      : Icons.notifications_active_rounded,
                              color: iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (!item.isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                ),
                                if (item.createdAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(item.createdAt!),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

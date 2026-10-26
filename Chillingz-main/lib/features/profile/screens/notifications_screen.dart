import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_screen_header.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/notification_list_item.dart';
import '../models/notification_item.dart';
import '../providers/profile_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  ProfileProvider? _profileProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<ProfileProvider>();
      _profileProvider = provider;
      provider.loadNotifications();
      provider.markNotificationsAsSeen();
    });
  }

  @override
  void dispose() {
    // Anything that landed while the list was open counts as seen too. It is
    // deferred because notifying listeners while this screen is being unmounted
    // would rebuild the tree while the framework has it locked.
    final provider = _profileProvider;
    if (provider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.markNotificationsAsSeen();
      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final items = provider.notificationItems;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppValues.screenHorizontalPadding,
              ),
              child: Column(
                children: [
                  10.vSpace,
                  const AppScreenHeader(title: AppStrings.notificationsTitle),
                  24.vSpace,
                  Expanded(
                    child:
                        provider.isLoadingNotifications &&
                            provider.notificationItems.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: () =>
                                provider.loadNotifications(forceRefresh: true),
                            child: items.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 96),
                                      EmptyState(
                                        message: AppStrings.currentlyUnavailable,
                                        icon: Icons.notifications_none_outlined,
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return NotificationListItem(
                                        title: item.title,
                                        message: item.message,
                                        isUnread: item.isUnread,
                                        timeLabel: _formatNotificationTime(
                                          item.createdAt,
                                        ),
                                        typeLabel: _humanize(item.type),
                                        onTap: () => _openDetail(context, item),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, NotificationItem item) {
    Navigator.pushNamed(context, AppRoutes.notificationDetail, arguments: item);
  }

  static String _formatNotificationTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    final now = DateTime.now();
    final local = value.toLocal();
    final difference = now.difference(local);
    if (!difference.isNegative && difference.inMinutes < 1) {
      return 'Just now';
    }
    if (!difference.isNegative && difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (!difference.isNegative && difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (!difference.isNegative && difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  static String _humanize(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return '';
    }

    return text
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

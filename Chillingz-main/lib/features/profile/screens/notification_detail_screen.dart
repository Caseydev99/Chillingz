import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/utils/extensions.dart';
import '../../../widgets/app_screen_header.dart';
import '../models/notification_item.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatNotificationTime(item.createdAt);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppValues.screenHorizontalPadding,
            10,
            AppValues.screenHorizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppScreenHeader(title: 'Notification'),
              24.vSpace,
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.rs(18, min: 16, max: 22)),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(
                    context.rs(22, min: 20, max: 24),
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.rs(52, min: 48, max: 58),
                      height: context.rs(52, min: 48, max: 58),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.white,
                        size: context.rs(28, min: 26, max: 30),
                      ),
                    ),
                    18.vSpace,
                    Text(
                      item.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: context.rs(22, min: 20, max: 24),
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (timeLabel.isNotEmpty) ...[
                      10.vSpace,
                      _DetailMetaRow(
                        icon: Icons.schedule_rounded,
                        label: timeLabel,
                      ),
                    ],
                    if (item.type.isNotEmpty || item.status.isNotEmpty) ...[
                      12.vSpace,
                      Wrap(
                        spacing: context.rs(8, min: 7, max: 9),
                        runSpacing: context.rs(8, min: 7, max: 9),
                        children: [
                          if (item.type.isNotEmpty)
                            _DetailChip(
                              icon: Icons.category_outlined,
                              label: _humanize(item.type),
                            ),
                          if (item.status.isNotEmpty)
                            _DetailChip(
                              icon: Icons.check_circle_outline_rounded,
                              label: _humanize(item.status),
                            ),
                        ],
                      ),
                    ],
                    22.vSpace,
                    Text(
                      item.message.isEmpty
                          ? 'This notification has no additional details.'
                          : item.message,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: context.rs(15, min: 14, max: 16),
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNotificationTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year}, $hour:$minute $period';
  }

  static String _humanize(String value) {
    return value
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _DetailMetaRow extends StatelessWidget {
  const _DetailMetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: context.rs(16, min: 15, max: 17),
        ),
        context.rs(7, min: 6, max: 8).hSpace,
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: context.rs(12.5, min: 12, max: 13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(11, min: 10, max: 12),
        vertical: context.rs(7, min: 6, max: 8),
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: context.rs(15, min: 14, max: 16),
          ),
          context.rs(6, min: 5, max: 7).hSpace,
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: context.rs(12, min: 11.5, max: 13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

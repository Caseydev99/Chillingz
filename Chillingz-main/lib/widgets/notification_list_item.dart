import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/extensions.dart';

class NotificationListItem extends StatelessWidget {
  const NotificationListItem({
    super.key,
    required this.title,
    required this.message,
    this.isUnread = false,
    this.timeLabel = '',
    this.typeLabel = '',
    this.onTap,
  });

  final String title;
  final String message;
  final bool isUnread;
  final String timeLabel;
  final String typeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(12, min: 10, max: 14)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.rs(18, min: 16, max: 20)),
          child: Ink(
            padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(
                context.rs(18, min: 16, max: 20),
              ),
              border: Border.all(
                color: isUnread ? AppColors.primary : AppColors.border,
                width: isUnread ? 1.2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.rs(42, min: 38, max: 46),
                  height: context.rs(42, min: 38, max: 46),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: isUnread ? AppColors.white : AppColors.primary,
                    size: context.rs(22, min: 20, max: 24),
                  ),
                ),
                context.rs(12, min: 10, max: 14).hSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.rs(14.5, min: 14, max: 16),
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            context.rs(8, min: 7, max: 9).hSpace,
                            Container(
                              width: context.rs(8, min: 7, max: 9),
                              height: context.rs(8, min: 7, max: 9),
                              margin: const EdgeInsets.only(top: 5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      context.rs(5, min: 4, max: 6).vSpace,
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rs(12.3, min: 11.8, max: 13),
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.32,
                        ),
                      ),
                      if (timeLabel.isNotEmpty || typeLabel.isNotEmpty) ...[
                        context.rs(10, min: 8, max: 11).vSpace,
                        Wrap(
                          spacing: context.rs(8, min: 7, max: 9),
                          runSpacing: context.rs(6, min: 5, max: 7),
                          children: [
                            if (timeLabel.isNotEmpty)
                              _NotificationMetaChip(
                                icon: Icons.schedule_rounded,
                                label: timeLabel,
                              ),
                            if (typeLabel.isNotEmpty)
                              _NotificationMetaChip(
                                icon: Icons.category_outlined,
                                label: typeLabel,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                context.rs(8, min: 7, max: 9).hSpace,
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: context.rs(22, min: 20, max: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationMetaChip extends StatelessWidget {
  const _NotificationMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(9, min: 8, max: 10),
        vertical: context.rs(5, min: 4, max: 6),
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
            size: context.rs(13, min: 12, max: 14),
            color: AppColors.textSecondary,
          ),
          context.rs(5, min: 4, max: 6).hSpace,
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.rs(10.8, min: 10.3, max: 11.5),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

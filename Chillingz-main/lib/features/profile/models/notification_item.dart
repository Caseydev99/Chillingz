class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.message,
    this.isUnread = false,
    this.createdAt,
    this.type = '',
    this.status = '',
  });

  final String title;
  final String message;
  final bool isUnread;
  final DateTime? createdAt;
  final String type;
  final String status;

  NotificationItem copyWith({bool? isUnread}) {
    return NotificationItem(
      title: title,
      message: message,
      isUnread: isUnread ?? this.isUnread,
      createdAt: createdAt,
      type: type,
      status: status,
    );
  }

  factory NotificationItem.fromMap(Map<String, dynamic> data) {
    return NotificationItem(
      title:
          _firstString(data, const ['title', 'heading', 'subject']) ??
          'Notification',
      message:
          _firstString(data, const ['message', 'body', 'description']) ?? '',
      isUnread: _boolValue(
        data['isUnread'] ?? data['unread'] ?? data['read'] == false,
      ),
      createdAt: _dateValue(
        data['createdAt'] ??
            data['sentAt'] ??
            data['fcmSentAt'] ??
            data['updatedAt'] ??
            data['timestamp'],
      ),
      type:
          _firstString(data, const [
            'type',
            'targetType',
            'notificationType',
          ]) ??
          '',
      status: _firstString(data, const ['status', 'fcmStatus']) ?? '',
    );
  }

  static String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _dateValue(Object? value) {
    if (value == null) {
      return null;
    }

    final dynamicValue = value as dynamic;
    final date = dynamicValue is DateTime ? dynamicValue : null;
    if (date != null) {
      return date;
    }

    try {
      final toDate = dynamicValue.toDate;
      if (toDate is Function) {
        final parsed = toDate();
        if (parsed is DateTime) {
          return parsed;
        }
      }
    } catch (_) {
      // Some backend fields are strings or numbers instead of timestamps.
    }

    return DateTime.tryParse(value.toString());
  }
}

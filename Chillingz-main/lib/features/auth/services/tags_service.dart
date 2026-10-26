import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/interest_option.dart';

class TagsService {
  TagsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<InterestOption>> fetchActiveTags() async {
    final snapshot = await _firestore.collection('tags').get();
    final options = <InterestOption>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isActive(data)) {
        continue;
      }

      final label = _firstText([
        data['tagName'],
        data['name'],
        data['title'],
        data['slug'],
      ]);
      if (label.isEmpty) {
        continue;
      }

      options.add(InterestOption(id: label, label: label));
    }

    options.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return options;
  }

  static bool _isActive(Map<String, dynamic> data) {
    final status = data['status']?.toString().trim().toLowerCase() ?? '';
    if (status.isNotEmpty) {
      return status == 'active';
    }
    return true;
  }

  static String _firstText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}

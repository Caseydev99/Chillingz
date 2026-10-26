import 'package:flutter/foundation.dart';

class BottomNavProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void resetToHome() {
    updateIndex(0);
  }

  void updateIndex(int index) {
    if (_currentIndex == index) {
      return;
    }

    _currentIndex = index;
    notifyListeners();
  }
}

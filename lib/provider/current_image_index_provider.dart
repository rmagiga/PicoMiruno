import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentImageIndexNotifier extends StateNotifier<int> {
  CurrentImageIndexNotifier(super.initialIndex);

  int get index => state;
  set index(int value) {
    state = value;
  }
}

final StateNotifierProvider<CurrentImageIndexNotifier, int> currentImageIndexProvider =
    StateNotifierProvider<CurrentImageIndexNotifier, int>(
      (StateNotifierProviderRef<CurrentImageIndexNotifier, int> ref) =>
          CurrentImageIndexNotifier(0),
    );

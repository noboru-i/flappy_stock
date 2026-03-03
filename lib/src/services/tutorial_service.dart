import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  TutorialService._();
  static final instance = TutorialService._();

  static const _key = 'tutorial_shown';

  Future<bool> isTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

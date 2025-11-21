import 'package:shared_preferences/shared_preferences.dart';

class SearchHistory {
  static const String _keyPrefix = 'search_history_';
  static const int _maxHistoryItems = 10;

  /// 获取搜索历史
  static Future<List<String>> getHistory(String screenName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_keyPrefix$screenName') ?? [];
  }

  /// 添加搜索记录
  static Future<void> addToHistory(String screenName, String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory(screenName);

    // 移除重复�?
    history.remove(query);

    // 添加到开�?
    history.insert(0, query);

    // 限制历史记录数量
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await prefs.setStringList('$_keyPrefix$screenName', history);
  }

  /// 删除特定的搜索记�?
  static Future<void> removeFromHistory(String screenName, String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory(screenName);

    history.remove(query);
    await prefs.setStringList('$_keyPrefix$screenName', history);
  }

  /// 清除所有搜索历�?
  static Future<void> clearHistory(String screenName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$screenName');
  }
}

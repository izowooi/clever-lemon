import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/storage_service.dart';
import '../../models/daily_quote.dart';

class LocalStorageService implements StorageService {
  static const String _dailyQuotesKey = 'saved_daily_quotes';

  @override
  Future<void> saveDailyQuote(DailyQuote dailyQuote) async {
    final prefs = await SharedPreferences.getInstance();
    final dailyQuotes = await getAllDailyQuotes();

    // 기존에 같은 ID가 있다면 업데이트, 없다면 추가
    final existingIndex = dailyQuotes.indexWhere((dq) => dq.id == dailyQuote.id);
    if (existingIndex != -1) {
      dailyQuotes[existingIndex] = dailyQuote;
    } else {
      dailyQuotes.add(dailyQuote);
    }

    final jsonList = dailyQuotes.map((dq) => dq.toJson()).toList();
    await prefs.setString(_dailyQuotesKey, jsonEncode(jsonList));
  }

  @override
  Future<List<DailyQuote>> getAllDailyQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_dailyQuotesKey);

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => DailyQuote.fromJson(json)).toList();
  }

  @override
  Future<DailyQuote?> getDailyQuoteById(String id) async {
    final dailyQuotes = await getAllDailyQuotes();
    try {
      return dailyQuotes.firstWhere((dailyQuote) => dailyQuote.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteDailyQuote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final dailyQuotes = await getAllDailyQuotes();

    dailyQuotes.removeWhere((dailyQuote) => dailyQuote.id == id);

    final jsonList = dailyQuotes.map((dq) => dq.toJson()).toList();
    await prefs.setString(_dailyQuotesKey, jsonEncode(jsonList));
  }

  @override
  Future<void> updateDailyQuote(DailyQuote dailyQuote) async {
    await saveDailyQuote(dailyQuote); // saveDailyQuote가 이미 업데이트 로직을 포함하고 있음
  }
}

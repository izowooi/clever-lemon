import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/storage_service.dart';
import '../../models/poetry.dart';

class LocalStorageService implements StorageService {
  static const String _poetriesKey = 'saved_poetries';
  
  @override
  Future<void> savePoetry(Poetry poetry) async {
    final prefs = await SharedPreferences.getInstance();
    final poetries = await getAllPoetries();
    
    // 기존에 같은 ID가 있다면 업데이트, 없다면 추가
    final existingIndex = poetries.indexWhere((p) => p.id == poetry.id);
    if (existingIndex != -1) {
      poetries[existingIndex] = poetry;
    } else {
      poetries.add(poetry);
    }
    
    final jsonList = poetries.map((p) => p.toJson()).toList();
    await prefs.setString(_poetriesKey, jsonEncode(jsonList));
  }

  @override
  Future<List<Poetry>> getAllPoetries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_poetriesKey);
    
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Poetry.fromJson(json)).toList();
  }

  @override
  Future<Poetry?> getPoetryById(String id) async {
    final poetries = await getAllPoetries();
    try {
      return poetries.firstWhere((poetry) => poetry.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deletePoetry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final poetries = await getAllPoetries();
    
    poetries.removeWhere((poetry) => poetry.id == id);
    
    final jsonList = poetries.map((p) => p.toJson()).toList();
    await prefs.setString(_poetriesKey, jsonEncode(jsonList));
  }

  @override
  Future<void> updatePoetry(Poetry poetry) async {
    await savePoetry(poetry); // savePoetry가 이미 업데이트 로직을 포함하고 있음
  }
}

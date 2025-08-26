import 'package:flutter/foundation.dart';
import '../models/poetry.dart';
import '../services/interfaces/storage_service.dart';

class PoetryListProvider with ChangeNotifier {
  final StorageService _storageService;

  PoetryListProvider({required StorageService storageService})
      : _storageService = storageService;

  List<Poetry> _poetries = [];
  List<Poetry> get poetries => _poetries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 저장된 모든 시를 로드합니다
  Future<void> loadPoetries() async {
    try {
      _setLoading(true);
      _poetries = await _storageService.getAllPoetries();
      // 최신순으로 정렬
      _poetries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _setError('시 목록을 불러오는데 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 시를 삭제합니다
  Future<void> deletePoetry(String id) async {
    try {
      _setLoading(true);
      await _storageService.deletePoetry(id);
      _poetries.removeWhere((poetry) => poetry.id == id);
      notifyListeners();
    } catch (e) {
      _setError('시 삭제에 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 시를 업데이트합니다
  Future<void> updatePoetry(Poetry updatedPoetry) async {
    try {
      _setLoading(true);
      await _storageService.updatePoetry(updatedPoetry);
      
      final index = _poetries.indexWhere((p) => p.id == updatedPoetry.id);
      if (index != -1) {
        _poetries[index] = updatedPoetry;
        // 수정시간 기준으로 재정렬
        _poetries.sort((a, b) {
          final aTime = a.modifiedAt ?? a.createdAt;
          final bTime = b.modifiedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
      }
      
      notifyListeners();
    } catch (e) {
      _setError('시 업데이트에 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 에러를 클리어합니다
  void clearError() {
    _setError(null);
  }
}

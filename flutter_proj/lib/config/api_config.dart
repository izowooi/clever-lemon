class ApiConfig {
  // 환경변수 또는 빌드 설정에서 읽어오기
  static const String? _envApiUrl = String.fromEnvironment('API_URL');
  static const bool _isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
  
  static const String _productionBaseUrl = 'https://clever-lemon.zowoo.uk';
  static const String _developmentBaseUrl = 'https://clever-lemon.zowoo.uk';
  
  static String get baseUrl {
    // 1. 환경변수가 설정되어 있으면 그것을 사용
    if (_envApiUrl != null && _envApiUrl!.isNotEmpty) {
      return _envApiUrl!;
    }
    
    // 2. 디버그 모드면 개발 서버, 릴리스 모드면 프로덕션 서버
    return _isDebugMode ? _developmentBaseUrl : _productionBaseUrl;
  }
  
  static bool get isDevelopment => _isDebugMode;
  static bool get isProduction => !_isDebugMode;
  
  // 현재 사용중인 서버 환경을 출력하는 디버그 함수
  static void printCurrentEnvironment() {
    print('🌍 API Environment: ${isDevelopment ? 'Development' : 'Production'}');
    print('🔗 Base URL: $baseUrl');
    if (_envApiUrl != null && _envApiUrl!.isNotEmpty) {
      print('📝 Using custom API_URL from environment variable');
    }
  }
  
  // API 엔드포인트들
  static String get authRegisterUrl => '$baseUrl/auth/register';
  static String get authWithdrawUrl => '$baseUrl/auth/withdraw';
  static String get poemGenerateUrl => '$baseUrl/poems/generate';
  static String get paymentApproveUrl => '$baseUrl/payments/approve';
}
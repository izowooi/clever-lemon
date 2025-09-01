import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase 설정 파일 경로 확인 및 초기화
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
      print("Firebase: GoogleService-Info.plist found at: \(path)")
      if let options = FirebaseOptions(contentsOfFile: path) {
        FirebaseApp.configure(options: options)
        print("Firebase: Configured with custom options")
      } else {
        print("Firebase: Failed to create options from plist")
        FirebaseApp.configure()
      }
    } else {
      print("Firebase: GoogleService-Info.plist not found, using default configuration")
      FirebaseApp.configure()
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

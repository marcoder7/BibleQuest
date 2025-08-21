import UIKit
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    // Configure Firebase once
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    return true
  }

  /// Handles the redirect back to your app from Google Sign-In
  func application(_ app: UIApplication,
                   open url: URL,
                   options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}

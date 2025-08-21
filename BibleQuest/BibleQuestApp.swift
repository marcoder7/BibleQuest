import SwiftUI

@main
struct BibleQuestApp: App {
  // Hook the UIKit AppDelegate so Firebase can initialize early
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      // Your existing entry point
      RootView()
    }
  }
}

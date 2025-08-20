import SwiftUI

final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
}

struct RootView: View {
    @StateObject private var appState = AppState()
    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainTabView()
                    .environmentObject(appState)
            } else {
                LoginView(onLogin: {
                    appState.isLoggedIn = true
                })
                .environmentObject(appState)
            }
        }
    }
}

#Preview {
    RootView()
}

import SwiftUI
import FirebaseAuth

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
        .onAppear {
            checkAuthState()
        }
    }

    private func checkAuthState() {
        // If Firebase has a user already, keep them logged in
        if Auth.auth().currentUser != nil {
            appState.isLoggedIn = true
        } else {
            appState.isLoggedIn = false
        }

        // Optional: keep listening for changes (logout/login)
        Auth.auth().addStateDidChangeListener { _, user in
            withAnimation {
                self.appState.isLoggedIn = (user != nil)
            }
        }
    }
}

#Preview {
    RootView()
}

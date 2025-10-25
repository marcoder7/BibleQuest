import SwiftUI
import FirebaseAuth
import FirebaseDatabase

final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var profile: UserProfile?
}

struct RootView: View {
    @StateObject private var appState = AppState()
    @State private var profileState: ProfileState = .unknown
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            contentView()
        }
        .onAppear {
            setUpAuthListenerIfNeeded()
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
        if appState.isLoggedIn {
            switch profileState {
            case .unknown:
                ProgressView("Loading profile...")
            case .needsOnboarding:
                OnboardingAvatarView {
                    profileState = .ready
                }
                .environmentObject(appState)
            case .ready:
                MainTabView()
                    .environmentObject(appState)
            }
        } else {
            LoginView()
            .environmentObject(appState)
        }
    }

    private func setUpAuthListenerIfNeeded() {
        if authListenerHandle == nil {
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                handleAuthChange(user: user)
            }
        }
        handleAuthChange(user: Auth.auth().currentUser)
    }

    private func handleAuthChange(user: User?) {
        if let user {
            withAnimation {
                appState.isLoggedIn = true
                fetchProfileState(for: user)
            }
        } else {
            withAnimation {
                appState.isLoggedIn = false
                profileState = .unknown
                appState.profile = nil
            }
        }
    }

    private func fetchProfileState(for user: User) {
        profileState = .unknown
        Database.database()
            .reference()
            .child("Users")
            .child(user.uid)
            .getData { error, snapshot in
                DispatchQueue.main.async {
                    guard error == nil else {
                        appState.profile = fallbackProfile(for: user)
                        profileState = .needsOnboarding
                        return
                    }

                    guard let snapshot = snapshot, snapshot.exists(),
                          let data = snapshot.value as? [String: Any] else {
                        appState.profile = fallbackProfile(for: user)
                        profileState = .needsOnboarding
                        return
                    }

                    let profile = buildProfile(uid: user.uid, data: data, firebaseUser: user)
                    appState.profile = profile
                    profileState = profile.isComplete ? .ready : .needsOnboarding
                }
            }
    }

    private func fallbackProfile(for user: User) -> UserProfile {
        UserProfile(
            uid: user.uid,
            name: user.displayName ?? "",
            hero: "",
            email: user.email ?? "",
            photoURL: user.photoURL?.absoluteString ?? ""
        )
    }

    private func buildProfile(uid: String,
                              data: [String: Any],
                              firebaseUser: User) -> UserProfile {
        func stringValue(_ key: String) -> String {
            (data[key] as? String)?.trimmed() ?? ""
        }

        let name = {
            let direct = stringValue("Name")
            if !direct.isEmpty { return direct }
            let legacy = stringValue("displayName")
            if !legacy.isEmpty { return legacy }
            return firebaseUser.displayName ?? ""
        }()

        let hero = {
            let heroKey = stringValue("Hero")
            if !heroKey.isEmpty { return heroKey }
            return stringValue("HeroName")
        }()

        let email = {
            let stored = stringValue("email")
            return stored.isEmpty ? (firebaseUser.email ?? "") : stored
        }()

        let photo = {
            let stored = stringValue("photoURL")
            return stored.isEmpty ? (firebaseUser.photoURL?.absoluteString ?? "") : stored
        }()

        return UserProfile(
            uid: uid,
            name: name,
            hero: hero,
            email: email,
            photoURL: photo
        )
    }

    private enum ProfileState {
        case unknown
        case needsOnboarding
        case ready
    }
}

#Preview {
    RootView()
}

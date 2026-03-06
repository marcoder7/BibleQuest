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
    @State private var isResolvingAuth = true
    @State private var pendingLoggedOutResolution: DispatchWorkItem?

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
        if isResolvingAuth {
            AuthLoadingView()
        } else if appState.isLoggedIn {
            switch profileState {
            case .unknown:
                AuthLoadingView()
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
        pendingLoggedOutResolution?.cancel()

        if let user {
            isResolvingAuth = true
            withAnimation {
                appState.isLoggedIn = true
                fetchProfileState(for: user)
            }
        } else {
            if !isResolvingAuth {
                withAnimation {
                    appState.isLoggedIn = false
                    profileState = .unknown
                    appState.profile = nil
                }
                return
            }

            // Avoid login flicker on cold launch while Firebase restores persisted auth.
            let work = DispatchWorkItem {
                guard Auth.auth().currentUser == nil else { return }
                withAnimation {
                    appState.isLoggedIn = false
                    profileState = .unknown
                    appState.profile = nil
                    isResolvingAuth = false
                }
            }
            pendingLoggedOutResolution = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65, execute: work)
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
                        isResolvingAuth = false
                        return
                    }

                    guard let snapshot = snapshot, snapshot.exists(),
                          let data = snapshot.value as? [String: Any] else {
                        appState.profile = fallbackProfile(for: user)
                        profileState = .needsOnboarding
                        isResolvingAuth = false
                        return
                    }

                    let profile = buildProfile(uid: user.uid, data: data, firebaseUser: user)
                    appState.profile = profile
                    profileState = profile.isComplete ? .ready : .needsOnboarding
                    isResolvingAuth = false
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

private struct AuthLoadingView: View {
    private let verseBubbles: [VerseBubble] = [
        .init(
            text: "Be strong and courageous. Do not be afraid.",
            reference: "Joshua 1:9",
            x: 0.23, y: 0.20, delay: 0.0, duration: 4.2, yDrift: 20
        ),
        .init(
            text: "The Lord is my shepherd; I shall not want.",
            reference: "Psalm 23:1",
            x: 0.77, y: 0.31, delay: 0.6, duration: 3.8, yDrift: 16
        ),
        .init(
            text: "I can do all things through Christ who strengthens me.",
            reference: "Philippians 4:13",
            x: 0.30, y: 0.58, delay: 1.0, duration: 4.5, yDrift: 22
        ),
        .init(
            text: "Let all that you do be done in love.",
            reference: "1 Corinthians 16:14",
            x: 0.72, y: 0.73, delay: 0.3, duration: 4.0, yDrift: 18
        )
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ForEach(verseBubbles) { bubble in
                    FloatingVerseBubble(bubble: bubble, size: geo.size)
                }

                VStack(spacing: 14) {
                    Text("BibleQuest")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.bqTitle)

                    ProgressView()
                        .controlSize(.large)
                        .tint(Color(hex: "#2C7CF6"))

                    Text("Loading your adventure...")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.bqSubtitle)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 22)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.bqCardSurface.opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.bqCardBorder.opacity(0.75), lineWidth: 2)
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
            }
        }
    }
}

private struct VerseBubble: Identifiable {
    let id = UUID()
    let text: String
    let reference: String
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    let duration: Double
    let yDrift: CGFloat
}

private struct FloatingVerseBubble: View {
    let bubble: VerseBubble
    let size: CGSize
    @State private var up = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("“\(bubble.text)”")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#355A9B"))
                .lineLimit(2)

            Text(bubble.reference)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#2C7CF6").opacity(0.82))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bqCardSurface.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.bqCardBorder.opacity(0.70), lineWidth: 1)
                )
        )
        .frame(width: min(250, size.width * 0.48))
        .position(x: size.width * bubble.x, y: size.height * bubble.y + (up ? -bubble.yDrift : bubble.yDrift))
        .opacity(up ? 0.95 : 0.65)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 5)
        .onAppear {
            withAnimation(
                .easeInOut(duration: bubble.duration)
                .repeatForever(autoreverses: true)
                .delay(bubble.delay)
            ) {
                up = true
            }
        }
    }
}

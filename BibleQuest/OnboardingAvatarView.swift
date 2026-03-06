import SwiftUI
import FirebaseAuth
import FirebaseDatabase

// MARK: - Onboarding Avatar Picker

struct OnboardingAvatarView: View {
    var onComplete: () -> Void = {}
    @EnvironmentObject var appState: AppState
    struct Avatar: Identifiable { let id = UUID(); let image: String; let title: String }

    private let avatars: [Avatar] = [
        .init(image: "david",       title: "David"),
        .init(image: "mary",        title: "Mary"),
        .init(image: "mosesAvatar", title: "Moses"),
        .init(image: "noahAvatar",  title: "Noah"),
        .init(image: "josephAvatar",title: "Joseph"),
        .init(image: "peterAvatar", title: "Peter"),
        .init(image: "jesusAvatar",  title: "Jesus")
    ]

    @State private var selectedIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var name: String = ""

    @State private var goToApp = false
    @FocusState private var nameFocused: Bool

    // NEW: saving state & errors
    @State private var isSaving = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .overlay(FloatingBits().opacity(0.6))

                VStack(spacing: 22) {
                    VStack(spacing: 6) {
                        Text("Choose Your Hero")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)
                        Text("Pick an avatar and tell us your name!")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)
                    }
                    .padding(.top, 24)

                    // Carousel
                    ZStack {
                        ForEach(avatars.indices, id: \.self) { i in
                            let rel = CGFloat(i - selectedIndex)
                            let isCenter = i == selectedIndex
                            let baseSize: CGFloat = isCenter ? 190 : 110
                            let spacing: CGFloat = 150
                            let x = rel * spacing + dragOffset
                            let y: CGFloat = isCenter ? 0 : 24
                            let blur: CGFloat = isCenter ? 0 : 1.5
                            let opacity: Double = isCenter ? 1 : 0.65
                            let scale: CGFloat = isCenter ? 1.0 : 0.88

                            AvatarBubble(imageName: avatars[i].image,
                                         size: baseSize,
                                         highlighted: isCenter)
                                .scaleEffect(scale)
                                .blur(radius: blur)
                                .opacity(opacity)
                                .offset(x: x, y: y)
                                .animation(.spring(response: 0.45, dampingFraction: 0.85),
                                           value: selectedIndex)
                                .onTapGesture { withAnimation { selectedIndex = i } }
                                .allowsHitTesting(isCenter || abs(rel) <= 1)
                        }
                    }
                    .frame(height: 240)
                    .gesture(
                        DragGesture()
                            .onChanged { value in dragOffset = value.translation.width }
                            .onEnded { value in
                                let threshold: CGFloat = 60
                                if value.translation.width < -threshold && selectedIndex < avatars.count-1 {
                                    selectedIndex += 1
                                } else if value.translation.width > threshold && selectedIndex > 0 {
                                    selectedIndex -= 1
                                }
                                dragOffset = 0
                            }
                    )

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)
                        HStack(spacing: 10) {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.bqTitle.opacity(0.9))
                            TextField("Type your name...", text: $name)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .focused($nameFocused)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.bqCardSurface)
                                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)

                    if let errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 22)
                    }

                    Spacer(minLength: 60)
                }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 12) {
                    LiquidGlassButton(title: isSaving ? "Saving..." : "Begin Adventure",
                                      icon: "play.fill") {
                        nameFocused = false
                        saveProfile()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .disabled(isSaving || name.trimmed().isEmpty)
                    .opacity((isSaving || name.trimmed().isEmpty) ? 0.6 : 1)

                    // Hidden navigation
                    NavigationLink("", destination: MainTabView(), isActive: $goToApp)
                        .opacity(0)
                }
                .padding(.bottom, 24)
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Save to Firebase, then proceed
    private func saveProfile() {
        errorText = nil

        guard let uid = Auth.auth().currentUser?.uid else {
            errorText = "Not signed in."
            return
        }
        let trimmed = name.trimmed()
        guard !trimmed.isEmpty else {
            errorText = "Please enter your name."
            return
        }

        isSaving = true
        let usersRef = Database.database().reference().child("Users").child(uid)

        // Save Name (and avatar for good measure)
        let updates: [String: Any] = [
          "Name": trimmed,
          "Hero": avatars[selectedIndex].image,          // 👈 store the asset/image name here
          // "avatar": avatars[selectedIndex].title,     // (optional) keep old key if other code reads it
          "updatedAt": Date().timeIntervalSince1970
        ]

        usersRef.updateChildValues(updates) { error, _ in
            isSaving = false
            if let error = error {
                errorText = "Failed to save: \(error.localizedDescription)"
                return
            }
            // Navigate into the app & let parent know onboarding completed
            let profile = UserProfile(
                uid: uid,
                name: trimmed,
                hero: avatars[selectedIndex].image,
                email: Auth.auth().currentUser?.email ?? "",
                photoURL: Auth.auth().currentUser?.photoURL?.absoluteString ?? ""
            )
            appState.profile = profile
            onComplete()
            goToApp = true
        }
    }
}

// MARK: - Avatar bubble

private struct AvatarBubble: View {
    let imageName: String
    let size: CGFloat
    let highlighted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.75)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    Circle().stroke(.white.opacity(0.85), lineWidth: highlighted ? 6 : 3)
                )
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)

            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(highlighted ? 18 : 20)
                    .clipShape(Circle())
            } else {
                Text("🧒").font(.system(size: size * 0.45))
            }

            if highlighted {
                ZStack {
                    Image(systemName: "sparkles").offset(x: 0, y: -size/2)
                    Image(systemName: "sparkles").offset(x:  size/2.2, y:  size/3.0)
                    Image(systemName: "sparkles").offset(x: -size/2.2, y:  size/3.0)
                }
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .rotationEffect(.degrees(360))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: highlighted)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Liquid Glass Button

private struct LiquidGlassButton: View {
    var title: String
    var icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 18, weight: .bold))
                Text(title).font(.system(size: 20, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 26)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex:"#7CB7FF"),
                                Color(hex:"#B36BFF"),
                                Color(hex:"#6ED47A"),
                                Color(hex:"#FFB661")
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.85), lineWidth: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.25))
                            .blur(radius: 2)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating background bits (unchanged)

private struct FloatingBits: View {
    @State private var t: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<10, id: \.self) { i in
                    let x = CGFloat(Int.random(in: -180...180))
                    let delay = Double(i) * 0.15
                    Image(systemName: i.isMultiple(of: 3) ? "trophy.fill" : (i.isMultiple(of: 2) ? "bolt.fill" : "star.fill"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.yellow.opacity(0.5))
                        .offset(x: x, y: (geo.size.height * (1 - t)).truncatingRemainder(dividingBy: geo.size.height) - 80)
                        .rotationEffect(.degrees(Double(t) * 45))
                        .animation(.linear(duration: 12).repeatForever(autoreverses: false).delay(delay), value: t)
                }
            }
            .onAppear { t = 1 }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Utils


#Preview {
    OnboardingAvatarView()
        .environmentObject(AppState())
}

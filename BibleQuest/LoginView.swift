import SwiftUI
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

// MARK: - LoginView

struct LoginView: View {
    // When auth succeeds we push OnboardingAvatarView
    @State private var goToOnboarding = false

    var onLogin: () -> Void = {}

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false

    // UI state
    @State private var isWorking: Bool = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            BackgroundDecor()

            // Keep Navigation in here so we can push OnboardingAvatarView
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        TitleBlock()
                            .padding(.top, 40)

                        MascotBounceImage() // animated David

                        LoginCard(
                            email: $email,
                            password: $password,
                            showPassword: $showPassword,
                            onLogin: {},
                            onGoogleTap: handleGoogleTap,
                            onAppleTap: handleAppleTap
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        if let errorText {
                            Text(errorText)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        FooterNote()
                            .padding(.horizontal, 28)
                            .padding(.bottom, 28)

                        // Hidden navigation trigger
                        NavigationLink(
                            destination: OnboardingAvatarView(),
                            isActive: $goToOnboarding
                        ) { EmptyView() }
                        .hidden()
                    }
                }
                .navigationBarHidden(true)
            }
        }

        .overlay {
            if isWorking {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .disabled(isWorking)
    }

    // MARK: - Handlers

    private func handleGoogleTap() {
        print("👉 Google button tapped")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            self.errorText = "No presenting controller"
            return
        }
        isWorking = true
        errorText = nil

        AuthService.signInWithGoogle(presenting: rootVC) { result in
            DispatchQueue.main.async {
                self.isWorking = false
                switch result {
                case .success:
                    
                    goToOnboarding = true
                case .failure(let err):
                    self.errorText = err.localizedDescription
                }
            }
        }
    }

    private func handleAppleTap() {
        print("👉 Apple button tapped")
        isWorking = true
        errorText = nil

        AuthService.startSignInWithApple { result in
            DispatchQueue.main.async {
                self.isWorking = false
                switch result {
                case .success:
                    onLogin()
                    goToOnboarding = true
                case .failure(let err):
                    self.errorText = err.localizedDescription
                }
            }
        }
    }
}

// MARK: - Background

private struct BackgroundDecor: View {
    private let bg = LinearGradient(
        colors: [Color(hex: "#CFEAFF"), Color(hex: "#E8F2FF")],
        startPoint: .top, endPoint: .bottom
    )
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            Circle()
                .fill(Color(hex: "#BFE6D4").opacity(0.6))
                .frame(width: 160, height: 160)
                .blur(radius: 2)
                .offset(x: -140, y: -360)

            Circle()
                .fill(Color(hex: "#C9C8FF").opacity(0.6))
                .frame(width: 140, height: 140)
                .blur(radius: 2)
                .offset(x: 140, y: -360)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Title

private struct TitleBlock: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Welcome,")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .opacity(0.0)

            Text("BibleQuest")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "#1F6FE5"))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

            Text("Adventures")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "#2C7CF6"))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

            Text("Play the Stories. Live the Values.")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(Color(hex: "#6C7A99"))
                .padding(.top, 2)
        }
    }
}

// MARK: - Animated Mascot

private struct MascotBounceImage: View {
    @State private var up = false
    var body: some View {
        Image("david")
            .resizable()
            .scaledToFill()
            .frame(width: 190, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 14, x: 0, y: 10)
            .offset(y: up ? -6 : 6)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    up.toggle()
                }
            }
    }
}

// MARK: - Card

private struct LoginCard: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var showPassword: Bool
    var onLogin: () -> Void

    // social actions
    var onGoogleTap: () -> Void
    var onAppleTap: () -> Void

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.white.opacity(0.72))
    }
    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(Color.white.opacity(0.65), lineWidth: 1)
    }

    var body: some View {
        VStack(spacing: 18) {
            Social3DButtons(onGoogleTap: onGoogleTap, onAppleTap: onAppleTap)

            // Bigger divider tag so the text never truncates
            DividerTag(label: "Or continue with email")
                .padding(.top, 6)

            EmailField(email: $email)
            PasswordField(password: $password, showPassword: $showPassword)

            CTAButton(title: "Start Your Adventure!", action: onLogin)
        }
        .padding(22)
        .background(cardBackground)
        .overlay(cardStroke)
        .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 16)
    }
}

// MARK: - Social Buttons (3D White)

private struct Social3DButtons: View {
    let onGoogleTap: () -> Void
    let onAppleTap: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            NeumorphicPill(icon: "globe", title: "Continue with Google", onTap: onGoogleTap)
            NeumorphicPill(icon: "applelogo", title: "Continue with Apple", onTap: onAppleTap)
        }
    }
}

private struct NeumorphicPill: View {
    let icon: String
    let title: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.45))

                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.black.opacity(0.55))
            }
            // Center the contents in the pill
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            LinearGradient(colors: [Color.white, Color(hex: "#F6F8FF")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
        .shadow(color: .white.opacity(0.9), radius: 8,  x: 0, y: -2)
    }
}

// MARK: - Divider Tag (single line, non-truncating, bigger)

private struct DividerTag: View {
    let label: String
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.70))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.98))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .fixedSize(horizontal: true, vertical: false) // <- don’t truncate
                .layoutPriority(1)
            Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Inputs

private struct EmailField: View {
    @Binding var email: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "envelope")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "#6C7A99"))

            TextField("your@email.com", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color(hex: "#4B5975"))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

private struct PasswordField: View {
    @Binding var password: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if showPassword {
                    TextField("Enter your password", text: $password)
                } else {
                    SecureField("Enter your password", text: $password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(.body, design: .rounded))
            .foregroundStyle(Color(hex: "#4B5975"))

            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showPassword.toggle() }
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "#6C7A99"))
            }
            .contentShape(Rectangle())
            .padding(.trailing, 2)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - CTA

private struct CTAButton: View {
    var title: String
    var action: () -> Void

    private let gradient = LinearGradient(
        colors: [Color(hex: "#5EA3F8"), Color(hex: "#B36BFF"), Color(hex: "#FF9A62")],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(gradient)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .shadow(color: Color(hex: "#7F8BFF").opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

// MARK: - Footer

private struct FooterNote: View {
    var body: some View {
        Text("Ready to explore amazing Bible stories? Let's go on an adventure! ✨")
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(Color(hex: "#6C7A99"))
            .multilineTextAlignment(.center)
    }
}

// MARK: - Color Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

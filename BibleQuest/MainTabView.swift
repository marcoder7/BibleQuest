import SwiftUI
import FirebaseAuth

// MARK: - Main Tabs

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            // Wrap Home in a NavigationStack so we can push detail screens
            NavigationStack {
                HomePage()
            }
            .tabItem {
                Image(systemName: selection == 0 ? "sailboat.fill" : "sailboat") // Ark-like for now
                Text("Home")
            }
            .tag(0)

            NavigationStack {
                StoriesView()
            }
                .tabItem {
                    Image(systemName: selection == 1 ? "book.closed.fill" : "book.closed")
                    Text("Stories")
                }
                .tag(1)

            NavigationStack {
                WisdomView()
            }
            .tabItem {
                Image(systemName: selection == 2 ? "lightbulb.fill" : "lightbulb")
                Text("Wisdom")
            }
            .tag(2)

            ProfilePage()
                .tabItem {
                    Image(systemName: selection == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(Color(hex: "#2C7CF6"))
    }
}

// MARK: - Home Page

struct HomePage: View {
    @EnvironmentObject var appState: AppState
    // Navigation trigger for Hero Album
    @State private var goToHeroAlbum = false
    @State private var goToVerseView = false
    @State private var goToAdventure = false
    
    var body: some View {
        let welcomeName = appState.profile?.displayName ?? "Explorer"
        ZStack {
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Welcome,\n\(welcomeName)!")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text("Ready for today's adventure? ✨")
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)
                    }
                    .padding(.top, 24)

                    // Challenge (gradient)
                    ChallengeCard()

                    HomeCard(
                        title: "Adventures",
                        subtitle: "Explore Bible stories",
                        bg: Color(hex: "#1E7BF4"),
                        tint: .white,
                        badgeImageName: "noah"
                    ) {
                        goToAdventure = true   // ✅ navigate to AdventureView
                    }

                    // Hero Album (purple) — uses asset "album"
                    HomeCard(
                        title: "Hero Album",
                        subtitle: "Collect Bible heroes",
                        bg: Color(hex: "#8C63E6"),
                        tint: .white,
                        badgeImageName: "album"
                    ) {
                        goToHeroAlbum = true
                    }

                    // Verse Power-Up (green) — uses asset "scroll"
                    HomeCard(
                        title: "Verse Power-Up",
                        subtitle: "Daily Bible verse",
                        bg: Color(hex: "#22A060"),
                        tint: .white,
                        badgeImageName: "scroll"
                    ) {
                        goToVerseView = true   // ✅ trigger navigation
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        // Hidden navigation links
        .background(
            VStack {
                NavigationLink("", destination: HeroAlbumView(), isActive: $goToHeroAlbum)
                    .opacity(0)
                NavigationLink("", destination: VerseView(), isActive: $goToVerseView) // ✅ new nav link
                    .opacity(0)
                NavigationLink("", destination: SelectQuestView(), isActive: $goToAdventure) // ✅ add this
                            .opacity(0)
            }
        )
        .navigationBarBackButtonHidden(true)   // no back button on root
                .navigationBarHidden(true) 
    }
}

// MARK: - Reusable Home Card (animated press + asset badge)

struct HomeCard: View {
    let title: String
    let subtitle: String
    let bg: Color
    let tint: Color
    var badgeImageName: String? = nil
    var action: (() -> Void)? = nil   // ← callback for navigation

    var body: some View {
        let corner: CGFloat = 28

        Button {
            action?()
        } label: {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(.white.opacity(0.8), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 12)

                BubbleDecor()

                VStack(spacing: 12) {
                    if let name = badgeImageName, UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 86, height: 86)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                    }

                    Text(title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(tint)

                    Text(subtitle)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(tint.opacity(0.95))
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity, minHeight: 170)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
                    .padding(1)
            )
        }
        .buttonStyle(HomeCardPressStyle())
    }
}

private struct HomeCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct BubbleDecor: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 110, height: 110)
                .offset(x: -110, y: -40)
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 90, height: 90)
                .offset(x: 110, y: 20)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Challenge Card

struct ChallengeCard: View {
    private let gradient = LinearGradient(
        colors: [Color(hex: "#6AAAF7"), Color(hex: "#B36BFF"), Color(hex: "#FF9A62")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    @State private var completed: Int = 2 // demo

    var body: some View {
        VStack(spacing: 14) {
            Text("Today’s Challenge")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Help David gather 5 smooth stones! 🪨")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))

            HStack(spacing: 14) {
                ForEach(1...5, id: \.self) { i in
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.28))
                            .frame(width: 44, height: 44)
                        if i <= completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        } else {
                            Text("\(i)")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            completed = i
                        }
                    }
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 12)
    }
}

struct ProfilePage: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Text("Profile")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .padding(.top, 24)

            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color(hex: "#2C7CF6"))

            Text(appState.profile?.displayName ?? "Explorer")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.bqTitle)

            Button(role: .destructive) {
                // 🔹 Sign out from Firebase
                try? Auth.auth().signOut()

                // 🔹 Update app state so RootView shows LoginView
                appState.isLoggedIn = false
            } label: {
                Text("Logout")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: 220, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.bqCardSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

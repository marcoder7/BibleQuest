import SwiftUI

// MARK: - Comic Sans helpers (fallback to rounded if the font isn't available)
enum ComicFont {
    static func bold(_ size: CGFloat) -> Font {
        if UIFont(name: "ComicSansMS-Bold", size: size) != nil {
            return .custom("ComicSansMS-Bold", size: size)
        }
        if UIFont(name: "ComicSansMS", size: size) != nil {
            return .custom("ComicSansMS", size: size).weight(.bold)
        }
        return .system(size: size, weight: .heavy, design: .rounded)
    }
    static func regular(_ size: CGFloat) -> Font {
        if UIFont(name: "ComicSansMS", size: size) != nil {
            return .custom("ComicSansMS", size: size)
        }
        return .system(size: size, weight: .regular, design: .rounded)
    }
    static func semi(_ size: CGFloat) -> Font {
        if UIFont(name: "ComicSansMS", size: size) != nil {
            return .custom("ComicSansMS", size: size).weight(.semibold)
        }
        return .system(size: size, weight: .semibold, design: .rounded)
    }
}

struct HeroLockedView: View {
    @Environment(\.dismiss) private var dismiss
    // Fallback route in case dismiss() doesn't pop:
    @State private var navigateToAlbum = false
    
    var heroName: String = "??? Locked\nHero ???"
    var description: String = "A mystery waiting to be revealed..."
    var questName: String = "Jonah & the Whale"
    
    var body: some View {
        ZStack {
            // Background gradient + soft bubbles
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.11, blue: 0.62),
                    Color(red: 0.09, green: 0.25, blue: 0.71)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(BackgroundBubbles())
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Big title + subtitle
                    VStack(spacing: 10) {
                        Text(heroName)
                            .multilineTextAlignment(.center)
                            .font(ComicFont.bold(44))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                        
                        Text(description)
                            .font(ComicFont.semi(22))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 18)
                    
                    // Locked hero glass card (with pulse)
                    LockedGlassCard()
                        .padding(.horizontal, 18)
                    
                    // "Mystery Hero" glass section
                    GlassSection {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.yellow)
                            Text("Mystery Hero")
                                .font(ComicFont.bold(24))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.bottom, 6)
                        
                        Text("This hero is waiting to be discovered!")
                            .font(ComicFont.semi(18))
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                        
                        Text("Help Jonah learn about God's forgiveness in the belly of a great fish!")
                            .font(ComicFont.regular(17))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 18)
                    
                    // Unlock quest card
                    GlassSection {
                        HStack(spacing: 10) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white.opacity(0.95))
                            Text("Unlock Quest")
                                .font(ComicFont.bold(22))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.bottom, 6)
                        
                        Text("Complete the \(questName) adventure to reveal this hero’s true identity!")
                            .font(ComicFont.regular(17))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 18)
                    
                    // Promise card
                    GlassSection {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.yellow)
                            Text("Hero’s Promise")
                                .font(ComicFont.bold(22))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.bottom, 6)
                        
                        Text("“Every hero has a story… finish the quest to reveal them!”")
                            .font(ComicFont.regular(18))
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .italic()
                    }
                    .padding(.horizontal, 18)
                    
                    // Buttons
                    VStack(spacing: 14) {
                        GradientButton(title: "▶  Go to Adventure")
                        OutlinePillButton(title: "←  Back to Album") {
                            // Let the system back handle it; this is a secondary option
                            // in case you keep this button.
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 18)
                    
                    // Footer progress
                    VStack(spacing: 8) {
                        Text("🏆 Unlocked 4/20 Heroes")
                            .font(ComicFont.semi(14))
                            .foregroundStyle(.white.opacity(0.95))
                        
                        HStack(spacing: 6) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.yellow)
                            }
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(false) // show native back
        .tint(.white)                          // make back chevron/text white
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Components

private struct LockedGlassCard: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Glass panel — material clipped to the rounded shape to avoid inner square corners
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )
                .frame(height: 360)
                .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)

            // Soft silhouette / question
            Image(systemName: "questionmark")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.white.opacity(0.10))
                .offset(y: -66)

            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)

                Text("??? ??? ???")
                    .font(ComicFont.bold(28))
                    .foregroundStyle(.white.opacity(0.9))

                // Little rounded "Locked" pill
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .bold))
                    Text("Locked")
                        .font(ComicFont.semi(16))
                }
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                )
                .overlay(
                    Capsule().stroke(.white.opacity(0.28), lineWidth: 1.2)
                )
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                .padding(.top, 6)
            }
            .offset(y: 60)
        }
        // Subtle pulse animation
        .scaleEffect(pulse ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

private struct GlassSection<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) { content }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Clip the material so there’s no inner square
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
}

private struct GradientButton: View {
    var title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ComicFont.bold(20))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.17, green: 0.51, blue: 0.98),
                                    Color(red: 0.50, green: 0.34, blue: 0.99)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.8), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
        }
    }
}

private struct OutlinePillButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ComicFont.bold(20))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.85), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
        }
    }
}

private struct BackgroundBubbles: View {
    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.16)).frame(width: 180).offset(x: -150, y: 120)
            Circle().fill(.white.opacity(0.14)).frame(width: 130).offset(x: 160, y: -40)
            Circle().fill(.white.opacity(0.12)).frame(width: 120).offset(x: 120, y: 420)
            Circle().fill(.white.opacity(0.10)).frame(width: 160).offset(x: -100, y: 560)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HeroLockedView()
    }
}

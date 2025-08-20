import SwiftUI
import UIKit

// MARK: - Font Theme (playful -> fallback to rounded)

enum BQAFont {
    static func title(_ size: CGFloat) -> Font {
        // Try your custom display font first (add it to the project & Info.plist)
        if UIFont(name: "Baloo2-ExtraBold", size: size) != nil {
            return .custom("Baloo2-ExtraBold", size: size)
        }
        return .system(size: size, weight: .heavy, design: .rounded)
    }
    static func heavy(_ size: CGFloat) -> Font {
        if UIFont(name: "Baloo2-Bold", size: size) != nil {
            return .custom("Baloo2-Bold", size: size)
        }
        return .system(size: size, weight: .heavy, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        if UIFont(name: "Baloo2-Regular", size: size) != nil {
            return .custom("Baloo2-Regular", size: size)
        }
        return .system(size: size, weight: .regular, design: .rounded)
    }
    static func subheadline(_ size: CGFloat) -> Font {
        if UIFont(name: "Baloo2-SemiBold", size: size) != nil {
            return .custom("Baloo2-SemiBold", size: size)
        }
        return .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Model you can pass from the grid

struct HeroDetail: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let title: String
    let value: String
    let emoji: String
    let verse: String
    let verseRef: String
    let story: String
}

// MARK: - Confetti that bursts from top-left & top-right (colored, no black)


// MARK: - Confetti (tiny, corner-burst, not waterfall)

struct ConfettiView: UIViewRepresentable {
    var start: Bool
    var duration: TimeInterval = 1.4     // shorter, “pop!” feel
    var baseScale: CGFloat = 0.16        // tiny pieces; tweak 0.10–0.20

    func makeUIView(context: Context) -> ConfettiContainer { ConfettiContainer() }
    func updateUIView(_ view: ConfettiContainer, context: Context) {
        view.startConfetti = start
        view.duration = duration
        view.baseScale = baseScale
        view.setNeedsLayout()
    }
}

final class ConfettiContainer: UIView {
    var startConfetti: Bool = false { didSet { update() } }
    var duration: TimeInterval = 1.4
    var baseScale: CGFloat = 0.16

    private weak var leftEmitter: CAEmitterLayer?
    private weak var rightEmitter: CAEmitterLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        positionEmitters()
    }

    private func update() {
        layer.sublayers?.removeAll(where: { $0.name == "BQAConfettiLeft" || $0.name == "BQAConfettiRight" })
        guard startConfetti, bounds.width > 0 else { return }

        // Top-left bursts down-right (≈ 60°)
        let left = makeEmitter(
            name: "BQAConfettiLeft",
            origin: CGPoint(x: 0, y: -8),
            emissionLongitude: .pi / 3,      // 60° (down-right)
            pushX: 60
        )

        // Top-right bursts down-left (≈ 120°)
        let right = makeEmitter(
            name: "BQAConfettiRight",
            origin: CGPoint(x: bounds.width, y: -8),
            emissionLongitude: 2 * .pi / 3,  // 120° (down-left)
            pushX: -60
        )

        layer.addSublayer(left)
        layer.addSublayer(right)
        leftEmitter = left
        rightEmitter = right

        // Stop spawning quickly so it feels like a burst
        let stopTime = duration
        DispatchQueue.main.asyncAfter(deadline: .now() + stopTime) { [weak left, weak right] in
            left?.birthRate = 0
            right?.birthRate = 0
        }
    }

    private func positionEmitters() {
        leftEmitter?.emitterPosition  = CGPoint(x: 0, y: -8)
        rightEmitter?.emitterPosition = CGPoint(x: bounds.width, y: -8)
        leftEmitter?.emitterSize = .init(width: 1, height: 1)
        rightEmitter?.emitterSize = .init(width: 1, height: 1)
    }

    private func makeEmitter(
        name: String,
        origin: CGPoint,
        emissionLongitude: CGFloat,
        pushX: CGFloat
    ) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.name = name
        emitter.emitterPosition = origin
        emitter.emitterShape = .point
        emitter.emitterSize = .init(width: 1, height: 1)
        emitter.beginTime = CACurrentMediaTime()

        // Use your asset images directly
        let assetNames = ["blue", "orange", "purple", "star", "square"]
        let images: [UIImage] = assetNames.compactMap { UIImage(named: $0) }

        // Phase A: quick burst (fast, short life)
        func burstCell(_ img: UIImage, scale: CGFloat) -> CAEmitterCell {
            let c = CAEmitterCell()
            c.contents = img.cgImage
            c.birthRate = 18
            c.beginTime = 0.0              // immediately
            c.duration = duration * 0.6    // when the cell can be spawned
            c.lifetime = 1.4
            c.lifetimeRange = 0.3
            c.velocity = 360               // fast
            c.velocityRange = 120
            c.yAcceleration = 140          // gentle gravity so it arcs
            c.xAcceleration = pushX
            c.emissionLongitude = emissionLongitude
            c.emissionRange = .pi / 6      // nice fan
            c.spin = 6
            c.spinRange = 8
            c.scale = scale
            c.scaleRange = scale * 0.2
            c.scaleSpeed = -0.08
            c.alphaSpeed = -0.6
            return c
        }

        // Phase B: softer fall (slower, starts a bit later)
        func fallCell(_ img: UIImage, scale: CGFloat) -> CAEmitterCell {
            let c = CAEmitterCell()
            c.contents = img.cgImage
            c.birthRate = 10
            c.beginTime = 0.12             // a hair after the burst
            c.duration = duration * 0.9
            c.lifetime = 2.2
            c.lifetimeRange = 0.6
            c.velocity = 220
            c.velocityRange = 90
            c.yAcceleration = 220
            c.xAcceleration = pushX
            c.emissionLongitude = emissionLongitude
            c.emissionRange = .pi / 5
            c.spin = 4
            c.spinRange = 6
            c.scale = scale * 0.9          // even smaller on average
            c.scaleRange = scale * 0.2
            c.scaleSpeed = -0.05
            c.alphaSpeed = -0.35
            return c
        }

        // Tiny sizes for variety
        var cells: [CAEmitterCell] = []
        for img in images {
            let s1 = baseScale                 // ~0.16 default
            let s2 = baseScale * 0.75          // ~0.12
            cells.append(burstCell(img, scale: s1))
            cells.append(burstCell(img, scale: s2))
            cells.append(fallCell(img, scale: s1))
            cells.append(fallCell(img, scale: s2))
        }
        emitter.emitterCells = cells

        return emitter
    }
}

// MARK: - Shake effect for the "pop in" wobble

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 6
    var shakesPerUnit: CGFloat = 2
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: t, y: 0))
    }
}

// MARK: - Main View

struct HeroDetailView: View {
    let hero: HeroDetail
    let collectedCount: Int
    let totalCount: Int

    @State private var showConfetti = false
    @State private var showHeroPanel = false
    @State private var showVerse = false
    @State private var showStory = false
    @State private var showAffirm = false
    @State private var showFav = false
    @State private var showBackBtn = false
    @State private var pulse: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#4F96FF"), Color(hex: "#B36BFF"), Color(hex: "#8AD96D")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(DecorDots())

            ScrollView {
                VStack(spacing: 18) {
                    // Header
                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(BQAFont.subheadline(17))
                            .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    HStack(spacing: 10) {
                        Text(hero.emoji).font(.system(size: 28))
                            .offset(y: pulse ? -3 : 3)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)
                        Text(hero.name)
                            .font(BQAFont.title(40))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    Text("Hero of \(hero.value)")
                        .font(BQAFont.body(22))
                        .foregroundStyle(.white.opacity(0.9))

                    // Cards
                    if showHeroPanel {
                        HeroPanelCard(hero: hero)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .modifier(ShakyOnAppear())
                            .padding(.horizontal, 16)
                    }

                    if showVerse {
                        VerseCard(verse: hero.verse, ref: hero.verseRef)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .modifier(ShakyOnAppear(strength: 5))
                            .padding(.horizontal, 16)
                    }

                    if showStory {
                        StoryCard(title: "Hero Story", text: hero.story)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            .modifier(ShakyOnAppear(strength: 4))
                            .padding(.horizontal, 16)
                    }

                    if showAffirm {
                        GradientButton(
                            titleTop: "Be Like \(hero.name)!",
                            titleBottom: "Brave and full of \(hero.value.lowercased())! ⚡️",
                            colors: [Color(hex: "#7CB7FF"), Color(hex: "#B36BFF"), Color(hex: "#FFB661")]
                        )
                        .transition(.scale.combined(with: .opacity))
                        .modifier(ShakyOnAppear(strength: 3))
                        .padding(.horizontal, 16)
                    }

                    if showFav {
                        FatPillButton(
                            title: "Add to Favorites",
                            bg: Color(hex: "#FF8A3C")
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .modifier(ShakyOnAppear(strength: 2.5))
                        .padding(.horizontal, 16)
                    }

                    if showBackBtn {
                        FatPillButton(
                            title: "←  Back to Album",
                            gradient: [Color(hex: "#7CB7FF"), Color(hex: "#B36BFF"), Color(hex: "#6ED47A"), Color(hex: "#FFB661")]
                        ) {
                            dismiss()
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .modifier(ShakyOnAppear(strength: 2))
                        .padding(.horizontal, 16)

                        VStack(spacing: 8) {
                            Text("🏆 You've unlocked \(collectedCount)/\(totalCount) Heroes!")
                                .font(BQAFont.body(15))
                                .foregroundStyle(.white.opacity(0.95))
                            HStack(spacing: 6) {
                                ForEach(0..<5) { _ in
                                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
                .padding(.bottom, 12)
            }

            // Confetti overlay (now colorful & both corners)
            ConfettiView(start: showConfetti)
                .allowsHitTesting(false)
        }
        .onAppear {
            pulse = true
            showConfetti = true
            withAnimation(.easeOut(duration: 0.45)) { showHeroPanel = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                withAnimation(.easeOut(duration: 0.45)) { showVerse = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation(.easeOut(duration: 0.45)) { showStory = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { showAffirm = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { showFav = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { showBackBtn = true }
            }
        }
    }
}

// MARK: - Little helper to shake once on appear

struct ShakyOnAppear: ViewModifier {
    var strength: CGFloat = 6
    @State private var t: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(amount: strength, shakesPerUnit: 2, animatableData: t))
            .onAppear { withAnimation(.easeOut(duration: 0.5)) { t = 1 } }
    }
}

// MARK: - Sections (use playful fonts)

private struct HeroPanelCard: View {
    let hero: HeroDetail
    private let inner = LinearGradient(
        colors: [Color(hex: "#FFEAA7"), Color.white.opacity(0.92), Color(hex: "#DFF0FF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    var body: some View {
        VStack(spacing: 12) {
            Text(hero.emoji)
                .font(.system(size: 60))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
                .padding(.top, 10)

            Text(hero.name)
                .font(BQAFont.heavy(30))
                .foregroundStyle(Color(hex: "#1F6FE5"))

            HStack {
                Image(systemName: "star.fill").foregroundStyle(.white)
                Text(hero.value)
                    .font(BQAFont.subheadline(17))
                    .foregroundStyle(.white)
            }
            .frame(height: 44)
            .frame(maxWidth: 220)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#7CB7FF"), Color(hex: "#B36BFF"), Color(hex: "#FFB661")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 5)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(inner)
                .shadow(color: Color.yellow.opacity(0.35), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.yellow.opacity(0.7), lineWidth: 3)
        )
    }
}

private struct VerseCard: View {
    let verse: String
    let ref: String
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "#1F6FE5"))
                Text("Bible Verse")
                    .font(BQAFont.heavy(22))
                    .foregroundStyle(Color(hex: "#1F6FE5"))
                Spacer()
            }
            Text("“\(verse)”")
                .font(BQAFont.body(20))
                .multilineTextAlignment(.center)
                .padding(.top, 6)
            Text(ref)
                .font(BQAFont.body(14))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

private struct StoryCard: View {
    let title: String
    let text: String
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(hex: "#FF8A3C"))
                Text(title)
                    .font(BQAFont.heavy(22))
                    .foregroundStyle(Color(hex: "#1F6FE5"))
                Spacer()
            }
            Text(text)
                .font(BQAFont.body(18))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
    }
}

private struct GradientButton: View {
    let titleTop: String
    let titleBottom: String
    let colors: [Color]
    var body: some View {
        VStack(spacing: 6) {
            Text(titleTop)
                .font(BQAFont.heavy(18))
                .foregroundStyle(.white)
            Text(titleBottom)
                .font(BQAFont.body(15))
                .foregroundStyle(.white.opacity(0.95))
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
    }
}

private struct FatPillButton: View {
    var title: String
    var bg: Color? = nil
    var gradient: [Color]? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BQAFont.heavy(18))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(
                    Group {
                        if let gradient {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                        } else if let bg {
                            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(bg)
                        } else {
                            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.blue)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.8), lineWidth: 2)
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 14, x: 0, y: 8)
    }
}

private struct DecorDots: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.18)).frame(width: 180).offset(x: -140, y: 120)
            Circle().fill(Color.white.opacity(0.16)).frame(width: 130).offset(x: 140, y: -60)
            Circle().fill(Color.white.opacity(0.14)).frame(width: 120).offset(x: 120, y: 420)
        }
        .allowsHitTesting(false)
    }
}



// MARK: - Preview

#Preview {
    NavigationStack {
        HeroDetailView(
            hero: HeroDetail(
                name: "David",
                title: "Hero of Courage",
                value: "Courage",
                emoji: "🪨",
                verse: "Be strong and courageous.",
                verseRef: "Joshua 1:9",
                story: "A young shepherd boy who trusted God and defeated a giant with just a sling and a stone. He shows us that with faith, even the smallest person can do mighty things!"
            ),
            collectedCount: 4,
            totalCount: 20
        )
    }
}

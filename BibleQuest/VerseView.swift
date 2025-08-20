import SwiftUI
import UIKit

// MARK: - Fonts (rounded / playful)
enum VerseFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func heavy(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
}

// MARK: - Confetti (random radial bursts across the screen)
// MARK: - Confetti (random radial bursts — smaller + *natural* fall/fade)
struct VerseConfettiView: UIViewRepresentable {
    var start: Bool
    var duration: TimeInterval = 1.0            // brief birth window (explosion)
    var baseScale: CGFloat = 0.11               // a touch smaller

    func makeUIView(context: Context) -> Host { Host() }
    func updateUIView(_ v: Host, context: Context) {
        v.start = start
        v.duration = duration
        v.baseScale = baseScale
    }

    final class Host: UIView {
        var start: Bool = false { didSet { update() } }
        var duration: TimeInterval = 1.0
        var baseScale: CGFloat = 0.11

        private var emitters: [CAEmitterLayer] = []
        private var anchors: [CGPoint] = []

        override func layoutSubviews() {
            super.layoutSubviews()
            for (i, e) in emitters.enumerated() where i < anchors.count {
                let u = anchors[i]
                e.emitterPosition = CGPoint(x: bounds.width * u.x, y: bounds.height * u.y)
            }
        }

        private func update() {
            layer.sublayers?.removeAll(where: { $0.name?.hasPrefix("Burst_") == true })
            emitters.removeAll()
            anchors.removeAll()
            guard start, bounds.width > 0, bounds.height > 0 else { return }

            let n = Int.random(in: 6...10)
            for i in 0..<n {
                let u = CGPoint(x: CGFloat.random(in: 0.12...0.88),
                                y: CGFloat.random(in: 0.08...0.70))
                anchors.append(u)

                let e = makeEmitter(name: "Burst_\(i)")
                e.emitterPosition = CGPoint(x: bounds.width * u.x, y: bounds.height * u.y)
                layer.addSublayer(e)
                emitters.append(e)
            }

            // Stop birthing quickly so it reads like an explosion
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.emitters.forEach { $0.birthRate = 0 }
            }

            // Cleanup *after* particles have had time to fall & fade out
            let maxLifetime: TimeInterval = 6.5
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + maxLifetime + 0.8) { [weak self] in
                self?.layer.sublayers?.removeAll(where: { $0.name?.hasPrefix("Burst_") == true })
                self?.emitters.removeAll()
                self?.anchors.removeAll()
            }
        }

        private func makeEmitter(name: String) -> CAEmitterLayer {
            let e = CAEmitterLayer()
            e.name = name
            e.emitterShape = .point
            e.emitterSize = .init(width: 1, height: 1)
            e.beginTime = CACurrentMediaTime()
            e.renderMode = .oldestLast   // smoother layering (prevents pop)

            let cgImgs = ["blue","orange","purple","star","square"]
                .compactMap { UIImage(named: $0)?.cgImage }

            func cell(_ cg: CGImage, s: CGFloat) -> CAEmitterCell {
                let c = CAEmitterCell()
                c.contents = cg
                c.birthRate = 36
                c.lifetime = 20.0                       // longer life
                c.lifetimeRange = 2.0
                c.velocity = CGFloat.random(in: 220...360)
                c.velocityRange = 140
                c.emissionLongitude = 0                // 360° spray
                c.emissionRange = .pi * 2
                c.yAcceleration = CGFloat.random(in: 320...520)  // fall out of view
                c.xAcceleration = 0
                c.spin = 6
                c.spinRange = 8
                c.scale = s
                c.scaleRange = s * 0.25
                c.scaleSpeed = -0.06                   // gentle shrink while falling
                c.alphaRange = 0.0
                c.alphaSpeed = -0.12                   // *slower* fade (no sudden vanish)
                return c
            }

            e.emitterCells = cgImgs.flatMap {
                [cell($0, s: baseScale * 0.90), cell($0, s: baseScale * 0.60)]
            }
            return e
        }
    }
}

// MARK: - Floating background icons (trophies, bolts, stars)
private struct FloatingIcons: View {
    struct Item: Identifiable { let id = UUID(); let symbol: String; let x: CGFloat; let delay: Double }
    let items: [Item] = [
        .init(symbol: "bolt.fill",   x: -120, delay: 0.0),
        .init(symbol: "star.fill",   x:  100, delay: 0.4),
        .init(symbol: "trophy.fill", x:  -40, delay: 0.8),
        .init(symbol: "bolt.fill",   x:  160, delay: 1.0),
        .init(symbol: "star.fill",   x: -180, delay: 1.2),
    ]
    @State private var t: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(items) { it in
                    let height = geo.size.height + 200
                    Image(systemName: it.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.yellow.opacity(0.5))
                        .rotationEffect(.degrees(Double(t * 30) + it.delay * 90))
                        .offset(
                            x: it.x,
                            y: (height * (1 - t)).truncatingRemainder(dividingBy: height) - 100
                        )
                        .animation(
                            .linear(duration: 10).repeatForever(autoreverses: false).delay(it.delay),
                            value: t
                        )
                }
            }
            .onAppear { t = 1 }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Main View

struct VerseView: View {
    // Supply an image from your DB/service when constructing VerseView.
    var avatarImage: UIImage? = nil

    @State private var isActivated = false
    @State private var fireConfetti = false
    @State private var flash = false
    @State private var spinSparkles = false
    @State private var streakDays: Int = 3   // plug in your real streak

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex:"#CFEAFF"), Color(hex:"#E8F2FF")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            FloatingIcons() // subtle moving trophies/bolts/stars

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {

                    // Header
                    VStack(spacing: 8) {
                        Text("Today’s Verse")
                            .font(VerseFont.display(44))
                            .foregroundStyle(Color(hex:"#1F6FE5"))
                        Text("Power-Up!")
                            .font(VerseFont.display(44))
                            .foregroundStyle(Color(hex:"#1F6FE5"))
                            .padding(.top, -8)

                        Text("God’s Word is your superpower! ⚡️")
                            .font(VerseFont.body(20))
                            .foregroundStyle(Color(hex:"#6C7A99"))
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 18)

                    // Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex:"#7CB7FF"),
                                        Color(hex:"#B36BFF"),
                                        Color(hex:"#FFB661"),
                                        Color(hex:"#6ED47A")
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.yellow.opacity(0.55), lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)

                        VStack(spacing: 18) {
                            // Rotating sparkle rim around avatar; supports runtime UIImage
                            ZStack {
                                Circle().strokeBorder(.white.opacity(0.25), lineWidth: 8)
                                    .frame(width: 166, height: 166)

                                Group {
                                    if let ui = avatarImage {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                    } else if UIImage(named: "power_kid") != nil {
                                        Image("power_kid")
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Text("🦸🏻‍♂️")
                                            .font(.system(size: 90))
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                }
                                .frame(width: 142, height: 142)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 6))

                                // rotating sparkles
                                ZStack {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .offset(x: 0, y: -96)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .offset(x: 86, y: 34)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .offset(x: -86, y: 34)
                                }
                                .rotationEffect(.degrees(spinSparkles ? 360 : 0))
                                .animation(
                                    spinSparkles
                                    ? .linear(duration: 2.2).repeatForever(autoreverses: false)
                                    : .default,
                                    value: spinSparkles
                                )
                            }
                            .padding(.top, 20)

                            // Verse text
                            VStack(spacing: 10) {
                                Text("“Be strong and courageous.”")
                                    .multilineTextAlignment(.center)
                                    .font(VerseFont.display(36))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .minimumScaleFactor(0.8)

                                Text("– Joshua 1:9")
                                    .font(VerseFont.body(22))
                                    .foregroundStyle(.white.opacity(0.95))
                            }
                            .padding(.horizontal, 24)

                            if isActivated {
                                // Activated panel
                                VStack(spacing: 16) {
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .fill(Color.white.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                                .stroke(.white.opacity(0.7), lineWidth: 2)
                                        )
                                        .frame(height: 110)
                                        .overlay(
                                            VStack(spacing: 6) {
                                                Text("POWER")
                                                Text("ACTIVATED!")
                                            }
                                            .font(VerseFont.display(30))
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.center)
                                        )
                                        .overlay(
                                            HStack {
                                                Image(systemName: "star.fill")
                                                Spacer()
                                                Image(systemName: "star.fill")
                                            }
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.9))
                                            .padding(.horizontal, 22)
                                        )
                                        .modifier(FlashOverlay(doFlash: flash))

                                    Text("Your courage is boosted for today!")
                                        .font(VerseFont.heavy(22))
                                        .foregroundStyle(.white)
                                        .padding(.bottom, 8)

                                    HStack(spacing: 10) {
                                        Image(systemName: "sparkles")
                                        Text("Courage +100")
                                    }
                                    .font(VerseFont.display(22))
                                    .foregroundStyle(.white)
                                    .padding(.bottom, 8)
                                }
                                .transition(.opacity.combined(with: .scale))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 22)

                            } else {
                                // Activate button
                                Button {
                                    activate()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bolt.fill")
                                        Text("Activate Power-Up!")
                                            .font(VerseFont.heavy(24))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 78)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                                            .stroke(.white.opacity(0.9), lineWidth: 3)
                                    )
                                }
                                .padding(.horizontal, 22)
                                .padding(.bottom, 24)
                            }
                        }

                        // bright flash overlay when activating
                        if flash {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.white.opacity(0.25))
                                .allowsHitTesting(false)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    // Streak banner
                    StreakBanner(days: streakDays)
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                    Spacer(minLength: 24)
                }
            }

            // Confetti overlay
            VerseConfettiView(start: fireConfetti)
                .allowsHitTesting(false)
        }
    }

    private func activate() {
        // Activated UI
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            isActivated = true
        }

        // Start sparkles rotation
        spinSparkles = true

        // Confetti burst
        fireConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { fireConfetti = false }

        // Card flash (gentle pulses)
        flash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { flash = false }

        // (Optional) persist/increment streak in your model layer
        // streakDays += 1
    }
}

// MARK: - Helpers

/// Adds a soft “energy” flash that breathes while `doFlash` is true.
private struct FlashOverlay: ViewModifier {
    var doFlash: Bool
    @State private var alpha: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.22), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(alpha)
                    .allowsHitTesting(false)
            )
            .onChange(of: doFlash) { _, new in
                guard new else { alpha = 0; return }
                alpha = 0.0
                withAnimation(.easeInOut(duration: 0.28).repeatCount(4, autoreverses: true)) {
                    alpha = 1.0
                }
            }
    }
}

// Simple streak banner like your screenshot
private struct StreakBanner: View {
    let days: Int
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                Text("Power-Up Streak: \(days) Day\(days == 1 ? "" : "s")!")
            }
            .font(VerseFont.display(22))
            .foregroundStyle(Color(hex:"#1F6FE5"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        )
    }
}

// MARK: - Preview
#Preview {
    VerseView()
}

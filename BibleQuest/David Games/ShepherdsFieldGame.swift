import SwiftUI
import AVFoundation

// MARK: - Shepherd’s Field Game

struct ShepherdsFieldGame: View {
    @Environment(\.dismiss) private var dismiss   // 🔹 lets us go back
    var onComplete: (() -> Void)? = nil
    // 7 sheep total; some are hidden behind specific spots
    @State private var sheep: [Sheep] = [
        // Visible sheep (not hiddenUnderSpotID)
        .init(id: 0, nx: 0.18, ny: 0.16),
        .init(id: 1, nx: 0.88, ny: 0.18),
        // Hidden sheep: we’ll bind their hiddenUnderSpotID after spots are created (in onAppear)
        .init(id: 2, nx: 0.20, ny: 0.78),
        .init(id: 3, nx: 0.72, ny: 0.58),
        .init(id: 4, nx: 0.32, ny: 0.33),
        .init(id: 5, nx: 0.52, ny: 0.45),
        .init(id: 6, nx: 0.82, ny: 0.80),
    ]

    // Movable cover spots
    @State private var spots: [CoverSpot] = [
        // ⬆️ Barn moved from ny: 0.87 -> 0.18 (top‑right)
        .barn(nx: 0.86, ny: 0.18, width: 120),

        .rock(nx: 0.72, ny: 0.65, width: 90),
        .rock(nx: 0.45, ny: 0.60, width: 95),
        .bush(nx: 0.30, ny: 0.47, width: 140),

        // ⬆️ Bottom‑left bush moved from ny: 0.86 -> 0.20 (top‑left)
        .bush(nx: 0.18, ny: 0.20, width: 150),
    ]

    @State private var foundSheep = 0
    @State private var showWin = false
    @State private var seconds = 0
    @State private var timerRunning = true

    private let baaPlayer = BaaPlayer()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient (sky → field)
                LinearGradient(
                    colors: [Color(red: 0.60, green: 0.86, blue: 1.0),
                             Color(red: 0.78, green: 0.96, blue: 0.86)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // Decorative soft mounds (gives depth)
                FieldMounds()
                    .allowsHitTesting(false)

                // Top HUD (Title, counter, timer)
                VStack(spacing: 6) {
                    TopBar(found: foundSheep, total: sheep.count, seconds: seconds, onBack: { dismiss() })
                        .padding(.top, 8)
                    Spacer()
                }
                .padding(.horizontal, 16)

                // Instruction bubble
                VStack {
                    Spacer()
                    InstructionCard()
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 24)

                // Sheep Pen badge (bottom-right)
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        SheepPenBadge()
//                            .padding(.trailing, 16)
//                            .padding(.bottom, 24)
//                    }
//                }

                // SHEEP (rendered below covers so they can be hidden)
                ForEach(sheep) { s in
                    if !s.found {
                        // Hidden if the assigned spot exists and isn't moved yet
                        if let sid = s.hiddenUnderSpotID,
                           let spot = spots.first(where: { $0.id == sid }),
                           !spot.isMoved {
                            // do not show yet
                        } else {
                            SheepView()
                                .position(x: s.nx * geo.size.width,
                                          y: s.ny * geo.size.height)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        baaPlayer.play()
                                        markFound(s.id)
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }

                // MOVABLE COVERS (barn/rocks/bushes) – above sheep
                ForEach(spots.indices, id: \.self) { i in
                    let spot = spots[i]
                    MovableCover(spot: spot)
                        .position(x: spot.nx * geo.size.width,
                                  y: spot.ny * geo.size.height)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.74)) {
                                spots[i].isMoved.toggle()
                            }
                        }
                }

                // WIN MODAL
                if showWin {
                    WinModal(
                        seconds: seconds,
                        onPlayAgain: resetGame,
                        onBack: { dismiss() }
                    )
                    .onAppear {
                        onComplete?()   // 🔹 mark game completed in parent view
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onReceive(timer) { _ in
                guard timerRunning, !showWin else { return }
                seconds += 1
            }
            .onAppear {
                wireHiddenSheepToSpots()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers

    private func markFound(_ id: Int) {
        if let idx = sheep.firstIndex(where: { $0.id == id }) {
            sheep[idx].found = true
            foundSheep += 1
            if foundSheep == sheep.count {
                timerRunning = false
                withAnimation(.spring()) { showWin = true }
            }
        }
    }

    /// Assign specific sheep to hide under specific covers (IDs must exist)
    private func wireHiddenSheepToSpots() {
        guard spots.count >= 5 else { return }
        // Map sheep 2..6 to covers
        let mapping: [(Int, UUID)] = [
            (2, spots[4].id), // bottom-left bush
            (3, spots[1].id), // mid-right rock
            (4, spots[3].id), // mid-left bush
            (5, spots[2].id), // mid rock
            (6, spots[0].id), // barn
        ]
        for (sid, coverID) in mapping {
            if let index = sheep.firstIndex(where: { $0.id == sid }) {
                sheep[index].hiddenUnderSpotID = coverID
            }
        }
    }

    private func resetGame() {
        // Reset movement of covers
        spots = spots.map { s in var m = s; m.isMoved = false; return m }

        // Reset sheep
        for i in sheep.indices {
            sheep[i].found = false
        }
        foundSheep = 0
        seconds = 0
        timerRunning = true
        withAnimation { showWin = false }
    }
}

// MARK: - Models

struct Sheep: Identifiable, Equatable {
    let id: Int
    let nx: CGFloat  // normalized (0...1)
    let ny: CGFloat
    var hiddenUnderSpotID: UUID? = nil
    var found: Bool = false
}

struct CoverSpot: Identifiable, Equatable {
    enum Kind { case barn, rock, bush }
    let id = UUID()
    var kind: Kind
    var nx: CGFloat
    var ny: CGFloat
    var width: CGFloat
    var isMoved: Bool = false

    // Convenience factories
    static func barn(nx: CGFloat, ny: CGFloat, width: CGFloat) -> CoverSpot {
        .init(kind: .barn, nx: nx, ny: ny, width: width)
    }
    static func rock(nx: CGFloat, ny: CGFloat, width: CGFloat) -> CoverSpot {
        .init(kind: .rock, nx: nx, ny: ny, width: width)
    }
    static func bush(nx: CGFloat, ny: CGFloat, width: CGFloat) -> CoverSpot {
        .init(kind: .bush, nx: nx, ny: ny, width: width)
    }
}

// MARK: - UI Pieces

/// Big title + counter + timer, like the mockup
// MARK: - TopBar
private struct TopBar: View {
    let found: Int
    let total: Int
    let seconds: Int
    var onBack: () -> Void   // 🔹 added callback

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Button(action: onBack) {              // 🔹 call dismiss
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundStyle(.white.opacity(0.95))
                .font(.system(.headline, design: .rounded))
            }

            Spacer()

            VStack(spacing: 0) {
                Text("David the")
                Text("Shepherd")
            }
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(found)/\(total)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("🐑")
                        .font(.system(size: 22))
                }
                HStack(spacing: 6) {
                    Text("\(seconds)s")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("⏰")
                }
            }
        }
    }
}

/// Soft field blobs for depth
private struct FieldMounds: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color.green.opacity(0.35))
                .frame(width: 180, height: 60)
                .blur(radius: 0.5)
                .offset(x: -100, y: -140)

            Capsule().fill(Color.green.opacity(0.32))
                .frame(width: 220, height: 70)
                .offset(x: 40, y: -30)

            Capsule().fill(Color.gray.opacity(0.35))
                .frame(width: 120, height: 60)
                .offset(x: 120, y: 170)

            Capsule().fill(Color.green.opacity(0.34))
                .frame(width: 210, height: 66)
                .offset(x: -10, y: 320)
        }
    }
}

/// Instruction card (bottom center)
private struct InstructionCard: View {
    var body: some View {
        Text("👆 Tap a barn, rock, or bush to slide it aside! Find all 7 sheep — listen for the baa! 🐑")
            .font(.system(.body, design: .rounded))
            .multilineTextAlignment(.center)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 6)
            )
            .padding(.horizontal, 8)
    }
}

/// Sheep pen badge (bottom-right)
private struct SheepPenBadge: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Sheep Pen").font(.system(.headline, design: .rounded))
            Text("🏡")
                .font(.system(size: 30))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(.brown, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        )
    }
}

/// A single sheep (emoji with soft shadow)
private struct SheepView: View {
    @State private var wobble = false
    var body: some View {
        Text("🐑")
            .font(.system(size: 44))
            .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 3)
            .scaleEffect(wobble ? 1.04 : 0.98)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: wobble)
            .onAppear { wobble = true }
    }
}

/// Movable cover with 3D tilt and shadow
private struct MovableCover: View {
    let spot: CoverSpot
    @State private var tilt = false

    private var imageName: String {
        switch spot.kind {
        case .barn: return "barn"
        case .rock: return "rock"
        case .bush: return "bush"
        }
    }

    private var cornerRadius: CGFloat {
        spot.kind == .barn ? 8 : 22
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: spot.width)
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 12)
            .overlay(
                LinearGradient(colors: [Color.white.opacity(0.22), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .rotation3DEffect(.degrees(tilt ? -6 : 0), axis: (x: 0, y: 1, z: 0))
            .offset(x: spot.isMoved ? 90 : 0, y: 0)
            .onChange(of: spot.isMoved) { _, moved in
                withAnimation(.easeInOut(duration: 0.28)) { tilt = moved }
            }
            .onAppear { tilt = false }
            .accessibilityLabel(Text("Movable cover"))
    }
}

// MARK: - Win Modal

// MARK: - Win Modal (Full Screen)

private struct WinModal: View {
    let seconds: Int
    var onPlayAgain: () -> Void
    var onBack: () -> Void

    var body: some View {
        ZStack {
            // Full screen gradient
            LinearGradient(
                colors: [
                    Color(red: 0.56, green: 0.64, blue: 1.0),
                    Color(red: 1.0, green: 0.70, blue: 0.76),
                    Color(red: 1.0, green: 0.77, blue: 0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("✨ Well Done! ✨")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                Text("🐑")
                    .font(.system(size: 64))

                Text("You helped David gather all his sheep safely!")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 6) {
                    Text("Remember:")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("“The Lord is my shepherd, I shall not want.”")
                        .font(.system(.headline, design: .rounded))
                        .italic()
                        .foregroundStyle(.white)
                    Text("– Psalm 23:1")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding()
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))

                Text("Time: \(seconds)s")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))

                HStack(spacing: 24) {
                    Button(action: onPlayAgain) {
                        HStack { Image(systemName: "star.fill"); Text("Play Again") }
                            .font(.system(.headline, design: .rounded))
                            .padding(.horizontal, 24).padding(.vertical, 14)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.6), lineWidth: 2))
                            .foregroundStyle(.white)
                    }

                    Button(action: onBack) {
                        HStack { Image(systemName: "arrow.left"); Text("Adventures") }
                            .font(.system(.headline, design: .rounded))
                            .padding(.horizontal, 24).padding(.vertical, 14)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.6), lineWidth: 2))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
    }
}
// MARK: - Audio

final class BaaPlayer {
    private var player: AVAudioPlayer?
    func play() {
        guard let url = Bundle.main.url(forResource: "baa", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Error playing baa: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Shepherd’s Field") {
    ShepherdsFieldGame(onComplete: { print("Completed Shepherd’s Field ✅") })
}

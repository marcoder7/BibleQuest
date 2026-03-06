import SwiftUI
import AVFoundation

struct ArmorGame: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil

    @State private var helmetRemoved = false
    @State private var chestRemoved = false
    @State private var swordRemoved = false

    @State private var helmetOffset: CGSize = .zero
    @State private var chestOffset: CGSize = .zero
    @State private var swordOffset: CGSize = .zero

    @State private var helmetRotation: Double = 0
    @State private var chestScale: CGFloat = 1
    @State private var swordTilt: Double = 0
    @State private var swordSlide: CGFloat = 0

    @State private var showWin = false
    private let sfx = ArmorSoundPlayer()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Image("davidBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height + 100)
                    .clipped()
                    .ignoresSafeArea()

                // David
                Image("davidFull")
                    .resizable()
                    .scaledToFit()
                    .frame(height: geo.size.height * 0.68)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.55)

                // Helmet
                if !helmetRemoved {
                    Image("helmet")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .offset(helmetOffset)
                        .rotationEffect(.degrees(helmetRotation))
                        .position(x: geo.size.width / 2 - 8,
                                  y: geo.size.height * 0.36)
                        .gesture(dragGesture(for: .helmet, geo: geo))
                        .zIndex(2)
                }

                // Chest armour
                if !chestRemoved {
                    Image("bodyArmour")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .offset(chestOffset)
                        .scaleEffect(chestScale)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.55)
                        .gesture(dragGesture(for: .chest, geo: geo))
                        .zIndex(2)
                }

                // Sword
                if !swordRemoved {
                    Image("sword")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .offset(swordOffset)
                        .rotationEffect(.degrees(swordTilt))
                        .position(x: geo.size.width * 0.25 + swordSlide,
                                  y: geo.size.height * 0.50)
                        .gesture(dragGesture(for: .sword, geo: geo))
                        .zIndex(2)
                }

                // Armor Box
                VStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(colors: [.purple.opacity(0.85), .blue.opacity(0.85)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .strokeBorder(.white, style: StrokeStyle(lineWidth: 4, dash: [10]))
                            )
                            .frame(width: geo.size.width * 0.75, height: 140)
                            .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)

                        Text("🪖 Armor Box\nDrop armor here!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .zIndex(1)

                // ✅ Custom back button
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, geo.safeAreaInsets.top - 30)
                .padding(.horizontal, 16)
                .zIndex(5)

                // Win screen
                if showWin {
                    ZStack {
                        LinearGradient(
                            colors: [Color.bqBackgroundTop, Color(hex: "#FFB6B9")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()

                        WellDoneView(
                            emoji: "🛡️",
                            message: "David trusted God’s strength, not armor!",
                            verse: "David said… 'I cannot go with these, for I have not tested them.' So David put them off.",
                            reference: "1 Samuel 17:39",
                            seconds: 0,
                            onPlayAgain: resetGame,
                            onBack: { dismiss() }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    }
                    .zIndex(3)
                    .transition(.opacity.combined(with: .scale))
                    .onAppear { onComplete?() }
                }
            }
        }
        // 🔒 Hide system nav bar so kids can’t tap it
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }

    // MARK: - Gestures
    private func dragGesture(for item: ArmorPiece, geo: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                switch item {
                case .helmet: helmetOffset = value.translation
                case .chest: chestOffset = value.translation
                case .sword: swordOffset = value.translation
                }
            }
            .onEnded { value in
                let dropThreshold = geo.size.height * 0.75
                if value.location.y > dropThreshold {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        triggerRemoval(for: item)
                    }
                    sfx.playClank()
                    checkForWin()
                } else {
                    withAnimation(.spring()) {
                        switch item {
                        case .helmet: helmetOffset = .zero
                        case .chest: chestOffset = .zero
                        case .sword: swordOffset = .zero
                        }
                    }
                }
            }
    }

    private func triggerRemoval(for item: ArmorPiece) {
        switch item {
        case .helmet:
            helmetRotation = 360
            helmetRemoved = true
        case .chest:
            chestScale = 0.1
            chestRemoved = true
        case .sword:
            swordTilt = -45
            swordSlide = -200
            swordRemoved = true
        }
    }

    private func checkForWin() {
        if helmetRemoved && chestRemoved && swordRemoved {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showWin = true
            }
        }
    }

    private func resetGame() {
        helmetRemoved = false
        chestRemoved = false
        swordRemoved = false
        helmetOffset = .zero
        chestOffset = .zero
        swordOffset = .zero
        helmetRotation = 0
        chestScale = 1
        swordTilt = 0
        swordSlide = 0
        showWin = false
    }
}

private enum ArmorPiece { case helmet, chest, sword }

final class ArmorSoundPlayer {
    private var player: AVAudioPlayer?
    func playClank() {
        let options = ["clank1", "clank2", "clank3"]
        guard let chosen = options.randomElement(),
              let url = Bundle.main.url(forResource: chosen, withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("❌ Error playing sound: \(error.localizedDescription)")
        }
    }
}

#Preview { ArmorGame() }

import SwiftUI
import CoreMotion
import AVFoundation

struct ValleyOfElahGame: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil
    
    // MARK: - Game State
    @State private var davidX: CGFloat = 0.0 // horizontal balance offset
    @State private var davidY: CGFloat = 0.0 // progress (vertical)
    @State private var showWin = false
    @State private var showIntro = true
    @State private var isFalling = false
    @State private var verses: [FloatingWord] = []
    @State private var doubts: [FloatingWord] = []
    @State private var gameTimer: Timer?
    @State private var tiltBaselineX: CGFloat = 0
    @State private var hasCalibratedTilt = false
    
    private let motionManager = CMMotionManager()
    private let sfx = FaithSoundPlayer()
    
    private let moveSpeed: CGFloat = 0.004 // upward speed
    private let fallThreshold: CGFloat = 0.72 // lower threshold = a bit harder
    private let tiltSensitivity: CGFloat = 1.8
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 🌄 Background
                Image("valleyImg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.15))
                
                // ✨ Floating words (faith/doubt)
                ForEach(verses) { verse in
                    FloatingText(word: verse, color: .yellow, containerSize: geo.size)
                }
                ForEach(doubts) { doubt in
                    FloatingText(word: doubt, color: .red, containerSize: geo.size)
                }
                
                // 🧍‍♂️ David (the balance)
                Image("davidFull")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.35)
                    .rotationEffect(.degrees(Double(davidX * 30))) // tilt visual
                    .offset(x: davidX * geo.size.width * 0.4,
                            y: geo.size.height * (0.4 - davidY))
                    .animation(.easeOut(duration: 0.1), value: davidX)
                    .animation(.linear(duration: 0.05), value: davidY)
                    .shadow(radius: 10)
                
                // 👇 Fail popup
                if isFalling {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    FailOverlay(onPlayAgain: retryGame, onBack: { dismiss() })
                        .padding(.horizontal, 24)
                    .transition(.opacity)
                }
                
                // 🏁 Win screen
                if showWin {
                    ZStack {
                        LinearGradient(colors: [Color.bqBackgroundTop, Color(hex:"#FFB6B9")],
                                       startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                        
                        WellDoneView(
                            emoji: "⚖️",
                            message: "You kept your faith steady in the Valley of Elah!",
                            verse: "“The Lord saves not with sword and spear, for the battle is the Lord’s.”",
                            reference: "1 Samuel 17:47",
                            seconds: 0,
                            onPlayAgain: resetGame,
                            onBack: { dismiss() }
                        )
                    }
                    .onAppear { onComplete?() }
                }
                
                // 🕹️ Intro overlay
                if showIntro {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("⚖️ Steady Faith")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Tilt your device to help David walk up the valley.\nKeep him centered or he’ll lose balance and fall!")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        Button(action: startGame) {
                            Text("Begin")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [.blue, .purple],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 8)
                    )
                    .padding(30)
                }
                
                // ⬅️ Back button
                VStack {
                    HStack {
                        Button {
                            sfx.tap()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.top, geo.safeAreaInsets.top + 10)
                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Game Flow
    private func startGame() {
        gameTimer?.invalidate()
        motionManager.stopAccelerometerUpdates()

        showIntro = false
        isFalling = false
        showWin = false
        davidX = 0
        davidY = 0
        tiltBaselineX = 0
        hasCalibratedTilt = false
        verses.removeAll()
        doubts.removeAll()
        sfx.playStart()
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1/60
            motionManager.startAccelerometerUpdates(to: .main) { data, _ in
                guard let accel = data?.acceleration else { return }

                // Calibrate "neutral" hold position when the game starts.
                if !hasCalibratedTilt {
                    tiltBaselineX = CGFloat(accel.x)
                    hasCalibratedTilt = true
                }

                let delta = CGFloat(accel.x) - tiltBaselineX
                // Device tilt now matches on-screen direction (not inverted).
                let targetX = (delta * tiltSensitivity).clamped(to: -1.0...1.0)

                // Damp motion so small sensor noise does not cause runaway tilt.
                davidX = (davidX * 0.70 + targetX * 0.30).clamped(to: -1.2...1.2)
            }
        }
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
            guard !showWin, !isFalling else {
                timer.invalidate()
                gameTimer = nil
                return
            }
            
            davidY += moveSpeed
            
            // Add some random push from "doubts"
            if Int.random(in: 0...24) == 0 {
                let push = CGFloat.random(in: -0.5...0.5)
                davidX += push * 0.24
                spawnWord(faith: push > 0)
            }
            
            // Win
            if davidY >= 0.9 {
                timer.invalidate()
                gameTimer = nil
                winGame()
            }
            
            // Fail
            if abs(davidX) > fallThreshold {
                timer.invalidate()
                gameTimer = nil
                fallDown()
            }
        }
    }
    
    private func winGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        motionManager.stopAccelerometerUpdates()
        sfx.success()
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            showWin = true
        }
    }
    
    private func fallDown() {
        gameTimer?.invalidate()
        gameTimer = nil
        motionManager.stopAccelerometerUpdates()
        sfx.fail()
        withAnimation(.easeIn(duration: 0.6)) {
            isFalling = true
        }
    }

    private func retryGame() {
        startGame()
    }
    
    private func resetGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        motionManager.stopAccelerometerUpdates()
        showIntro = true
        showWin = false
        isFalling = false
        davidY = 0
        davidX = 0
    }
    
    // MARK: - Words
    
    private func spawnWord(faith: Bool) {
        let id = UUID()
        let x = CGFloat.random(in: 0.15...0.85)
        let text = faith
            ? ["“Do not fear.”", "“God is with you.”", "“Trust in Him.”"].randomElement()!
            : ["You’re too small!", "Turn back!", "You can’t win!"].randomElement()!
        
        let word = FloatingWord(id: id, text: text, x: x, y: 1.1, isFaith: faith)
        if faith {
            verses.append(word)
            sfx.sparkle()
        } else {
            doubts.append(word)
            sfx.rumble()
        }
        
        // animate float
        withAnimation(.easeOut(duration: 4)) {
            if faith {
                verses = verses.map { $0.id == id ? $0.withY(-0.2) : $0 }
            } else {
                doubts = doubts.map { $0.id == id ? $0.withY(-0.2) : $0 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            verses.removeAll { $0.id == id }
            doubts.removeAll { $0.id == id }
        }
    }
}

// MARK: - Floating Text + Model

private struct FloatingWord: Identifiable {
    let id: UUID
    let text: String
    let x: CGFloat
    let y: CGFloat
    let isFaith: Bool
    
    func withY(_ newY: CGFloat) -> FloatingWord {
        FloatingWord(id: id, text: text, x: x, y: newY, isFaith: isFaith)
    }
}

private struct FloatingText: View {
    let word: FloatingWord
    let color: Color
    let containerSize: CGSize
    var body: some View {
        Text(word.text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(color.opacity(0.95))
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
            .position(
                x: containerSize.width * word.x,
                y: containerSize.height * word.y
            )
            .animation(.easeOut(duration: 4), value: word.y)
    }
}

// MARK: - Sounds
final class FaithSoundPlayer {
    private var player: AVAudioPlayer?
    
    func playStart() { play("ui_tap") }
    func sparkle() { play("sparkle") }
    func rumble() { play("rumble") }
    func success() { play("success") }
    func fail() { play("fail") }
    func tap() { play("ui_tap") }
    
    private func play(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch { }
    }
}

// MARK: - Preview
#Preview {
    ValleyOfElahGame()
}

private struct FailOverlay: View {
    var onPlayAgain: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("😵 You Lost Balance")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("David toppled in the valley. Try again and keep him steady.")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)

            HStack(spacing: 14) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Adventures")
                    }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.6), lineWidth: 1.5))
                }

                Button(action: onPlayAgain) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Play Again")
                    }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.6), lineWidth: 1.5))
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 12)
    }
}

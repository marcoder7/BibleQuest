import SwiftUI

struct StreamOfStonesGame: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil

    @State private var birds: [Bird] = []
    @State private var stones = 5   // ⬅️ only 4 stones
    @State private var seconds = 0
    @State private var timerRunning = false
    @State private var showWin = false
    @State private var showInstructions = true
    @State private var showGameOver = false   // ⬅️ Uh oh! popup

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let birdSpawnTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.3)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // Stones pile (bottom-center)
                VStack {
                    Spacer()
                    Text("🪨".repeat(stones))
                        .font(.system(size: 44))   // ⬆️ make stones bigger since only 4
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.bottom, 40)
                }

                // Birds
                ForEach(birds) { bird in
                    BirdView(bird: bird)
                        .position(x: bird.x * geo.size.width, y: bird.y * geo.size.height)
                        .onTapGesture {
                            withAnimation {
                                if let idx = birds.firstIndex(where: { $0.id == bird.id }) {
                                    birds.remove(at: idx)
                                }
                            }
                        }
                }

                // HUD
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Label("Back", systemImage: "chevron.left")
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        VStack {
                            Text("Stone Guard")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(seconds)s ⏰")
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("🪨: \(stones)")
                            .foregroundStyle(.white)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal)
                    Spacer()
                }

                // START POPUP
                if showInstructions {
                    InstructionPopup(
                        title: "🪨 Stone Guard 🐦",
                        message: "Tap the birds before they reach the stones!\nProtect David’s bag for 30 seconds ⏰",
                        buttonText: "Start!",
                        onTap: {
                            withAnimation(.spring()) {
                                showInstructions = false
                                timerRunning = true
                            }
                        }
                    )
                }

                // GAME OVER POPUP
                if showGameOver {
                    InstructionPopup(
                        title: "😢 Uh oh!",
                        message: "The birds took all the stones.\nNo worries! Try again — you got this!",
                        buttonText: "Try Again",
                        onTap: { resetGame() }
                    )
                }

                // WIN
                if showWin {
                    WellDoneView(
                        emoji: "🪨",
                        message: "You protected David’s stones from the birds!",
                        verse: "He chose five smooth stones from the stream, put them in his shepherd’s bag.",
                        reference: "1 Samuel 17:40",
                        seconds: seconds,
                        onPlayAgain: resetGame,
                        onBack: { dismiss() }
                    )
                    .onAppear { onComplete?() }
                }
            }
            .onReceive(timer) { _ in
                guard timerRunning, !showWin, !showGameOver else { return }
                seconds += 1
                if seconds >= 30 {
                    timerRunning = false
                    withAnimation(.spring()) { showWin = true }
                }
            }
            .onReceive(birdSpawnTimer) { _ in
                guard timerRunning else { return }
                spawnBird()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Logic
    private func spawnBird() {
        let bird = Bird(x: CGFloat.random(in: 0.1...0.9), y: -0.1)
        birds.append(bird)

        // Birds fall a little quicker (4.5s)
        withAnimation(.linear(duration: 4.5)) {
            if let idx = birds.firstIndex(where: { $0.id == bird.id }) {
                birds[idx].y = 1.2
            }
        }

        // After flight, remove bird & steal stone
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            if let idx = birds.firstIndex(where: { $0.id == bird.id }) {
                birds.remove(at: idx)
                if stones > 0 {
                    stones -= 1
                    if stones == 0 {
                        timerRunning = false
                        withAnimation(.spring()) { showGameOver = true }
                    }
                }
            }
        }
    }

    private func resetGame() {
        stones = 4
        seconds = 0
        birds.removeAll()
        timerRunning = false
        showInstructions = true
        showGameOver = false
        withAnimation { showWin = false }
    }
}

// MARK: - Models

struct Bird: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
}

struct BirdView: View {
    let bird: Bird
    var body: some View {
        Text("🐦")
            .font(.system(size: 44))
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
            .rotationEffect(.degrees(Double.random(in: -10...10)))
    }
}

// MARK: - Shared Popups

private struct InstructionPopup: View {
    let title: String
    let message: String
    let buttonText: String
    let onTap: () -> Void

    var body: some View {
        Color.black.opacity(0.45).ignoresSafeArea()
        VStack(spacing: 18) {
            Text(title)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: onTap) {
                Text(buttonText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .padding(.horizontal, 50).padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color.pink, Color.orange],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [Color.blue, Color.purple],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 30)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Helpers
extension String {
    func `repeat`(_ n: Int) -> String {
        guard n > 0 else { return "" }
        return Array(repeating: self, count: n).joined()
    }
}

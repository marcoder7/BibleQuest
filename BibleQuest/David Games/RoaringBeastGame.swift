import SwiftUI
import UIKit
import AVFoundation

struct RoaringBeastGame: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil

    @State private var showIntro = true
    @State private var showWin = false
    @State private var showGameOver = false
    @State private var isRunning = false

    @State private var lane = 1
    @State private var lionLanePosition: CGFloat = 1
    @State private var isJumping = false
    @State private var jumpProgress: CGFloat = 0

    @State private var runPhase: CGFloat = 0
    @State private var timeRemaining: Double = 30
    @State private var elapsed: Double = 0

    @State private var obstacles: [RoaringObstacle] = []
    @State private var spawnAccumulator: Double = 0
    @State private var nextSpawnIn: Double = 0.9
    @State private var obstacleSpeed: CGFloat = 285
    @State private var musicPlayer: AVAudioPlayer?

    private let lanes = 3
    private let gameDuration: Double = 30
    private let jumpDuration: CGFloat = 0.58

    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let davidX = laneX(for: CGFloat(lane), in: size)
            let lionX = laneX(for: lionLanePosition, in: size)
            let davidY = davidBaseY(in: size) - currentJumpHeight()
            let lionY = lionBaseY(in: size) - currentJumpHeight() * 0.28
            let trackRect = canyonTrackRect(in: size)

            ZStack {
                RoaringCanyonBackdrop(trackRect: trackRect, scrollPhase: CGFloat(elapsed) * 280)

                // Obstacles
                ForEach(obstacles) { obstacle in
                    obstacleView(for: obstacle)
                        .frame(width: obstacleWidth(for: obstacle, in: size), height: obstacleHeight(for: obstacle))
                        .position(x: obstacleX(for: obstacle, in: size), y: obstacle.y)
                }

                // Chasing lion (sync animated)
                lionRunnerView(runPhase: runPhase)
                    .frame(width: 92, height: 92)
                    .position(x: lionX, y: lionY)
                    .shadow(color: .black.opacity(0.28), radius: 7, x: 0, y: 5)

                // David runner
                davidRunnerView(runPhase: runPhase)
                    .frame(width: 98, height: 102)
                    .position(x: davidX, y: davidY)
                    .shadow(color: .black.opacity(0.28), radius: 7, x: 0, y: 5)

                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            stopRunningMusic()
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Roaring Beast")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Swipe left/right to dodge, swipe up to jump")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.95))
                        }

                        Spacer()

                        Text("\(Int(ceil(timeRemaining)))s")
                            .font(.system(size: 23, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, geo.safeAreaInsets.top + 8)

                    Spacer()

                    if !showIntro && !showWin && !showGameOver {
                        Text(isJumping ? "Jumping" : "Keep running")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(.black.opacity(0.22), in: Capsule())
                            .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                    }
                }

                if showIntro {
                    RoaringOverlayCard(
                        title: "🦁 Roaring Beast",
                        message: "Run through the canyon for 30 seconds.\nSwipe left/right to avoid rocks and bushes.\nSwipe up to jump over cracks.",
                        buttonText: "Start Run"
                    ) {
                        startGame()
                    }
                }

                if showGameOver {
                    RoaringOverlayCard(
                        title: "Caught!",
                        message: "The beast closed in.\nTry again and keep dodging the obstacles!",
                        buttonText: "Retry"
                    ) {
                        resetGame(showIntroCard: true)
                    }
                }

                if showWin {
                    WellDoneView(
                        emoji: "🦁",
                        message: "You outran the roaring beast for 30 seconds!",
                        verse: "I struck it and rescued the sheep from its mouth.",
                        reference: "1 Samuel 17:35",
                        seconds: Int(gameDuration),
                        onPlayAgain: { resetGame(showIntroCard: true) },
                        onBack: { dismiss() }
                    )
                    .onAppear { onComplete?() }
                }
            }
            .contentShape(Rectangle())
            .gesture(swipeGesture)
            .onReceive(tick) { _ in
                updateGame(in: size, dt: 1.0 / 60.0)
            }
            .onDisappear {
                stopRunningMusic()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard isRunning, !showIntro, !showWin, !showGameOver else { return }
                let dx = value.translation.width
                let dy = value.translation.height

                if abs(dx) > abs(dy), abs(dx) > 36 {
                    if dx > 0 {
                        moveLane(1)
                    } else {
                        moveLane(-1)
                    }
                    return
                }

                if dy < -44, abs(dy) > abs(dx) {
                    jump()
                }
            }
    }

    private func moveLane(_ delta: Int) {
        let next = (lane + delta).clamped(to: 0...(lanes - 1))
        guard next != lane else { return }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
            lane = next
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func jump() {
        guard !isJumping else { return }
        isJumping = true
        jumpProgress = 0
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    private func updateGame(in size: CGSize, dt: Double) {
        guard isRunning, !showIntro, !showWin, !showGameOver else { return }

        elapsed += dt
        timeRemaining = max(0, gameDuration - elapsed)
        runPhase += CGFloat(dt) * 9.5

        // Lion follows David lane with slight lag.
        lionLanePosition += (CGFloat(lane) - lionLanePosition) * 0.12

        if isJumping {
            jumpProgress += CGFloat(dt) / jumpDuration
            if jumpProgress >= 1 {
                jumpProgress = 0
                isJumping = false
            }
        }

        obstacleSpeed = min(390, 285 + CGFloat(elapsed) * 3.4)

        spawnAccumulator += dt
        if spawnAccumulator >= nextSpawnIn {
            spawnAccumulator = 0
            nextSpawnIn = Double.random(in: 0.64...1.02)
            spawnObstacle()
        }

        for idx in obstacles.indices {
            obstacles[idx].y += obstacleSpeed * CGFloat(dt)
        }

        evaluateCollisions(in: size)
        obstacles.removeAll { $0.y > size.height + 120 }

        if timeRemaining <= 0 {
            isRunning = false
            stopRunningMusic()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                showWin = true
            }
        }
    }

    private func evaluateCollisions(in size: CGSize) {
        let davidCollisionY = davidBaseY(in: size) - currentJumpHeight() + 16

        for obstacle in obstacles {
            let laneMatch = obstacle.spansAllLanes || obstacle.lane == lane
            let nearRunner = abs(obstacle.y - davidCollisionY) < 48
            guard laneMatch, nearRunner else { continue }

            switch obstacle.type {
            case .crack:
                if !isJumping {
                    triggerGameOver()
                    return
                }
            case .rock, .bush:
                triggerGameOver()
                return
            }
        }
    }

    private func triggerGameOver() {
        isRunning = false
        stopRunningMusic()
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            showGameOver = true
        }
    }

    private func spawnObstacle() {
        let chosenLane = Int.random(in: 0..<(lanes))

        let roll = Int.random(in: 0...99)
        let type: RoaringObstacleType
        if roll < 40 {
            type = .crack
        } else if roll < 74 {
            type = .rock
        } else {
            type = .bush
        }

        let spawnY: CGFloat = -80
        let spansAllLanes = (type == .crack) && Bool.random(probability: 0.38)
        obstacles.append(
            RoaringObstacle(
                lane: chosenLane,
                y: spawnY,
                type: type,
                spansAllLanes: spansAllLanes
            )
        )
    }

    private func canyonTrackRect(in size: CGSize) -> CGRect {
        let width = size.width * 0.72
        let height = size.height * 1.08
        return CGRect(
            x: (size.width - width) / 2,
            y: size.height * -0.04,
            width: width,
            height: height
        )
    }

    private func laneX(for lanePosition: CGFloat, in size: CGSize) -> CGFloat {
        let track = canyonTrackRect(in: size)
        let laneSpacing = track.width / CGFloat(max(1, lanes - 1))
        return track.minX + laneSpacing * lanePosition
    }

    private func davidBaseY(in size: CGSize) -> CGFloat {
        size.height * 0.70
    }

    private func lionBaseY(in size: CGSize) -> CGFloat {
        size.height * 0.82
    }

    private func currentJumpHeight() -> CGFloat {
        guard isJumping else { return 0 }
        return sin(jumpProgress * .pi) * 104
    }

    private func obstacleWidth(for obstacle: RoaringObstacle, in size: CGSize) -> CGFloat {
        if obstacle.type == .crack && obstacle.spansAllLanes {
            return canyonTrackRect(in: size).width * 0.92
        }
        return 96
    }

    private func obstacleHeight(for obstacle: RoaringObstacle) -> CGFloat {
        obstacle.type == .crack ? 34 : 76
    }

    private func obstacleX(for obstacle: RoaringObstacle, in size: CGSize) -> CGFloat {
        if obstacle.type == .crack && obstacle.spansAllLanes {
            return canyonTrackRect(in: size).midX
        }
        return laneX(for: CGFloat(obstacle.lane), in: size)
    }

    private func startGame() {
        resetGame(showIntroCard: false)
        startRunningMusic()
        isRunning = true
    }

    private func resetGame(showIntroCard: Bool) {
        if showIntroCard {
            stopRunningMusic()
        }
        showIntro = showIntroCard
        showWin = false
        showGameOver = false
        isRunning = !showIntroCard

        lane = 1
        lionLanePosition = 1
        isJumping = false
        jumpProgress = 0

        runPhase = 0
        timeRemaining = gameDuration
        elapsed = 0

        obstacles.removeAll()
        spawnAccumulator = 0
        nextSpawnIn = 0.85
        obstacleSpeed = 285
    }

    @ViewBuilder
    private func obstacleView(for obstacle: RoaringObstacle) -> some View {
        switch obstacle.type {
        case .rock:
            if UIImage(named: "rock") != nil {
                Image("rock")
                    .resizable()
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
            } else {
                Circle()
                    .fill(Color(hex: "#6E6E6E"))
                    .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
                    .padding(12)
            }
        case .bush:
            if UIImage(named: "bush") != nil {
                Image("bush")
                    .resizable()
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
            } else {
                Text("🌿")
                    .font(.system(size: 48))
            }
        case .crack:
            CrackObstacle()
                .fill(Color(hex: "#4B3A2B"))
                .overlay(CrackObstacle().stroke(Color.black.opacity(0.35), lineWidth: 2))
                .overlay(
                    CrackVeinLines(spansAllLanes: obstacle.spansAllLanes)
                        .stroke(Color.black.opacity(0.5), lineWidth: obstacle.spansAllLanes ? 2 : 1.5)
                )
                .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 6)
        }
    }

    @ViewBuilder
    private func davidRunnerView(runPhase: CGFloat) -> some View {
        let bob = sin(runPhase * 2.5) * 4
        let tilt = sin(runPhase * 2.5) * 2

        Group {
            if let imageName = firstAvailableAsset(["runningDavid", "davidFullBody", "davidFull", "david2", "david"]) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("🏃🏻")
                    .font(.system(size: 62))
            }
        }
        .offset(y: bob)
        .rotationEffect(.degrees(Double(tilt)))
    }

    @ViewBuilder
    private func lionRunnerView(runPhase: CGFloat) -> some View {
        let bob = sin(runPhase * 2.5) * 3
        let bounce = 1 + 0.03 * sin(runPhase * 2.5)

        Group {
            if let imageName = firstAvailableAsset(["runningLion", "runnningLion", "lionRun", "lion", "roaringBeast", "beast"]) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("🦁")
                    .font(.system(size: 56))
                    .frame(width: 82, height: 82)
                    .background(
                        Circle()
                            .fill(Color(hex: "#F9D69A").opacity(0.88))
                    )
            }
        }
        .offset(y: bob)
        .scaleEffect(CGSize(width: bounce, height: 1 / bounce))
    }

    private func firstAvailableAsset(_ names: [String]) -> String? {
        for name in names where UIImage(named: name) != nil {
            return name
        }
        return nil
    }

    private func startRunningMusic() {
        guard musicPlayer?.isPlaying != true else { return }

        let directURL = Bundle.main.url(forResource: "runningBeastMusic", withExtension: "m4a")
        let subdirURL = Bundle.main.url(forResource: "runningBeastMusic", withExtension: "m4a", subdirectory: "David Games/Audio")
        guard let url = directURL ?? subdirURL else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.78
            player.prepareToPlay()
            player.play()
            musicPlayer = player
        } catch { }
    }

    private func stopRunningMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
}

private enum RoaringObstacleType: CaseIterable {
    case crack
    case rock
    case bush
}

private struct RoaringObstacle: Identifiable {
    let id = UUID()
    let lane: Int
    var y: CGFloat
    let type: RoaringObstacleType
    let spansAllLanes: Bool
}

private struct CrackObstacle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 4, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + 6))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - 5))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.56, y: rect.minY + 8))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.74, y: rect.maxY - 6))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY))

        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.midY + 10))
        path.addLine(to: CGPoint(x: rect.minX + 4, y: rect.midY + 10))
        path.closeSubpath()
        return path
    }
}

private struct CrackVeinLines: Shape {
    let spansAllLanes: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // central jagged seam
        path.move(to: CGPoint(x: rect.minX + 6, y: rect.midY + 5))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY - 2))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.midY + 6))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.midY - 4))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.69, y: rect.midY + 7))
        path.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.midY - 1))

        // for full-lane cracks, add extra veins aligned to all columns
        if spansAllLanes {
            let first = rect.minX + rect.width / 3
            let second = rect.minX + rect.width * 2 / 3

            path.move(to: CGPoint(x: first - 14, y: rect.midY + 6))
            path.addLine(to: CGPoint(x: first - 6, y: rect.midY - 4))
            path.addLine(to: CGPoint(x: first + 8, y: rect.midY + 5))

            path.move(to: CGPoint(x: second - 10, y: rect.midY - 5))
            path.addLine(to: CGPoint(x: second + 2, y: rect.midY + 6))
            path.addLine(to: CGPoint(x: second + 14, y: rect.midY - 2))
        }

        return path
    }
}

private struct CanyonTrackTexture: View {
    let trackRect: CGRect
    let scrollPhase: CGFloat

    var body: some View {
        ZStack {
            // fast moving dust streaks in the running corridor
            ForEach(0..<36, id: \.self) { idx in
                let y = texturedY(index: idx)
                let xJitter = sin(CGFloat(idx) * 1.73) * trackRect.width * 0.40
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: trackRect.width * (idx % 3 == 0 ? 0.44 : 0.32), height: idx % 2 == 0 ? 9 : 7)
                    .rotationEffect(.degrees(idx.isMultiple(of: 2) ? -15 : 13))
                    .position(x: trackRect.midX + xJitter, y: y)
            }

            // small pebbles
            ForEach(0..<26, id: \.self) { idx in
                let x = trackRect.minX + 12 + (CGFloat((idx * 37) % 100) / 100) * (trackRect.width - 24)
                let y = trackRect.minY + CGFloat((idx * 97) % Int(max(trackRect.height, 1)))
                Circle()
                    .fill(Color.black.opacity(0.07))
                    .frame(width: CGFloat(5 + (idx % 4)), height: CGFloat(5 + (idx % 4)))
                    .position(x: x, y: y)
            }
        }
        .allowsHitTesting(false)
    }

    private func texturedY(index: Int) -> CGFloat {
        let spacing: CGFloat = 88
        let cycle = spacing * 30
        let y = (CGFloat(index) * spacing + scrollPhase * 0.62).truncatingRemainder(dividingBy: cycle)
        return trackRect.minY + y - 30
    }
}

private struct CanyonGlobalTexture: View {
    let scrollPhase: CGFloat

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // broad layered rock bands
                ForEach(0..<34, id: \.self) { idx in
                    let y = layerY(index: idx)
                    let width = size.width * (0.26 + CGFloat((idx * 17) % 55) / 100)
                    let x = size.width * (0.08 + CGFloat((idx * 37) % 84) / 100)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(idx.isMultiple(of: 2) ? 0.05 : 0.035))
                        .frame(width: width, height: CGFloat(8 + (idx % 4) * 3))
                        .rotationEffect(.degrees(idx.isMultiple(of: 2) ? -12 : 10))
                        .position(x: x, y: y)
                }

                // medium crack-like veins
                ForEach(0..<24, id: \.self) { idx in
                    let y = veinY(index: idx)
                    let x = size.width * (0.06 + CGFloat((idx * 29) % 88) / 100)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.black.opacity(0.08))
                        .frame(width: size.width * (0.10 + CGFloat((idx * 11) % 26) / 100), height: 4)
                        .rotationEffect(.degrees(idx.isMultiple(of: 2) ? -16 : 14))
                        .position(x: x, y: y)
                }

                // rough canyon grains
                ForEach(0..<90, id: \.self) { idx in
                    let x = size.width * (0.02 + CGFloat((idx * 53) % 100) / 102)
                    let y = size.height * (0.01 + CGFloat((idx * 29) % 100) / 100)
                    Circle()
                        .fill(Color.black.opacity(0.09))
                        .frame(width: CGFloat(4 + (idx % 5)), height: CGFloat(4 + (idx % 5)))
                        .position(x: x, y: y)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func layerY(index: Int) -> CGFloat {
        let spacing: CGFloat = 86
        let cycle = spacing * 40
        return (CGFloat(index) * spacing + scrollPhase * 0.58).truncatingRemainder(dividingBy: cycle) - 46
    }

    private func veinY(index: Int) -> CGFloat {
        let spacing: CGFloat = 132
        let cycle = spacing * 28
        return (CGFloat(index) * spacing + scrollPhase * 0.42).truncatingRemainder(dividingBy: cycle) - 30
    }
}

private struct RoaringCanyonBackdrop: View {
    let trackRect: CGRect
    let scrollPhase: CGFloat

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#A6653D"), Color(hex: "#8A4D31"), Color(hex: "#6B3925")],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // soft center warmth to avoid a boxed runway look
                RadialGradient(
                    colors: [Color(hex: "#D9A66B").opacity(0.38), .clear],
                    center: UnitPoint(x: 0.5, y: 0.57),
                    startRadius: 24,
                    endRadius: max(size.width, size.height) * 0.74
                )

                // canyon wall depth
                LinearGradient(
                    colors: [Color.black.opacity(0.24), .clear, .clear, Color.black.opacity(0.24)],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // irregular wall shadows
                ForEach(0..<20, id: \.self) { idx in
                    let onLeft = idx.isMultiple(of: 2)
                    let y = (CGFloat(idx) * 94 + scrollPhase * 0.34).truncatingRemainder(dividingBy: size.height + 220) - 110
                    let bubbleWidth = size.width * (0.30 + CGFloat((idx * 9) % 24) / 100)
                    let bubbleHeight = CGFloat(92 + (idx % 4) * 24)

                    Ellipse()
                        .fill(Color.black.opacity(0.10))
                        .frame(width: bubbleWidth, height: bubbleHeight)
                        .position(
                            x: onLeft ? -bubbleWidth * 0.34 : size.width + bubbleWidth * 0.34,
                            y: y
                        )
                }

                CanyonGlobalTexture(scrollPhase: scrollPhase)
                CanyonTrackTexture(trackRect: trackRect, scrollPhase: scrollPhase)
                    .opacity(0.78)
            }
            .ignoresSafeArea()
        }
    }
}

private struct RoaringOverlayCard: View {
    let title: String
    let message: String
    let buttonText: String
    var action: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.48).ignoresSafeArea()

            VStack(spacing: 18) {
                Text(title)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button(action: action) {
                    Text(buttonText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#2C7CF6"), Color(hex: "#66A7FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: "#4C88DE"), Color(hex: "#5E9DE8")], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 8)
            .padding(.horizontal, 28)
        }
    }
}

#Preview {
    NavigationStack {
        RoaringBeastGame()
    }
}

private extension Bool {
    static func random(probability: Double) -> Bool {
        let p = min(max(probability, 0), 1)
        return Double.random(in: 0...1) < p
    }
}

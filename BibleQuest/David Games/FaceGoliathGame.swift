import SwiftUI
import UIKit

struct FaceGoliathGame: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil

    @State private var showIntro = true
    @State private var showWin = false
    @State private var showGameOver = false
    @State private var stonesLeft = 5

    @State private var dragOffset: CGSize = .zero
    @State private var flyingStonePosition: CGPoint? = nil
    @State private var flyingVelocity: CGVector = .zero
    @State private var flightTimer: Timer?
    @State private var hitFlickerTask: Task<Void, Never>? = nil
    @State private var winSequenceTask: Task<Void, Never>? = nil
    @State private var showHitSprite = false
    @State private var showDefeatedSprite = false
    @State private var isDraggingStone = false
    @State private var hitRipples: [HitRipple] = []

    @State private var targets: [ShieldTarget] = ShieldTarget.defaults

    private let slingMaxPull: CGFloat = 110
    private let minLaunchPull: CGFloat = 24
    private let launchScale: CGFloat = 0.18
    private let gravity: CGFloat = 0.40
    private let stoneRadius: CGFloat = 12
    private let targetRadius: CGFloat = 44
    private let hitFlickerFrames = 8
    private let hitFlickerFrameNanos: UInt64 = 145_000_000

    var body: some View {
        GeometryReader { geo in
            let slingAnchor = CGPoint(x: geo.size.width * 0.2, y: geo.size.height * 0.78)
            let pouchPoint = pouchPoint(anchor: slingAnchor)
            let goliathFrame = goliathFrame(in: geo.size)
            let stonePoint = flyingStonePosition ?? pouchPoint
            let aimPath = projectedAimPath(from: slingAnchor, playSize: geo.size)
            let shieldsRemaining = targets.filter { !$0.isHit }.count
            let defeatedDrop = showDefeatedSprite ? geo.size.height * 0.09 : 0

            ZStack {
                FaceGoliathBackground()

                ZStack {
                    Rectangle()
                        .fill(Color(hex: "#7FBE8C").opacity(0.38))
                        .frame(height: geo.size.height * 0.30)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    GoliathSpriteView(showHitSprite: showHitSprite, showDefeatedSprite: showDefeatedSprite)
                        .frame(width: goliathFrame.width, height: goliathFrame.height)
                        .position(x: goliathFrame.midX, y: goliathFrame.midY + defeatedDrop)
                        .shadow(color: .black.opacity(showHitSprite ? 0.3 : 0.22), radius: showHitSprite ? 16 : 10, x: 0, y: 8)
                        .scaleEffect(showHitSprite ? 1.015 : 1.0)
                        .animation(.easeOut(duration: 0.12), value: showHitSprite)
                        .animation(.easeInOut(duration: 0.32), value: showDefeatedSprite)

                    ForEach(targets.indices, id: \.self) { index in
                        ShieldTargetView(isHit: targets[index].isHit)
                            .frame(width: targetRadius * 2, height: targetRadius * 2)
                            .position(targetPoint(for: targets[index], in: goliathFrame))
                    }

                    ForEach(hitRipples) { ripple in
                        ImpactRippleView(point: ripple.point)
                    }

                    ForEach(Array(aimPath.enumerated()), id: \.offset) { idx, point in
                        Circle()
                            .fill(.white.opacity(max(0.18, 0.62 - CGFloat(idx) * 0.06)))
                            .frame(width: max(4, 11 - CGFloat(idx) * 0.7), height: max(4, 11 - CGFloat(idx) * 0.7))
                            .position(point)
                    }

                    DavidSlingerSpriteView()
                        .frame(width: geo.size.width * 0.34, height: geo.size.height * 0.28)
                        .position(x: slingAnchor.x - 4, y: slingAnchor.y - 82)

                    SlingView(anchor: slingAnchor, pouch: pouchPoint)

                    Circle()
                        .stroke(.white.opacity(isDraggingStone ? 0.55 : 0.28), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                        .frame(width: 76, height: 76)
                        .position(slingAnchor)
                        .opacity(isStoneInFlight ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isDraggingStone)

                    Group {
                        if UIImage(named: "rock") != nil {
                            Image("rock")
                                .resizable()
                                .scaledToFit()
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#A0A0A0"), Color(hex: "#6E6E6E")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                        }
                    }
                        .frame(width: stoneRadius * 2.4, height: stoneRadius * 2.4)
                        .position(stonePoint)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 3)
                        .scaleEffect(isDraggingStone ? 1.08 : 1)
                        .animation(.easeOut(duration: 0.12), value: isDraggingStone)
                        .contentShape(Circle())
                        .gesture(slingDragGesture(from: slingAnchor, playSize: geo.size))

                    if !isStoneInFlight {
                        Circle()
                            .fill(.white.opacity(0.001))
                            .frame(width: 120, height: 120)
                            .position(pouchPoint)
                            .contentShape(Circle())
                            .gesture(slingDragGesture(from: slingAnchor, playSize: geo.size))
                    }
                }

                VStack(spacing: 0) {
                    FaceGoliathTopHUD(
                        safeTopInset: geo.safeAreaInsets.top,
                        stonesLeft: stonesLeft,
                        shieldsRemaining: shieldsRemaining,
                        totalShields: targets.count,
                        onBack: { dismiss() }
                    )

                    Spacer()

                    if !showIntro && !showWin && !showGameOver {
                        Text(isStoneInFlight ? "Stone in flight..." : "Drag, aim, and release")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.95))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.22), in: Capsule())
                            .padding(.bottom, geo.safeAreaInsets.bottom + 14)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: isStoneInFlight)
                    }
                }

                if showIntro {
                    FaceGoliathOverlayCard(
                        title: "📯 Face Goliath",
                        message: "Drag back the sling, aim carefully, and release.\nHit all three shield targets using up to five smooth stones.",
                        buttonText: "Start"
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showIntro = false
                        }
                    }
                }

                if showGameOver {
                    FaceGoliathOverlayCard(
                        title: "Try Again",
                        message: "You used all five stones.\nReset and aim for the shields again!",
                        buttonText: "Retry"
                    ) {
                        resetGame()
                    }
                }

                if showWin {
                    WellDoneView(
                        emoji: "🪨",
                        message: "Great aim! You hit Goliath's shields.",
                        verse: "David put his hand in his bag, took a stone... and struck the Philistine.",
                        reference: "1 Samuel 17:49",
                        seconds: 0,
                        onPlayAgain: resetGame,
                        onBack: { dismiss() }
                    )
                    .onAppear { onComplete?() }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .onDisappear {
                flightTimer?.invalidate()
                flightTimer = nil
                hitFlickerTask?.cancel()
                hitFlickerTask = nil
                winSequenceTask?.cancel()
                winSequenceTask = nil
                isDraggingStone = false
                hitRipples.removeAll()
            }
            .onChange(of: targets) { _, _ in
                evaluateWinState()
            }
        }
    }

    private var isStoneInFlight: Bool {
        flyingStonePosition != nil
    }

    private func pouchPoint(anchor: CGPoint) -> CGPoint {
        return CGPoint(x: anchor.x + dragOffset.width, y: anchor.y + dragOffset.height)
    }

    private func clampedOffset(_ value: CGSize, maxDistance: CGFloat) -> CGSize {
        let distance = sqrt(value.width * value.width + value.height * value.height)
        guard distance > maxDistance, distance > 0 else { return value }
        let scale = maxDistance / distance
        return CGSize(width: value.width * scale, height: value.height * scale)
    }

    private func slingDragGesture(from anchor: CGPoint, playSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !showIntro, !showWin, !showGameOver, stonesLeft > 0, !isStoneInFlight else { return }
                isDraggingStone = true
                dragOffset = clampedOffset(value.translation, maxDistance: slingMaxPull)
            }
            .onEnded { _ in
                isDraggingStone = false
                guard !showIntro, !showWin, !showGameOver, stonesLeft > 0, !isStoneInFlight else { return }
                launchStone(from: anchor, playSize: playSize)
            }
    }

    private func launchStone(from anchor: CGPoint, playSize: CGSize) {
        guard !showIntro, !showWin, !showGameOver, !isStoneInFlight, stonesLeft > 0 else {
            dragOffset = .zero
            return
        }

        let pullDistance = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
        guard pullDistance >= minLaunchPull else {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                dragOffset = .zero
            }
            return
        }

        stonesLeft -= 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let start = CGPoint(x: anchor.x + dragOffset.width, y: anchor.y + dragOffset.height)
        flyingStonePosition = start
        flyingVelocity = CGVector(dx: -dragOffset.width * launchScale, dy: -dragOffset.height * launchScale)
        dragOffset = .zero

        startFlightLoop(playSize: playSize)
    }

    private func startFlightLoop(playSize: CGSize) {
        flightTimer?.invalidate()
        flightTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            guard var pos = flyingStonePosition else {
                flightTimer?.invalidate()
                flightTimer = nil
                return
            }

            flyingVelocity.dy += gravity
            pos.x += flyingVelocity.dx
            pos.y += flyingVelocity.dy
            flyingStonePosition = pos

            if hitTarget(at: pos, playSize: playSize) {
                stopFlight(resetStone: true)
                return
            }

            if pos.x < -40 || pos.x > playSize.width + 40 || pos.y < -80 || pos.y > playSize.height + 40 {
                stopFlight(resetStone: true)
                return
            }
        }
    }

    private func hitTarget(at point: CGPoint, playSize: CGSize) -> Bool {
        let frame = goliathFrame(in: playSize)
        for index in targets.indices where !targets[index].isHit {
            let center = targetPoint(for: targets[index], in: frame)
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance <= (targetRadius + stoneRadius * 0.8) {
                targets[index].isHit = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                spawnHitRipple(at: center)
                triggerGoliathHitFlicker()
                return true
            }
        }
        return false
    }

    private func stopFlight(resetStone: Bool) {
        flightTimer?.invalidate()
        flightTimer = nil
        if resetStone {
            flyingStonePosition = nil
        }

        if targets.allSatisfy(\.isHit) {
            beginWinSequence()
            return
        }

        if stonesLeft == 0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showGameOver = true
            }
        }
    }

    private func evaluateWinState() {
        if targets.allSatisfy(\.isHit) && !showWin {
            beginWinSequence()
        }
    }

    private func projectedAimPath(from anchor: CGPoint, playSize: CGSize) -> [CGPoint] {
        guard !showIntro, !showWin, !showGameOver, !isStoneInFlight else { return [] }

        let pullDistance = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
        guard pullDistance >= minLaunchPull else { return [] }

        var points: [CGPoint] = []
        var pos = CGPoint(x: anchor.x + dragOffset.width, y: anchor.y + dragOffset.height)
        var vel = CGVector(dx: -dragOffset.width * launchScale, dy: -dragOffset.height * launchScale)

        for _ in 0..<18 {
            for _ in 0..<4 {
                vel.dy += gravity
                pos.x += vel.dx
                pos.y += vel.dy
            }

            if pos.x < -30 || pos.x > playSize.width + 30 || pos.y < -60 || pos.y > playSize.height + 20 {
                break
            }
            points.append(pos)
        }

        return points
    }

    private func targetPoint(for target: ShieldTarget, in frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.minX + frame.width * target.x,
            y: frame.minY + frame.height * target.y
        )
    }

    private func goliathFrame(in size: CGSize) -> CGRect {
        let width = size.width * 0.62
        let height = size.height * 0.84
        let x = size.width * 0.71 - (width / 2)
        let y = size.height * 0.60 - (height / 2)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func resetGame() {
        flightTimer?.invalidate()
        flightTimer = nil
        hitFlickerTask?.cancel()
        hitFlickerTask = nil
        winSequenceTask?.cancel()
        winSequenceTask = nil
        isDraggingStone = false
        hitRipples.removeAll()
        showHitSprite = false
        showDefeatedSprite = false
        flyingStonePosition = nil
        flyingVelocity = .zero
        dragOffset = .zero
        stonesLeft = 5
        showIntro = true
        showWin = false
        showGameOver = false
        targets = ShieldTarget.defaults
    }

    private func triggerGoliathHitFlicker() {
        guard !showDefeatedSprite else { return }
        hitFlickerTask?.cancel()
        hitFlickerTask = Task { @MainActor in
            for step in 0..<hitFlickerFrames {
                if Task.isCancelled { return }
                showHitSprite = step.isMultiple(of: 2)
                try? await Task.sleep(nanoseconds: hitFlickerFrameNanos)
            }
            showHitSprite = false
        }
    }

    private func spawnHitRipple(at point: CGPoint) {
        let ripple = HitRipple(point: point)
        hitRipples.append(ripple)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            hitRipples.removeAll { $0.id == ripple.id }
        }
    }

    private func beginWinSequence() {
        guard !showWin, !showDefeatedSprite else { return }
        winSequenceTask?.cancel()
        showHitSprite = false
        showDefeatedSprite = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        winSequenceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                showWin = true
            }
        }
    }
}

private struct FaceGoliathBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.28))
                .frame(width: 220, height: 220)
                .blur(radius: 3)
                .offset(x: 140, y: -290)

            Circle()
                .fill(Color(hex: "#A5C8F8").opacity(0.22))
                .frame(width: 180, height: 180)
                .offset(x: -130, y: -250)

            RoundedRectangle(cornerRadius: 140, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(width: 210, height: 74)
                .offset(x: -90, y: -310)
        }
    }
}

private struct FaceGoliathTopHUD: View {
    let safeTopInset: CGFloat
    let stonesLeft: Int
    let shieldsRemaining: Int
    let totalShields: Int
    var onBack: () -> Void

    private var shieldsHit: Int {
        max(0, totalShields - shieldsRemaining)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 7) {
                Text("Face Goliath")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Hit every shield in 5 stones")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)

            HStack(alignment: .top) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 7) {
                    HStack(spacing: 7) {
                        Text("🪨")
                        Text("\(stonesLeft)")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                    }

                    HStack(spacing: 4) {
                        ForEach(0..<max(totalShields, 1), id: \.self) { idx in
                            Capsule(style: .continuous)
                                .fill(idx < shieldsHit ? Color(hex: "#7EDFA7") : .white.opacity(0.32))
                                .frame(width: 22, height: 6)
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, safeTopInset + 8)
    }
}

private struct HitRipple: Identifiable {
    let id = UUID()
    let point: CGPoint
}

private struct ImpactRippleView: View {
    let point: CGPoint
    @State private var expanded = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.75), lineWidth: 4)
                .frame(width: 26, height: 26)
                .scaleEffect(expanded ? 2.3 : 0.65)
                .opacity(expanded ? 0 : 1)

            Circle()
                .fill(Color(hex: "#CDE3FF").opacity(0.45))
                .frame(width: 20, height: 20)
                .scaleEffect(expanded ? 0.2 : 1.0)
                .opacity(expanded ? 0 : 0.9)
        }
        .position(point)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.33)) {
                expanded = true
            }
        }
    }
}

private struct DavidSlingerSpriteView: View {
    private var spriteName: String? {
        let candidates = ["davidFullBody", "davidFull", "david2", "david"]
        for name in candidates where UIImage(named: name) != nil {
            return name
        }
        return nil
    }

    var body: some View {
        Group {
            if let spriteName {
                Image(spriteName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "figure.archery")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(16)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 5)
        .allowsHitTesting(false)
    }
}

private struct SlingView: View {
    let anchor: CGPoint
    let pouch: CGPoint

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: anchor.x - 16, y: anchor.y - 18))
                path.addLine(to: pouch)
                path.addLine(to: CGPoint(x: anchor.x + 16, y: anchor.y - 18))
            }
            .stroke(Color(hex: "#6E4D2F"), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: anchor.x - 14, y: anchor.y - 20))
                path.addLine(to: CGPoint(x: anchor.x - 6, y: anchor.y + 34))
                path.move(to: CGPoint(x: anchor.x + 14, y: anchor.y - 20))
                path.addLine(to: CGPoint(x: anchor.x + 6, y: anchor.y + 34))
            }
            .stroke(Color(hex: "#8B5E34"), style: StrokeStyle(lineWidth: 9, lineCap: .round))

            Circle()
                .fill(Color(hex: "#4B2E1E"))
                .frame(width: 24, height: 24)
                .position(pouch)
        }
        .allowsHitTesting(false)
    }
}

private struct GoliathSpriteView: View {
    let showHitSprite: Bool
    let showDefeatedSprite: Bool

    private var spriteName: String? {
        let defeatedCandidates = ["goliathBossDefeated", "goliathDefeated", "goliath_defeated"]
        let hitCandidates = ["goliathBossHit", "goliathHit", "goliath_hit"]
        let baseCandidates = ["goliathBoss", "goliath", "goliathImage", "giant", "bodyArmour"]
        let candidates: [String]
        if showDefeatedSprite {
            candidates = defeatedCandidates + baseCandidates
        } else if showHitSprite {
            candidates = hitCandidates + baseCandidates
        } else {
            candidates = baseCandidates
        }
        for name in candidates where UIImage(named: name) != nil {
            return name
        }
        return nil
    }

    var body: some View {
        Group {
            if let spriteName {
                Image(spriteName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(hex: "#6E4D2F").opacity(0.55))
                    .padding(.vertical, 40)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
    }
}

private struct ShieldTargetView: View {
    let isHit: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isHit ? [Color(hex: "#7EDFA7"), Color(hex: "#4CB57A")] : [Color(hex: "#B7C2D8"), Color(hex: "#8FA1C3")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.30)
            Circle()
                .stroke(isHit ? Color(hex: "#B8F1CD").opacity(0.95) : .white.opacity(0.85), lineWidth: 3)
            Image(systemName: isHit ? "checkmark.shield.fill" : "shield.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(isHit ? Color(hex: "#2A8E5C") : Color(hex: "#E85E5A"))
        }
        .scaleEffect(isHit ? 0.88 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: isHit)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}

private struct FaceGoliathOverlayCard: View {
    let title: String
    let message: String
    let buttonText: String
    var action: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 18) {
                Text(title)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                Button(action: action) {
                    Text(buttonText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 42)
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

private struct ShieldTarget: Identifiable, Equatable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    var isHit: Bool

    static let defaults: [ShieldTarget] = [
        ShieldTarget(x: 0.57, y: 0.40, isHit: false),
        ShieldTarget(x: 0.61, y: 0.58, isHit: false),
        ShieldTarget(x: 0.64, y: 0.72, isHit: false)
    ]
}

#Preview {
    NavigationStack {
        FaceGoliathGame()
    }
}

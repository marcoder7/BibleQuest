import SwiftUI
import Combine
import FirebaseAuth
import FirebaseDatabase

// MARK: - Adventure Model

struct AdventureNode: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let emoji: String
    let y: CGFloat
    let xOffset: CGFloat
}

// MARK: - View

struct AdventureView: View {
    // Map height
    private let mapHeight: CGFloat = 2800

    // Quest stops
    private let nodes: [AdventureNode] = [
        .init(title: "Shepherd’s Field", emoji: "🐑", y: 180,  xOffset: -60),
        .init(title: "Stream of Stones",  emoji: "🪨", y: 520,  xOffset: 40),
        .init(title: "Camp of Israel",    emoji: "🏕️", y: 900,  xOffset: -80),
        .init(title: "Valley of Elah",    emoji: "🛡️", y: 1250, xOffset: 70),
        .init(title: "Face Goliath",      emoji: "📯", y: 1600, xOffset: -60),
        .init(title: "The Sling",         emoji: "🏹", y: 1980, xOffset: 50),
        .init(title: "Victory!",          emoji: "👑", y: 2380, xOffset: -30)
    ]

    // Walking animation/progress
    @State private var isWalking = false
    @State private var progress: CGFloat = 0              // 0...1 over full path
    @State private var walkCancellable: AnyCancellable?

    // Scroll tracking
    @State private var currentAnchorY: CGFloat = 0

    // 🔹 User data from Firebase
    @State private var userName: String = "Explorer"
    @State private var heroKey: String = "david"   // keys like "david", "mary", "mosesAvatar", "noahAvatar"

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(colors: [Color(hex:"#CFEAFF"), Color(hex:"#E8F2FF")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack {
                            MapBackdrop(mapHeight: mapHeight)

                            AdventurePathShape(nodes: nodes)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex:"#7CB7FF"), Color(hex:"#B36BFF"), Color(hex:"#6ED47A")],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
                                )
                                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)

                            // ⤵︎ Make pins tappable and drive walking
                            ForEach(Array(nodes.enumerated()), id: \.element.id) { (idx, node) in
                                LocationPin(node: node) {
                                    walkToNode(idx)
                                }
                            }

                            // 🔹 Walking hero (uses selected avatar)
                            WalkingHero(heroKey: heroKey,
                                        progress: progress,
                                        nodes: nodes,
                                        mapHeight: mapHeight)
                                .onChange(of: progress) { _, newVal in
                                    let pos = positionAlongPath(progress: newVal, nodes: nodes)
                                    currentAnchorY = pos.y
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        proxy.scrollTo("anchor", anchor: UnitPoint(x: 0.5, y: min(0.5, (pos.y / mapHeight))))
                                    }
                                }

                            // Invisible anchor to follow hero
                            GeometryReader { _ in
                                Color.clear
                                    .frame(height: 1)
                                    .id("anchor")
                                    .offset(y: currentAnchorY)
                            }
                        }
                        .frame(height: mapHeight)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 30)
                        .padding(.bottom, 140)
                    }
                    .onAppear {
                        currentAnchorY = nodes.first?.y ?? 0
                        proxy.scrollTo("anchor", anchor: .top)
                    }
                }

                // Top UI
                VStack(spacing: 10) {
                    Text("\(userName)’s Adventure")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex:"#1F6FE5"))
                        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)

                    Text("Follow the quest and tap locations for story hints.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color(hex:"#6C7A99"))

                    Spacer()

                    HStack(spacing: 12) {
                        Button { jump(to: 0.0) } label: {
                            ControlPill(icon: "arrow.uturn.backward", title: "Start")
                        }
                        Button { toggleWalk() } label: {
                            ControlPill(icon: isWalking ? "pause.fill" : "play.fill",
                                        title: isWalking ? "Pause" : "Walk")
                        }
                        Button { jump(to: 1.0) } label: {
                            ControlPill(icon: "clock.fill", title: "Latest")
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
            }
            .overlay(alignment: .bottom) {
                PlayAdventurePill { toggleWalk() }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 90)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadUserProfile)   // 🔹 fetch Name & Hero
        }
    }

    // MARK: - Firebase

    private func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference()
            .child("Users")
            .child(uid)
            .observeSingleEvent(of: .value) { snapshot in
                guard let dict = snapshot.value as? [String: Any] else { return }

                if let name = (dict["Name"] as? String)?.trimmed(), !name.isEmpty {
                    self.userName = name
                } else if let dn = (dict["displayName"] as? String)?.trimmed(), !dn.isEmpty {
                    self.userName = dn
                } else if let gn = (dict["givenName"] as? String)?.trimmed(), !gn.isEmpty {
                    self.userName = gn
                } else if let email = dict["email"] as? String {
                    self.userName = email.components(separatedBy: "@").first ?? "Explorer"
                }

                if let hero = (dict["Hero"] as? String)?.trimmed(), !hero.isEmpty {
                    self.heroKey = hero
                }
            }
    }

    // MARK: - Movement

    /// Tap handler: walk to a specific node index.
    private func walkToNode(_ index: Int) {
        let n = max(1, nodes.count - 1)
        let target = CGFloat(index).clamped(to: 0...CGFloat(n)) / CGFloat(n)
        walk(to: target)
    }

    /// Walk to an arbitrary progress (0...1), pausing any current walk.
    private func walk(to targetProgress: CGFloat) {
        let start = progress.clamped(to: 0...1)
        let target = targetProgress.clamped(to: 0...1)
        guard target != start else { return }

        isWalking = true
        walkCancellable?.cancel()

        // Base: ~16s for a full path → scale by distance
        let fullPathSeconds: Double = 16.0
        let distance = abs(Double(target - start))
        let duration = max(0.30, fullPathSeconds * distance)
        let startDate = Date()

        walkCancellable = Timer.publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let t = Date().timeIntervalSince(startDate) / max(0.001, duration)
                let clampedT = min(1.0, t)
                let value = start + CGFloat(clampedT) * (target - start)

                withAnimation(.easeInOut(duration: 1/60)) {
                    progress = value
                }

                if clampedT >= 1.0 {
                    progress = target
                    walkCancellable?.cancel()
                    isWalking = false
                }
            }
    }

    private func toggleWalk() {
        if isWalking {
            isWalking = false
            walkCancellable?.cancel()
            return
        }
        // continue to next node boundary
        let start = progress
        let target = nextStopProgress(from: start)
        guard target > start else { return }
        walk(to: target)
    }

    private func nextStopProgress(from p: CGFloat) -> CGFloat {
        let n = max(1, nodes.count - 1)
        let raw = p.clamped(to: 0...1) * CGFloat(n)
        let nextIndex = min(n, Int(floor(raw)) + 1)
        return CGFloat(nextIndex) / CGFloat(n)
    }

    private func jump(to value: CGFloat) {
        walkCancellable?.cancel()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            progress = value.clamped(to: 0...1)
        }
        isWalking = false
    }
}

// MARK: - Backdrop

private struct MapBackdrop: View {
    let mapHeight: CGFloat
    var body: some View {
        ZStack {
            if UIImage(named: "map_vertical") != nil {
                Image("map_vertical")
                    .resizable()
                    .scaledToFill()
                    .frame(height: mapHeight)
                    .clipped()
                    .opacity(0.95)
            } else {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex:"#DAF2C2"), Color(hex:"#BEE8FF")],
                            startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 3)
                    )
            }
        }
    }
}

// MARK: - Path Shape

private struct AdventurePathShape: Shape {
    let nodes: [AdventureNode]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = nodes.first else { return path }

        let width = rect.width
        let start = CGPoint(x: width/2 + first.xOffset, y: first.y)
        path.move(to: start)

        for i in 1..<nodes.count {
            let p1 = CGPoint(x: width/2 + nodes[i-1].xOffset, y: nodes[i-1].y)
            let p2 = CGPoint(x: width/2 + nodes[i].xOffset,   y: nodes[i].y)
            let midY = (p1.y + p2.y) / 2
            let c1 = CGPoint(x: p1.x, y: midY)
            let c2 = CGPoint(x: p2.x, y: midY)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }
}

// MARK: - Marker Pins (now tappable)

private struct LocationPin: View {
    let node: AdventureNode
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(node.emoji)
                .font(.system(size: 28))
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 6)

            Text(node.title)
                .font(.system(.headline, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous).fill(Color.white.opacity(0.9))
                )
                .overlay(
                    Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        }
        .position(x: UIScreen.main.bounds.width/2 + node.xOffset + 18,
                  y: node.y)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }       // ⤴︎ trigger walking
    }
}

// MARK: - Walking Hero (dynamic)

private struct WalkingHero: View {
    let heroKey: String
    let progress: CGFloat
    let nodes: [AdventureNode]
    let mapHeight: CGFloat

    private var frames: [Image] {
        (1...6).compactMap { idx in
            let name = "\(heroKey)_walk_\(idx)"
            return UIImage(named: name) != nil ? Image(name) : nil
        }
    }

    @State private var frameIndex = 0
    @State private var timer: AnyCancellable?

    var body: some View {
        let pos = positionAlongPath(progress: progress, nodes: nodes)

        Group {
            if !frames.isEmpty {
                frames[frameIndex % frames.count]
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 6)
                    .onAppear { startTimer() }
                    .onDisappear { timer?.cancel() }
            } else {
                (UIImage(named: heroKey) != nil ? Image(heroKey) : Image("david"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 6)
            }
        }
        .position(pos)
    }

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.10, on: .main, in: .common)
            .autoconnect()
            .sink { _ in frameIndex = (frameIndex + 1) % max(frames.count, 1) }
    }
}

// MARK: - Path interpolation

private func positionAlongPath(progress: CGFloat, nodes: [AdventureNode]) -> CGPoint {
    guard nodes.count > 1 else {
        return CGPoint(x: UIScreen.main.bounds.width/2, y: nodes.first?.y ?? 0)
    }
    let p = progress.clamped(to: 0...1) * CGFloat(nodes.count - 1)
    let idx = Int(p)
    let frac = p - CGFloat(idx)

    let width = UIScreen.main.bounds.width
    let p1 = nodes[max(0, min(idx, nodes.count-1))]
    let p2 = nodes[max(0, min(idx+1, nodes.count-1))]

    let x1 = width/2 + p1.xOffset + 18
    let x2 = width/2 + p2.xOffset + 18
    let y = p1.y + (p2.y - p1.y) * frac
    let x = x1 + (x2 - x1) * frac
    return CGPoint(x: x, y: y)
}

// MARK: - Small UI helper

private struct ControlPill: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title).font(.system(.headline, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(hex:"#7CB7FF"), Color(hex:"#B36BFF")],
                                   startPoint: .leading, endPoint: .trailing)
                )
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.85), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 5)
    }
}

private struct PlayAdventurePill: View {
    var action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
                Text("Play Adventure")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex:"#2C7CF6"), Color(hex:"#1B6EF2")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.85), lineWidth: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.25))
                            .blur(radius: 2)
                    )
            )
            .shadow(color: .black.opacity(0.20), radius: 16, x: 0, y: 10)
            .scaleEffect(hover ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: hover)
        }
        .onAppear { hover = true }
    }
}

// MARK: - Handy clamp & utils

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Preview

#Preview {
    AdventureView()
}

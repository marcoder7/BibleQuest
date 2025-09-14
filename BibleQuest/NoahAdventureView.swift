import SwiftUI
import Combine
import FirebaseAuth
import FirebaseDatabase

struct NoahAdventureView: View {
    private let mapHeight: CGFloat = 2800

    // Noah’s 7 Quest stops
    private let nodes: [AdventureNode] = [
        .init(title: "God’s Call",        emoji: "🌟", y: 180,  xOffset: -60),
        .init(title: "Build the Ark",     emoji: "🪚", y: 520,  xOffset: 40),
        .init(title: "Gather Animals",    emoji: "🐘", y: 900,  xOffset: -80),
        .init(title: "Flood Begins",      emoji: "🌊", y: 1250, xOffset: 70),
        .init(title: "40 Days & Nights",  emoji: "☔️", y: 1600, xOffset: -60),
        .init(title: "The Dove Returns",  emoji: "🕊️", y: 1980, xOffset: 50),
        .init(title: "Rainbow Promise",   emoji: "🌈", y: 2380, xOffset: -30)
    ]

    // State
    @State private var isWalking = false
    @State private var progress: CGFloat = 0
    @State private var walkCancellable: AnyCancellable?
    @State private var currentAnchorY: CGFloat = 0

    @State private var userName: String = "Explorer"
    @State private var heroKey: String = "noah"
    @State private var goToFirstGame = false

    // Current stop
    private var currentNodeIndex: Int {
        let n = max(1, nodes.count - 1)
        let raw = (progress.clamped(to: 0...1) * CGFloat(n)).rounded()
        return Int(raw).clamped(to: 0...n)
    }

    // What happens when “Play Adventure” is tapped
    private func playAdventureTap() {
        if currentNodeIndex == 0 {
            goToFirstGame = true
        } else {
            toggleWalk()
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Hidden nav to first Noah game
                NavigationLink(
                    destination: Text("Noah Game 1 – God’s Call"), // Replace with actual game view
                    isActive: $goToFirstGame
                ) { EmptyView() }
                .hidden()

                // Background
                LinearGradient(colors: [Color(hex:"#E0F7FA"), Color(hex:"#E1F5FE")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack {
                            MapBackdrop(mapHeight: mapHeight)

                            AdventurePathShape(nodes: nodes)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex:"#00BCD4"),
                                                 Color(hex:"#4CAF50"),
                                                 Color(hex:"#8BC34A")],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

                            ForEach(Array(nodes.enumerated()), id: \.element.id) { (idx, node) in
                                LocationPin(node: node) {
                                    walkToNode(idx)
                                }
                            }

                            WalkingHero(heroKey: heroKey,
                                        progress: progress,
                                        nodes: nodes,
                                        mapHeight: mapHeight)
                                .onChange(of: progress) { _, newVal in
                                    let pos = positionAlongPath(progress: newVal, nodes: nodes)
                                    currentAnchorY = pos.y
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        proxy.scrollTo("anchor", anchor: UnitPoint(x: 0.5,
                                            y: min(0.5, (pos.y / mapHeight))))
                                    }
                                }

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
                        .foregroundStyle(Color(hex:"#00695C"))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                    Text("Follow the quest and tap locations for story hints.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color(hex:"#455A64"))

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
                PlayAdventurePill { playAdventureTap() }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 90)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadUserProfile)
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
                } else if let email = dict["email"] as? String {
                    self.userName = email.components(separatedBy: "@").first ?? "Explorer"
                }
                if let hero = (dict["Hero"] as? String)?.trimmed(), !hero.isEmpty {
                    self.heroKey = hero
                }
            }
    }

    // MARK: - Movement

    private func walkToNode(_ index: Int) {
        let n = max(1, nodes.count - 1)
        let target = CGFloat(index).clamped(to: 0...CGFloat(n)) / CGFloat(n)
        walk(to: target)
    }

    private func walk(to targetProgress: CGFloat) {
        let start = progress.clamped(to: 0...1)
        let target = targetProgress.clamped(to: 0...1)
        guard target != start else { return }

        isWalking = true
        walkCancellable?.cancel()

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

// MARK: - Preview
#Preview {
    NoahAdventureView()
}

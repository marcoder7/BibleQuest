import SwiftUI
import Combine
import FirebaseAuth
import FirebaseDatabase

struct DavidAdventureView: View {
    private let mapHeight: CGFloat = 2800

    // David’s 7 Quest stops
    private let nodes: [AdventureNode] = [
        .init(title: "Shepherd’s Field", emoji: "🐑", y: 180,  xOffset: -60),
        .init(title: "Stream of Stones",  emoji: "🪨", y: 520,  xOffset: 40),
        .init(title: "Camp of Israel",    emoji: "🏕️", y: 900,  xOffset: -80),
        .init(title: "Valley of Elah",    emoji: "🛡️", y: 1250, xOffset: 70),
        .init(title: "Face Goliath",      emoji: "📯", y: 1600, xOffset: -60),
        .init(title: "The Sling",         emoji: "🏹", y: 1980, xOffset: 50),
        .init(title: "Victory!",          emoji: "👑", y: 2380, xOffset: -30)
    ]

    // 🔑 Map node titles → Firebase keys
    private let nodeKeyMap: [String: String] = [
        "Shepherd’s Field": "ShepherdField",
        "Stream of Stones": "StreamOfStones",
        "Camp of Israel": "CampOfIsrael",
        "Valley of Elah": "ValleyOfElah",
        "Face Goliath": "FaceGoliath",
        "The Sling": "TheSling",
        "Victory!": "Victory"
    ]

    // Walking state
    @State private var isWalking = false
    @State private var progress: CGFloat = 0
    @State private var walkCancellable: AnyCancellable?
    @State private var currentAnchorY: CGFloat = 0

    // User profile
    @State private var userName: String = "Explorer"
    @State private var heroKey: String = "david"
    @State private var goToShepherdsField = false
    @State private var goToSlingGame = false
    @State private var goToArmorGame = false
    @State private var goToValleyOfElah = false
    
    
    // Game progress from Firebase
    @State private var completedGames: Set<String> = []

    // Alert state
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var currentNodeIndex: Int {
        let n = max(1, nodes.count - 1)
        let raw = (progress.clamped(to: 0...1) * CGFloat(n)).rounded()
        return Int(raw).clamped(to: 0...n)
    }

    private func playAdventureTap() {
        switch currentNodeIndex {
        case 0: goToShepherdsField = true
        case 1: goToSlingGame = true
        case 2: goToArmorGame = true
        case 3: goToValleyOfElah = true
        default:
            toggleWalk()
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Hidden nav to first game
                NavigationLink(
                    destination: ShepherdsFieldGame(onComplete: {
                        markGameCompleted("Shepherd’s Field") // use title → maps to Firebase
                    }),
                    isActive: $goToShepherdsField
                ) { EmptyView() }
                .hidden()
                
                NavigationLink(
                    destination: StreamOfStonesGame()
                        .onDisappear { markGameCompleted("Stream of Stones") },
                    isActive: $goToSlingGame
                ) { EmptyView() }
                .hidden()
                
                // Camp of Israel
                NavigationLink(
                    destination: ArmorGame(onComplete: {
                        markGameCompleted("Camp of Israel")
                    }),
                    isActive: $goToArmorGame
                ) { EmptyView() }
                .hidden()
                
                NavigationLink(
                    destination: ValleyOfElahGame(onComplete: {
                        markGameCompleted("Valley of Elah")
                    }),
                    isActive: $goToValleyOfElah
                ) { EmptyView() }.hidden()

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
                                        colors: [Color(hex:"#7CB7FF"),
                                                 Color(hex:"#B36BFF"),
                                                 Color(hex:"#6ED47A")],
                                        startPoint: .top, endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 14,
                                                       lineCap: .round,
                                                       lineJoin: .round)
                                )
                                .shadow(color: .black.opacity(0.1),
                                        radius: 6, x: 0, y: 3)

                            ForEach(Array(nodes.enumerated()), id: \.element.id) { (idx, node) in
                                LocationPin(node: node) {
                                  //  handleNodeTap(idx)
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
                                        proxy.scrollTo("anchor", anchor: UnitPoint(
                                            x: 0.5,
                                            y: min(0.5, (pos.y / mapHeight))
                                        ))
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
                        .foregroundStyle(Color(hex:"#1F6FE5"))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

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
                PlayAdventurePill { playAdventureTap() }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 90)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserProfile()
                loadCompletedGames()
            }
            .alert("Locked", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
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

    private func loadCompletedGames() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference()
            .child("Users")
            .child(uid)
            .child("Adventures")
            .child("David")
            .observeSingleEvent(of: .value) { snapshot in
                var completed: Set<String> = []
                for child in snapshot.children {
                    if let snap = child as? DataSnapshot,
                       let val = snap.value as? Bool, val {
                        completed.insert(snap.key)
                    }
                }
                self.completedGames = completed
                print("📡 loaded completedGames=\(completed)")
            }
    }

    private func markGameCompleted(_ nodeTitle: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let gameKey = nodeKeyMap[nodeTitle] else { return }

        Database.database().reference()
            .child("Users")
            .child(uid)
            .child("Adventures")
            .child("David")
            .child(gameKey)
            .setValue(true)
    }

    // MARK: - Node tap handler with full chain locking + debug
//    private func handleNodeTap(_ index: Int) {
//        let nodeTitle = nodes[index].title
//        print("👉 handleNodeTap index=\(index) nodeTitle=\(nodeTitle)")
//        walkToNode(index)   // 👈 always walk, no alert
//    }
    
    
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
        let duration = max(0.3, fullPathSeconds * distance)
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
        let n = max(1, nodes.count - 1)
        let raw = start.clamped(to: 0...1) * CGFloat(n)
        let nextIndex = min(n, Int(floor(raw)) + 1)

        // 🔒 Check prerequisites before walking
        let nextTitle = nodes[nextIndex].title
        guard let nextKey = nodeKeyMap[nextTitle] else { return }

        for prevIndex in 0..<nextIndex {
            let prevTitle = nodes[prevIndex].title
            guard let prevKey = nodeKeyMap[prevTitle] else { continue }

            if !completedGames.contains(prevKey) {
                alertMessage = "Please complete \"\(prevTitle)\" before moving to \"\(nextTitle)\"."
                showAlert = true
                print("   ❌ Blocked walk button: \(prevTitle) not completed")
                return
            }
        }

        // ✅ All prerequisites done, walk to nextIndex
        let target = CGFloat(nextIndex) / CGFloat(n)
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
    DavidAdventureView()
}

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseDatabase

struct DavidAdventureView: View {
    private let mapHeight: CGFloat = 2800

    // David’s 7 Quest stops
    private let nodes: [AdventureNode] = [
        .init(title: "Shepherd’s Field", emoji: "🐑", y: 180,  xOffset: -60),
        .init(title: "Roaring Beast",     emoji: "🦁", y: 520,  xOffset: 40),
        .init(title: "Stream of Stones",  emoji: "🪨", y: 900,  xOffset: -80),
        .init(title: "Camp of Israel",    emoji: "🏕️", y: 1250, xOffset: 70),
        .init(title: "Valley of Elah",    emoji: "🛡️", y: 1600, xOffset: -60),
        .init(title: "Face Goliath",      emoji: "📯", y: 1980, xOffset: 50),
        .init(title: "Victory!",          emoji: "👑", y: 2380, xOffset: -30)
    ]

    // 🔑 Map node titles → Firebase keys
    private let nodeKeyMap: [String: String] = [
        "Shepherd’s Field": "ShepherdField",
        "Roaring Beast": "RoaringBeast",
        "Stream of Stones": "StreamOfStones",
        "Camp of Israel": "CampOfIsrael",
        "Valley of Elah": "ValleyOfElah",
        "Face Goliath": "FaceGoliath",
        "Victory!": "Victory"
    ]

    // Walking state
    @State private var isWalking = false
    @State private var progress: CGFloat = 0
    @State private var walkCancellable: AnyCancellable?
    @State private var currentAnchorY: CGFloat = 0
    @State private var lastAutoScrollY: CGFloat = -1000
    @State private var hasLoadedAdventureState = false

    // User profile
    @State private var userName: String = "Explorer"
    @State private var heroKey: String = "david"
    @State private var goToShepherdsField = false
    @State private var goToRoaringBeast = false
    @State private var goToStreamOfStones = false
    @State private var goToArmorGame = false
    @State private var goToValleyOfElah = false
    @State private var goToFaceGoliath = false
    @State private var goToHeroAlbum = false
    
    
    // Game progress from Firebase
    @State private var completedGames: Set<String> = []

    // Alert state
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showTrophyUnlockPopup = false
    @State private var isClaimingTrophy = false

    private var currentNodeIndex: Int {
        let n = max(1, nodes.count - 1)
        let raw = (progress.clamped(to: 0...1) * CGFloat(n)).rounded()
        return Int(raw).clamped(to: 0...n)
    }

    private func playAdventureTap() {
        if currentNodeIndex == nodes.count - 1 {
            claimDavidTrophy()
            return
        }
        if !openGame(at: currentNodeIndex) {
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
                    destination: RoaringBeastGame(onComplete: {
                        markGameCompleted("Roaring Beast")
                    }),
                    isActive: $goToRoaringBeast
                ) { EmptyView() }
                .hidden()

                NavigationLink(
                    destination: StreamOfStonesGame(onComplete: {
                        markGameCompleted("Stream of Stones")
                    }),
                    isActive: $goToStreamOfStones
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

                NavigationLink(
                    destination: FaceGoliathGame(onComplete: {
                        markGameCompleted("Face Goliath")
                    }),
                    isActive: $goToFaceGoliath
                ) { EmptyView() }.hidden()

                NavigationLink(
                    destination: HeroAlbumView(focusedHeroName: "David"),
                    isActive: $goToHeroAlbum
                ) { EmptyView() }.hidden()

                // Background
                LinearGradient(colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
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
                                    handleNodeTap(idx)
                                }
                                .position(
                                    x: UIScreen.main.bounds.width / 2 + node.xOffset + 18,
                                    y: node.y
                                )
                            }

                            WalkingHero(heroKey: heroKey,
                                        progress: progress,
                                        nodes: nodes,
                                        mapHeight: mapHeight)

                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: currentAnchorY.clamped(to: 0...(mapHeight - 1)))

                                Color.clear
                                    .frame(height: 1)
                                    .id("anchor")

                                Spacer(minLength: 0)
                            }
                            .frame(height: mapHeight)
                        }
                        .frame(height: mapHeight)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 30)
                        .padding(.bottom, 140)
                    }
                    .scrollDisabled(isWalking)
                    .onAppear {
                        let pos = positionAlongPath(progress: progress, nodes: nodes)
                        currentAnchorY = pos.y
                        lastAutoScrollY = -1000
                        proxy.scrollTo("anchor", anchor: .center)
                    }
                    .onChange(of: progress) { _, newVal in
                        let pos = positionAlongPath(progress: newVal, nodes: nodes)
                        currentAnchorY = pos.y
                        autoScrollIfNeeded(proxy: proxy, to: pos.y)
                    }
                    .onChange(of: hasLoadedAdventureState) { _, loaded in
                        guard loaded else { return }
                        let pos = positionAlongPath(progress: progress, nodes: nodes)
                        currentAnchorY = pos.y
                        lastAutoScrollY = -1000
                        DispatchQueue.main.async {
                            var transaction = Transaction()
                            transaction.animation = .easeOut(duration: 0.22)
                            withTransaction(transaction) {
                                proxy.scrollTo("anchor", anchor: .center)
                            }
                        }
                    }
                }

                // Top UI
                VStack(spacing: 10) {
                    VStack(spacing: 6) {
                        Text("David's Adventure")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                        Text("Follow the quest and tap locations for story hints.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.bqCardSurface.opacity(0.72))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.bqCardBorder.opacity(0.5), lineWidth: 1)
                            )
                    )

                    Spacer()

                    HStack(spacing: 12) {
                        Button { jump(to: 0.0) } label: {
                            ControlPill(icon: "arrow.uturn.backward", title: "Restart")
                        }
                        Button { toggleWalk() } label: {
                            ControlPill(icon: isWalking ? "pause.fill" : "play.fill",
                                        title: isWalking ? "Pause" : "Walk")
                        }
                        Button { jumpToLatest() } label: {
                            ControlPill(icon: "clock.fill", title: "Latest")
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.top, 10)
                .padding(.horizontal, 16)
            }
            .overlay(alignment: .bottom) {
                PlayAdventurePill(
                    title: currentNodeIndex == nodes.count - 1
                        ? (isClaimingTrophy ? "Claiming..." : "Claim Trophy")
                        : "Play Adventure",
                    icon: currentNodeIndex == nodes.count - 1 ? "trophy.fill" : "play.fill"
                ) {
                    playAdventureTap()
                }
                    .disabled(isClaimingTrophy)
                    .opacity(isClaimingTrophy ? 0.8 : 1)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 90)
            }
            .overlay {
                if showTrophyUnlockPopup {
                    DavidTrophyUnlockOverlay {
                        showTrophyUnlockPopup = false
                        goToHeroAlbum = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            goToHeroAlbum = true
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserProfile()
                loadCompletedGames()
            }
            .onDisappear {
                saveAdventureProgress(progress)
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
                       isTruthyValue(snap.value) {
                        completed.insert(snap.key)
                    }
                }
                let savedProgressRaw = snapshot.childSnapshot(forPath: "Progress").value
                let savedProgress: CGFloat? = {
                    if let num = savedProgressRaw as? NSNumber {
                        return CGFloat(truncating: num).clamped(to: 0...1)
                    }
                    if let str = savedProgressRaw as? String, let dbl = Double(str) {
                        return CGFloat(dbl).clamped(to: 0...1)
                    }
                    return nil
                }()

                DispatchQueue.main.async {
                    self.completedGames = completed
                    if !hasLoadedAdventureState {
                        let unlockedProgress = latestAccessibleProgress(using: completed)
                        let restored: CGFloat
                        if let savedProgress {
                            restored = min(savedProgress, unlockedProgress)
                        } else {
                            restored = unlockedProgress
                        }
                        progress = restored.clamped(to: 0...1)
                        hasLoadedAdventureState = true
                        saveAdventureProgress(progress)
                    }
                    print("📡 loaded completedGames=\(completed), progress=\(progress)")
                }
            }
    }

    private func isTruthyValue(_ value: Any?) -> Bool {
        if let boolValue = value as? Bool {
            return boolValue
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            return string == "true" || string == "1" || string == "yes"
        }
        return false
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

        completedGames.insert(gameKey)
        saveAdventureProgress(progress)
    }

    private func claimDavidTrophy() {
        guard !isClaimingTrophy else { return }

        let victoryIndex = nodes.count - 1
        guard currentNodeIndex >= victoryIndex else {
            alertMessage = "Reach the Victory stop before claiming your trophy."
            showAlert = true
            return
        }

        if let missingTitle = firstMissingPrerequisite(before: victoryIndex) {
            alertMessage = "Please complete \"\(missingTitle)\" before claiming your trophy."
            showAlert = true
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else { return }
        isClaimingTrophy = true

        let updates: [String: Any] = [
            "Users/\(uid)/Adventures/David/Victory": true,
            "Users/\(uid)/HeroAlbumUnlocked/David": true
        ]

        Database.database().reference().updateChildValues(updates) { error, _ in
            DispatchQueue.main.async {
                isClaimingTrophy = false
                if let error {
                    alertMessage = "Could not claim trophy right now. \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                completedGames.insert("Victory")
                saveAdventureProgress(1)
                withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                    progress = 1
                    showTrophyUnlockPopup = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    // MARK: - Node taps
    private func handleNodeTap(_ index: Int) {
        guard nodes.indices.contains(index) else { return }

        if isWalking {
            isWalking = false
            walkCancellable?.cancel()
            saveAdventureProgress(progress)
        }

        let victoryIndex = nodes.count - 1
        if index == victoryIndex, index <= currentNodeIndex {
            claimDavidTrophy()
            return
        }

        // Completed games should always be replayable from the map.
        if isNodeCompleted(index), openGame(at: index) {
            return
        }

        // Replay any past/current playable game directly.
        if index <= currentNodeIndex {
            if openGame(at: index) { return }
            alertMessage = "\"\(nodes[index].title)\" game is not available yet."
            showAlert = true
            return
        }

        // Future node: walk only when prerequisites are complete.
        if let missingTitle = firstMissingPrerequisite(before: index) {
            alertMessage = "Please complete \"\(missingTitle)\" before moving to \"\(nodes[index].title)\"."
            showAlert = true
            return
        }

        walkToNode(index)
    }

    @discardableResult
    private func openGame(at index: Int) -> Bool {
        resetGameNavigationFlags()
        switch index {
        case 0:
            DispatchQueue.main.async { goToShepherdsField = true }
            return true
        case 1:
            DispatchQueue.main.async { goToRoaringBeast = true }
            return true
        case 2:
            DispatchQueue.main.async { goToStreamOfStones = true }
            return true
        case 3:
            DispatchQueue.main.async { goToArmorGame = true }
            return true
        case 4:
            DispatchQueue.main.async { goToValleyOfElah = true }
            return true
        case 5:
            DispatchQueue.main.async { goToFaceGoliath = true }
            return true
        default:
            return false
        }
    }

    private func resetGameNavigationFlags() {
        goToShepherdsField = false
        goToRoaringBeast = false
        goToStreamOfStones = false
        goToArmorGame = false
        goToValleyOfElah = false
        goToFaceGoliath = false
    }

    private func firstMissingPrerequisite(before index: Int) -> String? {
        guard index > 0 else { return nil }
        for prevIndex in 0..<index {
            let prevTitle = nodes[prevIndex].title
            guard let prevKey = nodeKeyMap[prevTitle] else { continue }
            if !completedGames.contains(prevKey) {
                return prevTitle
            }
        }
        return nil
    }

    private func isNodeCompleted(_ index: Int) -> Bool {
        guard nodes.indices.contains(index) else { return false }
        let title = nodes[index].title
        guard let key = nodeKeyMap[title] else { return false }
        return completedGames.contains(key)
    }

    private func latestAccessibleProgress(using completed: Set<String>? = nil) -> CGFloat {
        let completedSet = completed ?? completedGames
        let n = max(1, nodes.count - 1)
        var highestUnlockedIndex = 0

        for idx in 0...n {
            var canAccess = true
            if idx > 0 {
                for prevIndex in 0..<idx {
                    let prevTitle = nodes[prevIndex].title
                    guard let prevKey = nodeKeyMap[prevTitle] else { continue }
                    if !completedSet.contains(prevKey) {
                        canAccess = false
                        break
                    }
                }
            }
            if canAccess {
                highestUnlockedIndex = idx
            } else {
                break
            }
        }

        return CGFloat(highestUnlockedIndex) / CGFloat(n)
    }

    private func jumpToLatest() {
        let unlockedProgress = latestAccessibleProgress()
        jump(to: unlockedProgress.clamped(to: 0...1))
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
        lastAutoScrollY = -1000

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

                progress = value

                if clampedT >= 1.0 {
                    progress = target
                    walkCancellable?.cancel()
                    isWalking = false
                    saveAdventureProgress(progress)
                }
            }
    }

    private func toggleWalk() {
        if isWalking {
            isWalking = false
            walkCancellable?.cancel()
            saveAdventureProgress(progress)
            return
        }

        let start = progress
        let n = max(1, nodes.count - 1)
        let raw = start.clamped(to: 0...1) * CGFloat(n)
        let nextIndex = min(n, Int(floor(raw)) + 1)

        let nextTitle = nodes[nextIndex].title
        if let missingTitle = firstMissingPrerequisite(before: nextIndex) {
            alertMessage = "Please complete \"\(missingTitle)\" before moving to \"\(nextTitle)\"."
            showAlert = true
            print("   ❌ Blocked walk button: \(missingTitle) not completed")
            return
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
        lastAutoScrollY = -1000
        let target = value.clamped(to: 0...1)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            progress = target
        }
        isWalking = false
        saveAdventureProgress(target)
    }

    private func autoScrollIfNeeded(proxy: ScrollViewProxy, to positionY: CGFloat) {
        let threshold: CGFloat = isWalking ? 0 : 18
        let shouldScroll = abs(positionY - lastAutoScrollY) >= threshold
        guard shouldScroll else { return }

        lastAutoScrollY = positionY
        var transaction = Transaction()
        transaction.animation = isWalking ? nil : .easeOut(duration: 0.22)
        withTransaction(transaction) {
            proxy.scrollTo("anchor", anchor: .center)
        }
    }

    private func saveAdventureProgress(_ value: CGFloat) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let clamped = value.clamped(to: 0...1)
        Database.database().reference()
            .child("Users")
            .child(uid)
            .child("Adventures")
            .child("David")
            .child("Progress")
            .setValue(Double(clamped))
    }
}

// MARK: - Preview
#Preview {
    DavidAdventureView()
}

private struct DavidTrophyUnlockOverlay: View {
    var onClose: () -> Void

    @State private var revealed = false
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Trophy Unlocked!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFE08A"), Color(hex: "#FFB34D")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulsing ? 1.04 : 0.96)
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)

                    if revealed {
                        if UIImage(named: "rock") != nil {
                            Image("rock")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("🪨")
                                .font(.system(size: 56))
                                .transition(.scale.combined(with: .opacity))
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 52, weight: .black))
                            .foregroundStyle(.white)
                            .scaleEffect(0.9)
                            .rotationEffect(.degrees(-8))
                            .transition(.scale.combined(with: .opacity))
                    }

                    ForEach(0..<8, id: \.self) { idx in
                        Image(systemName: "sparkle")
                            .font(.system(size: idx.isMultiple(of: 2) ? 14 : 11, weight: .bold))
                            .foregroundStyle(.white.opacity(revealed ? 0.95 : 0.0))
                            .offset(y: -74)
                            .rotationEffect(.degrees(Double(idx) * 45))
                            .scaleEffect(pulsing ? 1.08 : 0.92)
                    }
                }

                if UIImage(named: "davidFull") != nil {
                    Image("davidFull")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 6)
                        .transition(.scale.combined(with: .opacity))
                } else if UIImage(named: "runningDavid") != nil {
                    Image("runningDavid")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 6)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("🪨")
                        .font(.system(size: 64))
                }

                Text("David’s trophy has been added to your Hero Album.")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button(action: onClose) {
                    Text("Awesome!")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#2C7CF6"), Color(hex: "#7A4AF8")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#4C88DE"), Color(hex: "#5E9DE8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                pulsing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                revealed = true
            }
        }
    }
}

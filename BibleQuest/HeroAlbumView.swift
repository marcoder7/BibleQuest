import SwiftUI
import FirebaseAuth
import FirebaseDatabase

// MARK: - Model

struct HeroCard: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let value: String
    let emoji: String
    var isUnlocked: Bool
}

// MARK: - Album

struct HeroAlbumView: View {
    var focusedHeroName: String? = nil
    @State private var heroes: [HeroCard] = Self.baseHeroes
    @State private var hasAutoScrolledToFocusedHero = false

    // Stats
    private var collectedCount: Int { heroes.filter { $0.isUnlocked }.count }
    private var totalCount: Int { heroes.count }

    // Layout
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    private static let baseHeroes: [HeroCard] = [
        .init(name: "David",  value: "Courage",        emoji: "🪨", isUnlocked: false),
        .init(name: "Noah",   value: "Obedience",      emoji: "🌊", isUnlocked: false),
        .init(name: "Jonah",  value: "Second Chances", emoji: "🐋", isUnlocked: false),
        .init(name: "Daniel", value: "Faithfulness",   emoji: "🦁", isUnlocked: false),
        .init(name: "Esther", value: "Bravery",        emoji: "👑", isUnlocked: false),
        .init(name: "Moses",  value: "Leadership",     emoji: "🔥", isUnlocked: false),
        .init(name: "Abraham",value: "Faith",          emoji: "⭐️", isUnlocked: false),
        .init(name: "Joseph", value: "Forgiveness",    emoji: "🎽", isUnlocked: false),
        .init(name: "Mary",   value: "Humility",       emoji: "🌹", isUnlocked: false),
        .init(name: "Joshua", value: "Boldness",       emoji: "⚔️", isUnlocked: false),
        .init(name: "Deborah",value: "Wisdom",         emoji: "🌿", isUnlocked: false),
        .init(name: "Ruth",   value: "Loyalty",        emoji: "🌾", isUnlocked: false),
        .init(name: "Elijah", value: "Prayer Power",   emoji: "🔥", isUnlocked: false),
        .init(name: "Elisha", value: "Miracles",       emoji: "💧", isUnlocked: false),
        .init(name: "Samuel", value: "Listening",      emoji: "📜", isUnlocked: false),
        .init(name: "Peter",  value: "Boldness",       emoji: "⛵️", isUnlocked: false),
        .init(name: "Paul",   value: "Perseverance",   emoji: "✍️", isUnlocked: false),
        .init(name: "Mary M.",value: "Faithfulness",   emoji: "🌸", isUnlocked: false),
        .init(name: "Solomon",value: "Wisdom",         emoji: "👑", isUnlocked: false),
        .init(name: "Jesus",  value: "Love",           emoji: "✨", isUnlocked: false),
    ]

    private let adventureHeroMap: [String: String] = [
        "David": "David",
        "Noah": "Noah",
        "Jonah": "Jonah",
        "Daniel": "Daniel",
        "Esther": "Esther",
        "Moses": "Moses",
        "Abraham": "Abraham",
        "Joseph": "Joseph",
        "Mary": "Mary",
        "Joshua": "Joshua",
        "Deborah": "Deborah",
        "Ruth": "Ruth",
        "Elijah": "Elijah",
        "Elisha": "Elisha",
        "Samuel": "Samuel",
        "Peter": "Peter",
        "Paul": "Paul",
        "MaryM": "Mary M.",
        "MaryMagdalene": "Mary M.",
        "Solomon": "Solomon",
        "Jesus": "Jesus"
    ]

    private let completionNodeByAdventure: [String: String] = [
        "David": "Victory",
        "Noah": "RainbowPromise",
        "Jonah": "Nineveh",
        "Daniel": "LionsDen",
        "Moses": "PromisedLand",
        "Jesus": "Resurrection"
    ]

    var body: some View {
        ZStack {
            BackgroundGradient()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        Header()

                        ProgressCard(collected: collectedCount, total: totalCount)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(heroes.indices, id: \.self) { i in
                                let hero = heroes[i]
                                let highlighted = hero.name == focusedHeroName

                                if hero.isUnlocked {
                                    // ✅ Unlocked → NavigationLink to detail
                                    NavigationLink {
                                        HeroDetailView(
                                            hero: toDetail(hero),
                                            collectedCount: collectedCount,
                                            totalCount: totalCount
                                        )
                                    } label: {
                                        HeroTileContent(hero: hero, locked: false, highlight: highlighted)
                                    }
                                    .id(hero.name)
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    .animation(.easeOut(duration: 0.35).delay(0.02 * Double(i)), value: heroes)

                                } else {
                                    // 🔒 Locked → NavigationLink to locked view
                                    NavigationLink {
                                        HeroLockedView(
                                            heroName: hero.name,
                                            description: "A mystery waiting to be revealed...",
                                            questName: "\(hero.name)’s Quest"
                                        )
                                    } label: {
                                        HeroTileContent(hero: hero, locked: true, highlight: highlighted)
                                    }
                                    .id(hero.name)
                                    .buttonStyle(.plain)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    .animation(.easeOut(duration: 0.35).delay(0.02 * Double(i)), value: heroes)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 4)

                        FooterCTA()
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                    }
                }
                .onAppear {
                    scrollToFocusedHeroIfNeeded(proxy, animated: false)
                }
                .onChange(of: heroes) { _, _ in
                    scrollToFocusedHeroIfNeeded(proxy)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear(perform: loadUnlockedHeroes)
    }

    // Map an album card → detail screen data
    private func toDetail(_ h: HeroCard) -> HeroDetail {
        switch h.name {
        case "David":
            return HeroDetail(
                name: "David",
                title: "Hero of Courage",
                value: "Courage",
                emoji: "🪨",
                verse: "Be strong and courageous.",
                verseRef: "Joshua 1:9",
                story: "A young shepherd boy who trusted God and defeated a giant with a sling and a stone. With faith, even the smallest person can do mighty things!"
            )
        case "Noah":
            return HeroDetail(
                name: "Noah",
                title: "Hero of Obedience",
                value: "Obedience",
                emoji: "🌊",
                verse: "Noah did all that God commanded him.",
                verseRef: "Genesis 6:22",
                story: "Noah trusted God and built the ark even when others laughed. Obedience kept his family—and the animals—safe through the flood."
            )
        case "Daniel":
            return HeroDetail(
                name: "Daniel",
                title: "Hero of Faithfulness",
                value: "Faithfulness",
                emoji: "🦁",
                verse: "My God sent his angel and shut the lions’ mouths.",
                verseRef: "Daniel 6:22",
                story: "Daniel prayed to God every day. Even in the lions’ den, he stayed faithful—and God protected him."
            )
        case "Moses":
            return HeroDetail(
                name: "Moses",
                title: "Hero of Leadership",
                value: "Leadership",
                emoji: "🔥",
                verse: "I will be with you.",
                verseRef: "Exodus 3:12",
                story: "God chose Moses to lead His people out of Egypt. With God’s help, Moses guided them through the Red Sea to freedom."
            )
        default:
            // Generic fallback for any other unlocked hero
            return HeroDetail(
                name: h.name,
                title: "Hero of \(h.value)",
                value: h.value,
                emoji: h.emoji,
                verse: "Let your light shine before others.",
                verseRef: "Matthew 5:16",
                story: "This hero shows us how to live out \(h.value.lowercased()) every day as we trust and follow God."
            )
        }
    }

    private func loadUnlockedHeroes() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference()
        let paths = [ref.child("Users").child(uid), ref.child(uid)]
        let group = DispatchGroup()
        let lock = NSLock()
        var unlocked: Set<String> = []

        for path in paths {
            group.enter()
            path.observeSingleEvent(of: .value, with: { snapshot in
                let found = unlockedHeroes(from: snapshot)
                lock.lock()
                unlocked.formUnion(found)
                lock.unlock()
                group.leave()
            }, withCancel: { _ in
                group.leave()
            })
        }

        group.notify(queue: .main) {
            heroes = heroes.map { hero in
                var updated = hero
                updated.isUnlocked = unlocked.contains(hero.name)
                return updated
            }
        }
    }

    private func unlockedHeroes(from snapshot: DataSnapshot) -> Set<String> {
        var unlocked: Set<String> = []

        for root in ["HeroAlbumUnlocked", "heroAlbumUnlocked"] {
            let explicit = snapshot.childSnapshot(forPath: root)
            for child in explicit.children {
                guard let snap = child as? DataSnapshot else { continue }
                if isTruthy(snap.value) {
                    unlocked.insert(heroName(forAdventureKey: snap.key) ?? snap.key)
                }
            }
        }

        for root in ["Adventure", "Adventures", "adventure", "adventures"] {
            let adventures = snapshot.childSnapshot(forPath: root)
            for child in adventures.children {
                guard let snap = child as? DataSnapshot else { continue }
                guard let heroName = heroName(forAdventureKey: snap.key) else { continue }
                if isAdventureCompleted(adventureKey: snap.key, snapshot: snap) {
                    unlocked.insert(heroName)
                }
            }
        }

        if isDavidUnlocked(in: snapshot) {
            unlocked.insert("David")
        }

        return unlocked
    }

    private func isAdventureCompleted(adventureKey: String, snapshot: DataSnapshot) -> Bool {
        if isTruthy(snapshot.value) {
            return true
        }

        let canonicalKey = heroName(forAdventureKey: adventureKey) ?? adventureKey
        if let explicitKey = completionNodeByAdventure[canonicalKey],
           isTruthy(snapshot.childSnapshot(forPath: explicitKey).value) {
            return true
        }

        if isTruthy(snapshot.childSnapshot(forPath: "Victory").value) {
            return true
        }
        if isTruthy(snapshot.childSnapshot(forPath: "victory").value) {
            return true
        }

        return false
    }

    private func isDavidUnlocked(in snapshot: DataSnapshot) -> Bool {
        let paths = [
            "Adventure/David/Victory",
            "Adventure/David/victory",
            "Adventure/david/Victory",
            "Adventure/david/victory",
            "adventure/David/Victory",
            "adventure/david/victory",
            "Adventures/David/Victory",
            "Adventures/David/victory",
            "Adventures/david/Victory",
            "Adventures/david/victory",
            "Adventures/DavidAdventure/Victory",
            "adventures/David/Victory",
            "adventures/david/victory",
            "HeroAlbumUnlocked/David",
            "heroAlbumUnlocked/David",
            "HeroAlbumUnlocked/david"
        ]
        for path in paths where isTruthy(snapshot.childSnapshot(forPath: path).value) {
            return true
        }
        return false
    }

    private func heroName(forAdventureKey key: String) -> String? {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if let mapped = adventureHeroMap[trimmedKey] {
            return mapped
        }
        if let mapped = adventureHeroMap.first(where: { $0.key.caseInsensitiveCompare(trimmedKey) == .orderedSame })?.value {
            return mapped
        }

        let normalized = trimmedKey.lowercased().filter { $0.isLetter || $0.isNumber }
        switch normalized {
        case "david", "davidadventure":
            return "David"
        case "noah":
            return "Noah"
        case "jonah":
            return "Jonah"
        case "daniel":
            return "Daniel"
        case "esther":
            return "Esther"
        case "moses":
            return "Moses"
        case "abraham":
            return "Abraham"
        case "joseph":
            return "Joseph"
        case "mary":
            return "Mary"
        case "joshua":
            return "Joshua"
        case "deborah":
            return "Deborah"
        case "ruth":
            return "Ruth"
        case "elijah":
            return "Elijah"
        case "elisha":
            return "Elisha"
        case "samuel":
            return "Samuel"
        case "peter":
            return "Peter"
        case "paul":
            return "Paul"
        case "marym", "marymagdalene":
            return "Mary M."
        case "solomon":
            return "Solomon"
        case "jesus":
            return "Jesus"
        default:
            return nil
        }
    }

    private func isTruthy(_ value: Any?) -> Bool {
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

    private func scrollToFocusedHeroIfNeeded(_ proxy: ScrollViewProxy, animated: Bool = true) {
        guard let focusedHeroName, !hasAutoScrolledToFocusedHero else { return }
        guard heroes.contains(where: { $0.name == focusedHeroName }) else { return }
        hasAutoScrolledToFocusedHero = true

        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(focusedHeroName, anchor: .center)
                }
            } else {
                proxy.scrollTo(focusedHeroName, anchor: .center)
            }
        }
    }
}

// MARK: - Background & Header

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay(DecorBubbles())
    }
}

private struct DecorBubbles: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.25)).frame(width: 140).offset(x: -130, y: 100)
            Circle().fill(Color.white.opacity(0.2)).frame(width: 120).offset(x: 150, y: -40)
            Circle().fill(Color.white.opacity(0.18)).frame(width: 130).offset(x: 120, y: 420)
        }
        .allowsHitTesting(false)
    }
}

private struct Header: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("My Hero\nAlbum")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "#2C7CF6"))
                .multilineTextAlignment(.center)

            Text("Collect them all, live their values! ⚡️")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(Color.bqSubtitle)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
        }
        .padding(.top, 8)
    }
}

// MARK: - Progress

private struct ProgressCard: View {
    let collected: Int
    let total: Int

    private var progress: Double { total == 0 ? 0 : Double(collected) / Double(total) }

    private let gradient = LinearGradient(
        colors: [Color(hex: "#7CB7FF"), Color(hex: "#B36BFF"), Color(hex: "#FFB661")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 12) {
            Text("Collection Progress")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("You've collected \(collected)/\(total) heroes!")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))

            ProgressBar(value: progress)
                .frame(height: 16)
                .padding(.horizontal, 12)

            HStack {
                Text("Start your journey")
                Spacer()
                Text("Master collector!")
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#F4F8FF"), Color(hex: "#C9D4E9"), Color(hex: "#FFFFFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .overlay {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let travel = w * 1.4
                let cycle: Double = 2.6

                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let phase = CGFloat((t.truncatingRemainder(dividingBy: cycle)) / cycle)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color(hex: "#F5FAFF").opacity(0.55),
                                    Color(hex: "#DDE5F8").opacity(0.28),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: w * 0.42, height: h * 1.6)
                        .rotationEffect(.degrees(18))
                        .offset(x: -travel + (travel * 2 * phase))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
        .padding(.horizontal, 16)
    }
}

private struct ProgressBar: View {
    let value: Double // 0...1
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: w, height: h)
                Capsule()
                    .fill(Color(hex: "#2C7CF6"))
                    .frame(width: max(8, w * value), height: h)
            }
        }
    }
}

// MARK: - Tile Content

private struct HeroTileContent: View {
    let hero: HeroCard
    let locked: Bool
    let highlight: Bool

    var body: some View {
        let corner: CGFloat = 22

        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(highlight ? Color(hex: "#FFB34D") : .clear, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)

            VStack(spacing: 8) {
                if !locked {
                    Text(hero.emoji).font(.system(size: 40))
                    Text(hero.name)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.bqTitle)
                    Text(hero.value)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color(hex: "#FF8A3C"))
                        Text("Collected!")
                            .foregroundStyle(Color(hex: "#FF8A3C"))
                            .font(.system(.footnote, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .padding(.top, 2)
                } else {
                    VStack(spacing: 6) {
                        Text(hero.emoji)
                            .font(.system(size: 36))
                            .opacity(0.5)
                            .saturation(0.0)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.8))

                        Text("???")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(.gray)

                        Text("Complete adventure")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                    .opacity(0.7)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)

            Circle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 80, height: 80)
                .offset(x: -40, y: 36)
                .allowsHitTesting(false)
        }
        .frame(height: 150)
    }
}

// MARK: - Footer CTA

private struct FooterCTA: View {
    private let gradient = LinearGradient(
        colors: [Color(hex: "#7CB7FF"), Color(hex: "#B36BFF"), Color(hex: "#6ED47A"), Color(hex: "#FFB661")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    var body: some View {
        VStack(spacing: 12) {
            Text("Keep Exploring! 🌟")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Each hero teaches us something special about following God. Complete their adventures to unlock their cards!")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)

            Button {
                // navigate to Adventures list
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "book")
                    Text("Explore More Adventures")
                        .fontWeight(.heavy)
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.85), lineWidth: 2)
                        .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.12)))
                )
            }
            .padding(.top, 6)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HeroAlbumView()
    }
}

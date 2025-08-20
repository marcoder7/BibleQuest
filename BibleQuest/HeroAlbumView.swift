import SwiftUI

// MARK: - Model

struct HeroCard: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let value: String
    let emoji: String
    let isUnlocked: Bool
}

// MARK: - Album

struct HeroAlbumView: View {
    // Demo data
    @State private var heroes: [HeroCard] = [
        .init(name: "David",  value: "Courage",        emoji: "🪨", isUnlocked: true),
        .init(name: "Noah",   value: "Obedience",      emoji: "🌊", isUnlocked: true),
        .init(name: "Jonah",  value: "Second Chances", emoji: "🐋", isUnlocked: false),
        .init(name: "Daniel", value: "Faithfulness",   emoji: "🦁", isUnlocked: true),
        .init(name: "Esther", value: "Bravery",        emoji: "👑", isUnlocked: false),
        .init(name: "Moses",  value: "Leadership",     emoji: "🔥", isUnlocked: true),
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

    // Stats
    private var collectedCount: Int { heroes.filter { $0.isUnlocked }.count }
    private let totalCount: Int = 20

    // Layout
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        ZStack {
            BackgroundGradient()

            ScrollView {
                VStack(spacing: 18) {
                    Header()

                    ProgressCard(collected: collectedCount, total: totalCount)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(heroes.indices, id: \.self) { i in
                            let hero = heroes[i]

                            if hero.isUnlocked {
                                // ✅ Unlocked → NavigationLink to detail
                                NavigationLink {
                                    HeroDetailView(
                                        hero: toDetail(hero),
                                        collectedCount: collectedCount,
                                        totalCount: totalCount
                                    )
                                } label: {
                                    HeroTileContent(hero: hero, locked: false)
                                }
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
                                    HeroTileContent(hero: hero, locked: true)
                                }
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
        }
        .navigationBarBackButtonHidden(false)
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
}

// MARK: - Background & Header

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "#CFEAFF"), Color(hex: "#E8F2FF")],
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
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "#2C7CF6"))
                Text("Back")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color(hex: "#2C7CF6"))
                Spacer()
            }
            .opacity(0.9)
            .padding(.horizontal, 16)

            Text("My Hero\nAlbum")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "#2C7CF6"))
                .multilineTextAlignment(.center)

            Text("Collect them all, live their values! ⚡️")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(Color(hex: "#6C7A99"))
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
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
        )
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
    @State private var pressed = false

    var body: some View {
        let corner: CGFloat = 22

        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)

            VStack(spacing: 8) {
                if !locked {
                    Text(hero.emoji).font(.system(size: 40))
                    Text(hero.name)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F6FE5"))
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
        .scaleEffect(pressed ? 0.97 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
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

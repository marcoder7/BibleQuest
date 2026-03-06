import SwiftUI

struct WisdomView: View {
    private let items: [WisdomCardItem] = [
        .init(
            title: "Ask God for Wisdom",
            verse: "If any of you lacks wisdom, let him ask of God.",
            reference: "James 1:5",
            icon: "🙏"
        ),
        .init(
            title: "Trust the Lord",
            verse: "Trust in Yahweh with all your heart, and don't lean on your own understanding.",
            reference: "Proverbs 3:5",
            icon: "💛"
        ),
        .init(
            title: "Guard Your Words",
            verse: "Whoever guards his mouth and his tongue keeps his soul from troubles.",
            reference: "Proverbs 21:23",
            icon: "🗣️"
        ),
        .init(
            title: "Choose Kindness",
            verse: "A gentle answer turns away wrath, but a harsh word stirs up anger.",
            reference: "Proverbs 15:1",
            icon: "🤝"
        ),
        .init(
            title: "Walk in Integrity",
            verse: "He who walks blamelessly walks surely.",
            reference: "Proverbs 10:9",
            icon: "🧭"
        ),
        .init(
            title: "Listen and Learn",
            verse: "A wise man will hear, and will increase in learning.",
            reference: "Proverbs 1:5",
            icon: "👂"
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Wisdom")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)

                        Text("Simple truth for everyday choices.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)
                    }
                    .padding(.top, 18)

                    ForEach(items) { item in
                        WisdomCard(item: item)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wisdom Games")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)

                        Text("Play and learn with Bible-themed alphabet, numbers, and words.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)

                        NavigationLink {
                            AlphabetWisdomGameView()
                        } label: {
                            WisdomGameCard(
                                title: "Alphabet of Faith",
                                subtitle: "Match letters with Bible words.",
                                icon: "🔤",
                                colors: [Color(hex: "#2C7CF6"), Color(hex: "#66A7FF")]
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            NumbersWisdomGameView()
                        } label: {
                            WisdomGameCard(
                                title: "Bible Numbers",
                                subtitle: "Count key moments from Scripture.",
                                icon: "🔢",
                                colors: [Color(hex: "#22A060"), Color(hex: "#54C989")]
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            WordBuilderWisdomGameView()
                        } label: {
                            WisdomGameCard(
                                title: "Word Builder",
                                subtitle: "Unscramble Bible words.",
                                icon: "🧩",
                                colors: [Color(hex: "#8C63E6"), Color(hex: "#B088FF")]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    Text("Keep this page close when you need direction.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Color.bqSubtitle)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WisdomGameCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 34))
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            }

            Spacer(minLength: 8)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.85), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
    }
}

private struct WisdomCard: View {
    let item: WisdomCardItem

    private let gradient = LinearGradient(
        colors: [Color(hex: "#7CB7FF"), Color(hex: "#B36BFF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(item.icon)
                    .font(.system(size: 28))

                Text(item.title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("\"\(item.verse)\"")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineSpacing(3)

            Text(item.reference)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
    }
}

private struct AlphabetWisdomGameView: View {
    var body: some View {
        BibleQuizGameView(
            title: "Alphabet of Faith",
            icon: "🔤",
            subtitle: "Pick the Bible word that starts with the shown letter.",
            questions: [
                .init(prompt: "Which word starts with A?", options: ["Ark", "Boat", "Stone"], correctAnswer: "Ark", explanation: "Noah built an ark."),
                .init(prompt: "Which word starts with B?", options: ["Bible", "Crown", "River"], correctAnswer: "Bible", explanation: "The Bible is God's Word."),
                .init(prompt: "Which word starts with C?", options: ["Faith", "Cross", "Lion"], correctAnswer: "Cross", explanation: "Jesus died on the cross."),
                .init(prompt: "Which word starts with D?", options: ["David", "Eden", "Moses"], correctAnswer: "David", explanation: "David trusted God against Goliath."),
                .init(prompt: "Which word starts with E?", options: ["Temple", "Eden", "Jonah"], correctAnswer: "Eden", explanation: "God planted the Garden of Eden."),
                .init(prompt: "Which word starts with F?", options: ["Faith", "Grace", "Angel"], correctAnswer: "Faith", explanation: "Faith means trusting God."),
                .init(prompt: "Which word starts with G?", options: ["Goliath", "Prophet", "Prayer"], correctAnswer: "Goliath", explanation: "Goliath was the giant David faced."),
                .init(prompt: "Which word starts with H?", options: ["Hope", "Story", "Stone"], correctAnswer: "Hope", explanation: "Our hope is in the Lord.")
            ]
        )
    }
}

private struct NumbersWisdomGameView: View {
    var body: some View {
        BibleQuizGameView(
            title: "Bible Numbers",
            icon: "🔢",
            subtitle: "Choose the right number from Bible stories.",
            questions: [
                .init(prompt: "How many days and nights did rain fall in Noah's flood?", options: ["7", "40", "100"], correctAnswer: "40", explanation: "Genesis says rain fell for 40 days and nights."),
                .init(prompt: "How many stones did David pick up before facing Goliath?", options: ["2", "5", "10"], correctAnswer: "5", explanation: "David took five smooth stones."),
                .init(prompt: "How many disciples did Jesus choose?", options: ["12", "7", "3"], correctAnswer: "12", explanation: "Jesus called 12 disciples."),
                .init(prompt: "How many days was Jonah in the big fish?", options: ["3", "12", "30"], correctAnswer: "3", explanation: "Jonah was inside three days and nights."),
                .init(prompt: "On which day did God rest after creation?", options: ["6th", "7th", "8th"], correctAnswer: "7th", explanation: "God rested on the seventh day."),
                .init(prompt: "How many loaves were used when Jesus fed the crowd in one miracle?", options: ["5", "12", "2"], correctAnswer: "5", explanation: "A boy brought five loaves and two fish."),
                .init(prompt: "How many fish did the boy bring in that same miracle?", options: ["2", "5", "7"], correctAnswer: "2", explanation: "The meal was five loaves and two fish."),
                .init(prompt: "How many commandments did God give Moses?", options: ["5", "8", "10"], correctAnswer: "10", explanation: "God gave the Ten Commandments.")
            ]
        )
    }
}

private struct WordBuilderWisdomGameView: View {
    var body: some View {
        BibleQuizGameView(
            title: "Word Builder",
            icon: "🧩",
            subtitle: "Unscramble each Bible word.",
            questions: [
                .init(prompt: "Unscramble: KRA", options: ["Ark", "Jar", "Car"], correctAnswer: "Ark", explanation: "Noah built the ark."),
                .init(prompt: "Unscramble: VLOE", options: ["Vole", "Love", "Lave"], correctAnswer: "Love", explanation: "God is love."),
                .init(prompt: "Unscramble: ASHFIT", options: ["Faiths", "Fiasth", "Faith"], correctAnswer: "Faith", explanation: "Faith trusts God's promises."),
                .init(prompt: "Unscramble: RPEAYR", options: ["Prayer", "Parery", "Ryrpea"], correctAnswer: "Prayer", explanation: "Prayer is talking with God."),
                .init(prompt: "Unscramble: SGNO", options: ["Nogs", "Song", "Snog"], correctAnswer: "Song", explanation: "Many Psalms are songs to God."),
                .init(prompt: "Unscramble: CEGAR", options: ["Grace", "Cager", "Ragec"], correctAnswer: "Grace", explanation: "Grace is God's undeserved kindness."),
                .init(prompt: "Unscramble: EPSHO", options: ["Spore", "Hope", "Shoep"], correctAnswer: "Hope", explanation: "Hope looks to God."),
                .init(prompt: "Unscramble: RYCEM", options: ["Mercy", "Cream", "Mecyr"], correctAnswer: "Mercy", explanation: "God is rich in mercy.")
            ]
        )
    }
}

private struct BibleQuizGameView: View {
    let title: String
    let icon: String
    let subtitle: String
    let questions: [BibleQuizQuestion]

    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var selectedAnswer: String?

    private var currentQuestion: BibleQuizQuestion {
        questions[currentIndex]
    }

    private var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    private var hasFinished: Bool {
        currentIndex >= questions.count
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(icon) \(title)")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.bqTitle)
                        Text(subtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)
                    }
                    .padding(.top, 16)

                    if hasFinished {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Great Job!")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.bqTitle)
                            Text("Your score: \(score) / \(questions.count)")
                                .font(.system(.title3, design: .rounded))
                                .foregroundStyle(Color.bqBody)

                            Button {
                                currentIndex = 0
                                score = 0
                                selectedAnswer = nil
                            } label: {
                                Text("Play Again")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color(hex: "#2C7CF6"))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.94))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                        )
                    } else {
                        Text("Question \(currentIndex + 1) of \(questions.count)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color.bqSubtitle)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(currentQuestion.prompt)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.bqTitle)

                            ForEach(currentQuestion.options, id: \.self) { option in
                                Button {
                                    handleSelect(option)
                                } label: {
                                    HStack {
                                        Text(option)
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundStyle(buttonTextColor(option))
                                        Spacer()
                                        if let selectedAnswer {
                                            if option == currentQuestion.correctAnswer {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color(hex: "#22A060"))
                                            } else if option == selectedAnswer {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.red.opacity(0.85))
                                            }
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(buttonBackgroundColor(option))
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedAnswer != nil)
                            }

                            if selectedAnswer != nil {
                                Text(currentQuestion.explanation)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Color.bqBody)
                                    .padding(.top, 2)

                                Button {
                                    nextQuestion()
                                } label: {
                                    Text(isLastQuestion ? "See Score" : "Next Question")
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(hex: "#2C7CF6"))
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.94))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                        )
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleSelect(_ option: String) {
        guard selectedAnswer == nil else { return }
        selectedAnswer = option
        if option == currentQuestion.correctAnswer {
            score += 1
        }
    }

    private func nextQuestion() {
        if isLastQuestion {
            currentIndex = questions.count
            selectedAnswer = nil
            return
        }
        currentIndex += 1
        selectedAnswer = nil
    }

    private func buttonBackgroundColor(_ option: String) -> Color {
        guard let selectedAnswer else { return Color(hex: "#EEF5FF") }
        if option == currentQuestion.correctAnswer {
            return Color(hex: "#DFF5E8")
        }
        if option == selectedAnswer {
            return Color(hex: "#FFE5E5")
        }
        return Color(hex: "#EEF5FF")
    }

    private func buttonTextColor(_ option: String) -> Color {
        guard let selectedAnswer else { return Color.bqTitle }
        if option == currentQuestion.correctAnswer {
            return Color(hex: "#1A7A47")
        }
        if option == selectedAnswer {
            return Color(hex: "#B42318")
        }
        return Color.bqTitle
    }
}

private struct BibleQuizQuestion: Hashable {
    let prompt: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
}

private struct WisdomCardItem: Identifiable {
    let id = UUID()
    let title: String
    let verse: String
    let reference: String
    let icon: String
}

#Preview {
    NavigationStack {
        WisdomView()
    }
}

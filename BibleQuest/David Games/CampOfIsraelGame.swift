import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import AVFoundation

struct CampOfIsraelGame: View {
    // MARK: - External
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)? = nil

    // MARK: - Game State
    @State private var showIntro = true
    @State private var showWin = false
    @State private var currentStep = 0                 // index in dialogues
    @State private var faithPoints = 0                 // fills the faith meter
    @State private var hasAnswered = false
    @State private var lastChoiceWasFaithful = false

    // simple SFX hooks (optional)
    private let sfx = HopeSFX()

    // MARK: - Content
    private let dialogues: [Dialogue] = [
        // Brothers
        Dialogue(
            character: .brother,
            line: "What are you doing here, David? You’re just here to watch the battle.",
            options: [
                .init(text: "Maybe you’re right… I should go home.", faithful: false, note: "Your brother stays doubtful."),
                .init(text: "I brought food—and I believe the Lord will help Israel!", faithful: true, note: "Your brother looks surprised.")
            ]
        ),
        // Soldier
        Dialogue(
            character: .soldier,
            line: "We’re too weak to fight Goliath… he’s too strong.",
            options: [
                .init(text: "You’re right… he is too strong.", faithful: false, note: "The soldier sighs and looks down."),
                .init(text: "The Lord is stronger than any man!", faithful: true, note: "The soldier stands a little taller.")
            ]
        ),
        // Saul’s attendant
        Dialogue(
            character: .attendant,
            line: "The King needs a mighty warrior. You’re just a shepherd boy.",
            options: [
                .init(text: "I guess I’m not ready.", faithful: false, note: "The attendant shakes his head."),
                .init(text: "The Lord who rescued me from the lion will rescue me again!", faithful: true, note: "The attendant looks hopeful.")
            ]
        ),
        // King Saul
        Dialogue(
            character: .saul,
            line: "If you truly wish to fight, take my armor so you’ll be safe.",
            options: [
                .init(text: "Armor will keep me safe. I’ll rely on that.", faithful: false, note: "The camp remains uneasy."),
                .init(text: "I cannot go with these—I trust the Lord!", faithful: true, note: "Saul nods slowly. Faith fills the camp.")
            ]
        )
    ]

    // MARK: - Layout
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background (use your art if available; fallback to gradient)
                if UIImage(named: "davidBackground") != nil {
                    Image("davidBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height + 40)
                        .clipped()
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    // Top Bar: custom back + title + faith meter
                    HStack(alignment: .center) {
                        Button {
                            sfx.tap()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Back")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color.black.opacity(0.25), in: Capsule())
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("Messenger of Hope")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)

                            // Faith Meter
                            FaithMeter(value: faithPoints, total: dialogues.count)
                                .frame(width: 180, height: 10)
                        }

                        Spacer()

                        // Spacer to balance back button
                        Color.clear.frame(width: 80, height: 1)
                    }
                    .padding(.top, geo.safeAreaInsets.top + 8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    Spacer()

                    // Dialogue Card
                    DialogueCard(
                        dialogue: dialogues[currentStep],
                        hasAnswered: hasAnswered,
                        lastChoiceWasFaithful: lastChoiceWasFaithful,
                        onChoose: { choice in
                            guard !hasAnswered else { return }
                            sfx.tap()
                            hasAnswered = true
                            lastChoiceWasFaithful = choice.faithful
                            if choice.faithful { faithPoints += 1 }
                            sfx.react(faithful: choice.faithful)
                        },
                        onContinue: {
                            sfx.tap()
                            advanceOrWin()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 24)
                }

                // START OVERLAY
                if showIntro {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    StartOverlay {
                        sfx.tap()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showIntro = false
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // WIN OVERLAY
                if showWin {
                    ZStack {
                        LinearGradient(
                            colors: [Color.bqBackgroundTop, Color(hex:"#FFB6B9")],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()

                        WellDoneView(
                            emoji: "🕊️",
                            message: "You brought hope to the Camp of Israel!",
                            verse: "“The LORD who rescued me from the paw of the lion and of the bear will rescue me from this Philistine.”",
                            reference: "1 Samuel 17:37",
                            seconds: 0,
                            onPlayAgain: resetGame,
                            onBack: { dismiss() }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    }
                    .transition(.opacity.combined(with: .scale))
                    .onAppear { onComplete?() }
                }
            }
        }
        // Hide the system nav bar; we supply our own back button
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Flow
    private func advanceOrWin() {
        if currentStep + 1 < dialogues.count {
            // go to next step
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                currentStep += 1
                hasAnswered = false
                lastChoiceWasFaithful = false
            }
        } else {
            // end → show success
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showWin = true
            }
        }
    }

    private func resetGame() {
        currentStep = 0
        faithPoints = 0
        hasAnswered = false
        lastChoiceWasFaithful = false
        showIntro = true
        showWin = false
    }
}

// MARK: - Models
struct Dialogue {
    let character: CampCharacter
    let line: String
    let options: [Choice]
}

struct Choice: Identifiable {
    let id = UUID()
    let text: String
    let faithful: Bool
    let note: String
}

enum CampCharacter {
    case brother, soldier, attendant, saul

    var title: String {
        switch self {
        case .brother: return "Brother"
        case .soldier: return "Soldier"
        case .attendant: return "Saul’s Attendant"
        case .saul: return "King Saul"
        }
    }
    var emoji: String {
        switch self {
        case .brother: return "👨‍🌾"
        case .soldier: return "🛡️"
        case .attendant: return "🤴🏻"
        case .saul: return "👑"
        }
    }
}

// MARK: - UI Pieces
private struct FaithMeter: View {
    let value: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.25))
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex:"#6ED47A"), Color.bqTitle],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geo.size.width * CGFloat(value) / CGFloat(max(total, 1))))
                    .animation(.easeInOut(duration: 0.35), value: value)
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            HStack {
                Spacer()
                Text("\(value)/\(total)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.trailing, 4)
            }
        )
    }
}

private struct DialogueCard: View {
    let dialogue: Dialogue
    let hasAnswered: Bool
    let lastChoiceWasFaithful: Bool
    var onChoose: (Choice) -> Void
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Character header
            HStack(spacing: 10) {
                Text(dialogue.character.emoji)
                    .font(.system(size: 32))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                Text(dialogue.character.title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Line
            Text("“\(dialogue.line)”")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Choices
            VStack(spacing: 10) {
                ForEach(dialogue.options) { opt in
                    Button {
                        onChoose(opt)
                    } label: {
                        HStack(spacing: 10) {
                            Text(opt.text)
                                .font(.system(.body, design: .rounded))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if hasAnswered {
                                Image(systemName: opt.faithful ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .opacity(0.001) // keep layout consistent; reveal only for selected?
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.16))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.35), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(hasAnswered) // lock once a choice is picked
                }
            }

            // Feedback + Continue
            if hasAnswered {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text(lastChoiceWasFaithful ? "✨ Faith grows!" : "😕 Not quite…")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                    }

                    Button(action: onContinue) {
                        HStack(spacing: 8) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(.headline, design: .rounded))
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(.white.opacity(0.22), in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 1.5))
                        .foregroundStyle(.white)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex:"#7CB7FF").opacity(0.8),
                                              Color(hex:"#B36BFF").opacity(0.8)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 10)
        )
    }
}

private struct StartOverlay: View {
    var onStart: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Text("🏕️ Camp of Israel\nMessenger of Hope")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Talk to the people in the camp and choose faith-filled answers to lift their courage!\nFill the Faith Meter to move on.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            Button(action: onStart) {
                Text("Begin")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .padding(.horizontal, 40).padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.pink, Color.orange],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 6)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color.blue, Color.purple],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 8)
        )
        .padding(.horizontal, 28)
    }
}

// MARK: - SFX
final class HopeSFX {
    private var player: AVAudioPlayer?

    func tap() {
        play(name: "ui_tap") // optional; add ui_tap.mp3 in bundle
    }
    func react(faithful: Bool) {
        play(name: faithful ? "sparkle" : "bonk") // optional sfx
    }
    private func play(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch { }
    }
}

// MARK: - Preview
#Preview {
    CampOfIsraelGame()
}

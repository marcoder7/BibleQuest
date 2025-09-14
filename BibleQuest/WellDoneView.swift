import SwiftUI

struct WellDoneView: View {
    let emoji: String
    let message: String
    let verse: String
    let reference: String
    let seconds: Int
    var onPlayAgain: () -> Void
    var onBack: () -> Void

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.56, green: 0.64, blue: 1.0),
                    Color(red: 1.0, green: 0.70, blue: 0.76),
                    Color(red: 1.0, green: 0.77, blue: 0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("✨ Well Done! ✨")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                Text(emoji)
                    .font(.system(size: 64))

                Text(message)
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 6) {
                    Text("Remember:")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("“\(verse)”")
                        .font(.system(.headline, design: .rounded))
                        .italic()
                        .foregroundStyle(.white)
                    Text("– \(reference)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding()
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))

                Text("Time: \(seconds)s")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))

                HStack(spacing: 24) {
                    Button(action: onPlayAgain) {
                        HStack { Image(systemName: "star.fill"); Text("Play Again") }
                            .font(.system(.headline, design: .rounded))
                            .padding(.horizontal, 24).padding(.vertical, 14)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.6), lineWidth: 2))
                            .foregroundStyle(.white)
                    }

                    Button(action: onBack) {
                        HStack { Image(systemName: "arrow.left"); Text("Adventures") }
                            .font(.system(.headline, design: .rounded))
                            .padding(.horizontal, 24).padding(.vertical, 14)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.6), lineWidth: 2))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
    }
}

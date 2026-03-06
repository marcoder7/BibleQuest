import SwiftUI

struct SelectQuestView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: Background gradient
                LinearGradient(
                    colors: [Color(hex: "#4B6CB7"), Color(hex: "#182848")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .overlay(
                    // Animated bubbles
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.35))
                            .frame(width: 280, height: 280)
                            .blur(radius: 40)
                            .offset(x: -120, y: -300)
                        Circle()
                            .fill(Color.blue.opacity(0.35))
                            .frame(width: 240, height: 240)
                            .blur(radius: 50)
                            .offset(x: 150, y: -280)
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 300, height: 300)
                            .blur(radius: 60)
                            .offset(x: 40, y: 280)
                    }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // MARK: Title
                        VStack(spacing: 8) {
                            Text("Choose Your")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Quest Hero")
                                .font(.system(size: 38, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex:"#FF7E5F"), Color(hex:"#FEB47B"), Color(hex:"#6A82FB")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Select your favorite Bible character and\nembark on an amazing adventure!")
                                .font(.system(.subheadline, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.top, 6)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)

                        // MARK: David’s Adventure
                        QuestCard(
                            title: "David's Adventures",
                            subtitle: "Join the brave shepherd boy on his heroic journeys",
                            image: "david", // ✅ Updated asset name
                            gradient: [Color(hex:"#FF9966"), Color(hex:"#FF5E62")],
                            destination: DavidAdventureView()
                        )

                        // MARK: Noah’s Adventure
                        QuestCard(
                            title: "Noah's Journey",
                            subtitle: "Help Noah build the ark and save the animals",
                            image: "noahAvatar", // ✅ Updated asset name
                            gradient: [Color(hex:"#36D1DC"), Color(hex:"#5B86E5")],
                            destination: NoahAdventureView()
                        )

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // 🔹 Removed custom Toolbar back button
        }
    }
}

// MARK: - Quest Card

private struct QuestCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let image: String
    let gradient: [Color]
    let destination: Destination

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 16) {
            // Character image
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Title
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)

                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            // Start button
            NavigationLink {
                destination
            } label: {
                HStack {
                    Text("Start Adventure")
                        .font(.system(.headline, design: .rounded))
                    Image(systemName: "sparkles")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .shadow(color: gradient.last!.opacity(0.4), radius: 10, x: 0, y: 6)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation { isPressed.toggle() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { isPressed.toggle() }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SelectQuestView()
}

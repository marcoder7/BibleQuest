// AdventureKit.swift
import SwiftUI
import Combine

// MARK: - Shared Models

struct AdventureNode: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let emoji: String
    let y: CGFloat
    let xOffset: CGFloat
}

// MARK: - Backdrop

struct MapBackdrop: View {
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

struct AdventurePathShape: Shape {
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

// MARK: - Marker Pin

struct LocationPin: View {
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
                .foregroundStyle(Color.bqInputText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous).fill(Color.bqCardSurfaceSoft.opacity(0.92))
                )
                .overlay(
                    Capsule().stroke(Color.bqCardBorder.opacity(0.5), lineWidth: 1)
                )
        }
        .frame(width: 170)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Walking Hero

struct WalkingHero: View {
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

func positionAlongPath(progress: CGFloat, nodes: [AdventureNode]) -> CGPoint {
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

// MARK: - ControlPill

struct ControlPill: View {
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

// MARK: - PlayAdventurePill

struct PlayAdventurePill: View {
    var title: String = "Play Adventure"
    var icon: String = "play.fill"
    var action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
                Text(title)
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

// MARK: - Handy Extensions

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

import SwiftUI
import UIKit

private extension UIColor {
    static func bqHex(_ hex: String) -> UIColor {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }

        return UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }

    static func bqDynamic(light: String, dark: String) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? bqHex(dark) : bqHex(light)
        }
    }
}

extension Color {
    static let bqBackgroundTop = Color(uiColor: .bqDynamic(light: "#CFEAFF", dark: "#0E1A2B"))
    static let bqBackgroundBottom = Color(uiColor: .bqDynamic(light: "#E8F2FF", dark: "#182C45"))

    static let bqTitle = Color(uiColor: .bqDynamic(light: "#1F6FE5", dark: "#8FB9FF"))
    static let bqSubtitle = Color(uiColor: .bqDynamic(light: "#6C7A99", dark: "#B9C8E2"))
    static let bqBody = Color(uiColor: .bqDynamic(light: "#4B5975", dark: "#DCE5F7"))

    static let bqCardSurface = Color(uiColor: .bqDynamic(light: "#FFFFFF", dark: "#22344F"))
    static let bqCardSurfaceSoft = Color(uiColor: .bqDynamic(light: "#F6F8FF", dark: "#2A3F5E"))
    static let bqCardBorder = Color(uiColor: .bqDynamic(light: "#FFFFFF", dark: "#A9BEE3"))

    static let bqInputText = Color(uiColor: .bqDynamic(light: "#2E3A51", dark: "#EFF4FF"))
    static let bqInputIcon = Color(uiColor: .bqDynamic(light: "#586A8A", dark: "#C6D5EF"))
    static let bqDivider = Color(uiColor: .bqDynamic(light: "#1E2A3E", dark: "#D8E3F8"))
}

enum BQTheme {
    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [Color.bqBackgroundTop, Color.bqBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

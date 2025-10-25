import Foundation

struct UserProfile {
    let uid: String
    let name: String
    let hero: String
    let email: String
    let photoURL: String

    var displayName: String {
        let trimmedName = name.trimmed()
        return trimmedName.isEmpty ? "Explorer" : trimmedName
    }

    var isComplete: Bool {
        !name.trimmed().isEmpty && !hero.trimmed().isEmpty
    }
}

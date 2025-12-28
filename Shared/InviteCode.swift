import Foundation

enum InviteCode {
    static let length = 6
    static let alphabet: [Character] = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    static let allowedCharacters = Set(alphabet)

    static func generate() -> String {
        String((0..<length).compactMap { _ in alphabet.randomElement() })
    }

    static func normalize(_ raw: String) -> String {
        let upper = raw.uppercased()
        let filtered = upper.filter { allowedCharacters.contains($0) }
        return String(filtered.prefix(length))
    }

    static func isValid(_ code: String) -> Bool {
        code.count == length && code.allSatisfy { allowedCharacters.contains($0) }
    }
}

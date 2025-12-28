import XCTest
@testable import DoodleGuess

final class InviteCodeTests: XCTestCase {
    func testGenerateInviteCodeUsesAllowedCharacters() {
        let allowed = InviteCode.allowedCharacters

        for _ in 0..<100 {
            let code = InviteCode.generate()
            XCTAssertEqual(code.count, InviteCode.length)
            XCTAssertTrue(code.allSatisfy { allowed.contains($0) })
        }
    }

    func testNormalizeInviteCodeUppercasesAndFilters() {
        let normalized = InviteCode.normalize("  ab c 234  ")
        XCTAssertEqual(normalized, "ABC234")
        XCTAssertTrue(InviteCode.isValid(normalized))

        let filtered = InviteCode.normalize("AB10OI")
        XCTAssertEqual(filtered, "AB")
        XCTAssertFalse(InviteCode.isValid(filtered))
    }
}

import Foundation

enum TurnAction: Equatable { case speak, demonstrate, listen, display }

struct PracticeEngine {
    let show: Show
    let sceneId: String
    let mode: PracticeMode
    var index: Int = 0
    var hintLevel = 0
    var demonstrated = false
    var usedDemonstration = false
    var sessionId = UUID().uuidString

    var lines: [ScriptUnit] { show.units(in: sceneId).filter { $0.type.isSpoken || (show.settings.speakStageDirections && $0.type == .stageDirection) } }
    var current: ScriptUnit? { lines.indices.contains(index) ? lines[index] : nil }
    var isChildTurn: Bool { current.map { show.childRoles.contains($0.characterId ?? "") && $0.type.isSpoken } ?? false }
    var finished: Bool { index >= lines.count }
    var action: TurnAction {
        guard let current else { return .display }
        if mode == .listen || !isChildTurn { return current.type.isSpoken || show.settings.speakStageDirections ? .speak : .display }
        if mode == .repeatLine && !demonstrated { return .demonstrate }
        return .listen
    }
    var hidesText: Bool { isChildTurn && (mode == .offBook || (mode == .practice && !show.settings.showPracticeText)) }
    var visibleText: String {
        guard let current else { return "" }
        guard hidesText && hintLevel < 3 else { return current.text }
        if hintLevel == 0 { return "Your turn" }
        let words = current.text.split(whereSeparator: \.isWhitespace)
        if words.count <= 1 {
            return String(current.text.prefix(hintLevel == 1 ? 1 : 3)) + "…"
        }
        return words.prefix(hintLevel == 1 ? 1 : 3).joined(separator: " ") + "…"
    }
    var lowPrompt: Bool { hidesText && hintLevel == 0 && !usedDemonstration && mode != .repeatLine }
    mutating func next() { index += 1; hintLevel = 0; demonstrated = false; usedDemonstration = false }
    mutating func previous() { index = max(0, index - 1); hintLevel = 0; demonstrated = false; usedDemonstration = false }
    mutating func hint() { hintLevel = min(3, hintLevel + 1) }
    mutating func didDemonstrate() { demonstrated = true; usedDemonstration = true }
}

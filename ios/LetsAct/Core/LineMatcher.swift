import Foundation

struct MatchResult: Equatable {
    var score: Double
    var success: Bool
    var feedback: String { success ? "Got it" : (score >= 0.5 ? "Almost" : "Let’s try again") }
}

enum LineMatcher {
    static func tokens(_ text: String) -> [String] {
        let normalized = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        var result: [String] = [], word = ""
        func flush() { if !word.isEmpty { result.append(word); word = "" } }
        for scalar in normalized.unicodeScalars {
            if (0x3400...0x9FFF).contains(scalar.value) { flush(); result.append(String(scalar)) }
            else if CharacterSet.alphanumerics.contains(scalar) { word.unicodeScalars.append(scalar) }
            else if scalar == "'" || scalar == "’" { continue }
            else { flush() }
        }
        flush()
        return result
    }
    static func compare(target: String, spoken: String, age: AgeBand) -> MatchResult {
        let expected = tokens(target), actual = tokens(spoken)
        guard !expected.isEmpty, !actual.isEmpty else { return MatchResult(score: 0, success: false) }
        // Bound microphone transcripts to avoid unbounded quadratic work.
        guard actual.count <= 1500, expected.count <= 1500 else { return MatchResult(score: 0, success: false) }
        var previous = Array(0...actual.count)
        for (i, token) in expected.enumerated() {
            var row = [i + 1] + Array(repeating: 0, count: actual.count)
            for (j, heard) in actual.enumerated() {
                row[j + 1] = min(row[j] + 1, previous[j + 1] + 1, previous[j] + (token == heard ? 0 : 1))
            }
            previous = row
        }
        let score = max(0, 1 - Double(previous[actual.count]) / Double(max(expected.count, actual.count)))
        // Short cues require exact words; semantic paraphrases never receive special credit.
        return MatchResult(score: score, success: score >= (expected.count <= 3 ? 1 : age.threshold))
    }
}

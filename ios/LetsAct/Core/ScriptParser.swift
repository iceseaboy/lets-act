import Foundation

enum LocalScriptParser {
    /// Conservative offline fallback. Ambiguous prose remains a direction for adult review.
    static func parse(text: String, title: String) -> Show {
        var show = Show(title: title, sourceText: text, scenes: [], characters: [], units: [])
        var scene = Scene(title: "Scene 1")
        var currentSpeaker: String?
        func castId(_ name: String) -> String {
            let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if let existing = show.characters.first(where: { $0.name.caseInsensitiveCompare(cleaned) == .orderedSame }) { return existing.id }
            let member = CastMember(name: cleaned, colorIndex: show.characters.count % 6)
            show.characters.append(member)
            return member.id
        }
        func append(_ type: UnitType, _ content: String, speaker: String? = nil) {
            if show.scenes.isEmpty { show.scenes.append(scene) }
            show.units.append(ScriptUnit(type: type, sceneId: scene.id, characterId: speaker, text: content, order: show.units.count))
        }
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            let upper = line.uppercased()
            if upper.range(of: "^(SCENE|ACT)\\s+[0-9IVX]+|^第.+[场幕]", options: .regularExpression) != nil {
                scene = Scene(title: line)
                show.scenes.append(scene)
                append(.sceneHeading, line)
                currentSpeaker = nil
            } else if upper.hasPrefix("SONG:") || line.hasPrefix("歌曲：") {
                append(.song, line); currentSpeaker = nil
            } else if line.hasPrefix("[") || line.hasPrefix("(") || line.hasPrefix("（") {
                append(.stageDirection, line)
            } else if let colon = line.firstIndex(where: { $0 == ":" || $0 == "：" }), line.distance(from: line.startIndex, to: colon) <= 48 {
                let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                let dialogue = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty && !dialogue.isEmpty {
                    currentSpeaker = castId(name)
                    append(line.contains("♪") ? .lyrics : .dialogue, dialogue, speaker: currentSpeaker)
                } else { append(.stageDirection, line) }
            } else if line == upper && line.count < 40 && line.rangeOfCharacter(from: .letters) != nil && !line.contains(where: { ".!?".contains($0) }) {
                currentSpeaker = castId(line)
            } else if let speaker = currentSpeaker {
                append(line.contains("♪") ? .lyrics : .dialogue, line, speaker: speaker)
            } else { append(.stageDirection, line) }
        }
        return show
    }
}

struct ParsedScript: Codable {
    struct ParsedCharacter: Codable { var id: String; var name: String }
    struct AliasSuggestion: Codable, Identifiable {
        var sourceId: String
        var targetId: String
        var reason: String
        var id: String { sourceId + ":" + targetId }
    }
    var scenes: [Scene]
    var characters: [ParsedCharacter]
    var units: [ScriptUnit]
    var aliases: [AliasSuggestion]

    func makeShow(title: String, originalText: String) throws -> Show {
        let show = Show(title: title, sourceText: originalText, scenes: scenes,
                        characters: characters.enumerated().map { CastMember(id: $0.element.id, name: $0.element.name, colorIndex: $0.offset % 6) },
                        units: units)
        guard show.validationErrors.isEmpty, units.count <= 3000,
              Set(units.map(\.order)).count == units.count,
              aliases.allSatisfy({ a in a.sourceId != a.targetId && characters.contains { $0.id == a.sourceId } && characters.contains { $0.id == a.targetId } }) else {
            throw ScriptError.invalidStructure
        }
        return show
    }
}

enum ScriptError: LocalizedError {
    case invalidStructure, emptyText, tooLarge, invalidEndpoint, serviceUnavailable
    var errorDescription: String? {
        switch self {
        case .invalidStructure: return "The script structure needs another review. Use local parsing or try again."
        case .emptyText: return "No readable text was found. Try a clearer photo or paste the text."
        case .tooLarge: return "Please import a shorter section (up to 30 PDF pages or 30,000 characters)."
        case .invalidEndpoint: return "Enter a secure HTTPS parsing service address."
        case .serviceUnavailable: return "The parsing service is unavailable. You can still use local parsing."
        }
    }
}

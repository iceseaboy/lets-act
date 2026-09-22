import Foundation

enum UnitType: String, Codable, CaseIterable, Identifiable {
    case sceneHeading = "scene_heading", dialogue, stageDirection = "stage_direction", song, lyrics
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sceneHeading: return "Scene heading"
        case .dialogue: return "Dialogue"
        case .stageDirection: return "Stage direction"
        case .song: return "Song"
        case .lyrics: return "Lyrics"
        }
    }
    var isSpoken: Bool { self == .dialogue || self == .lyrics }
}

struct CastMember: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var name: String
    var colorIndex: Int = 0
    var voiceIdentifier: String?
}

struct Scene: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var title: String
}

struct ScriptUnit: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var type: UnitType
    var sceneId: String
    var characterId: String?
    var text: String
    var order: Int
}

enum AgeBand: String, Codable, CaseIterable, Identifiable {
    case young = "3–6", middle = "7–10", older = "11–14"
    var id: String { rawValue }
    var threshold: Double {
        switch self { case .young: return 0.80; case .middle: return 0.88; case .older: return 0.94 }
    }
    var defaultMode: PracticeMode { self == .young ? .repeatLine : .practice }
}

enum PracticeMode: String, Codable, CaseIterable, Identifiable {
    case listen, read, repeatLine = "repeat", practice, offBook = "off_book"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .listen: return "Listen"
        case .read: return "Read"
        case .repeatLine: return "Repeat"
        case .practice: return "Practice"
        case .offBook: return "Off Book"
        }
    }
    var symbol: String {
        switch self {
        case .listen: return "headphones"
        case .read: return "text.book.closed"
        case .repeatLine: return "repeat"
        case .practice: return "theatermasks"
        case .offBook: return "sparkle"
        }
    }
    var subtitle: String {
        switch self {
        case .listen: return "Hear the whole scene"
        case .read: return "Your words, right here"
        case .repeatLine: return "Listen, then try it"
        case .practice: return "Meet your scene partner"
        case .offBook: return "Let your memory lead"
        }
    }
}

struct PracticeSettings: Codable, Equatable {
    var age: AgeBand = .middle
    var locale = "en-US"
    var speechRate: Double = 0.45
    var showPracticeText = true
    var speakStageDirections = false
    var soundEffects = false
    var masterySuccesses = 3
    var masterySessions = 2
}

enum LineState: String, Codable { case new = "New", learning = "Learning", remembered = "Remembered", mastered = "Mastered" }

struct Attempt: Codable, Equatable {
    var sessionId: String
    var date = Date()
    var score: Double
    var success: Bool
    var lowPrompt: Bool
}

struct LineProgress: Codable, Equatable {
    var attempts: [Attempt] = []
    func state(settings: PracticeSettings) -> LineState {
        let good = attempts.filter { $0.success && $0.lowPrompt }
        if good.count >= settings.masterySuccesses && Set(good.map(\.sessionId)).count >= settings.masterySessions { return .mastered }
        if !good.isEmpty { return .remembered }
        return attempts.isEmpty ? .new : .learning
    }
}

struct Show: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var title: String
    /// Original extracted text is never overwritten by parsing or structured edits.
    var sourceText: String
    var scenes: [Scene]
    var characters: [CastMember]
    var units: [ScriptUnit]
    var childRoles: [String] = []
    var reviewed = false
    var settings = PracticeSettings()
    var progress: [String: LineProgress] = [:]
    var lastSceneId: String?
    var lastUnitId: String?
    var completedSessions = 0
    var createdAt = Date()

    var assignedLines: [ScriptUnit] { units.filter { $0.type.isSpoken && childRoles.contains($0.characterId ?? "") } }
    var masteredCount: Int { assignedLines.filter { progress[$0.id]?.state(settings: settings) == .mastered }.count }
    var readyToPractice: Bool { reviewed && !assignedLines.isEmpty && validationErrors.isEmpty }
    func units(in sceneId: String) -> [ScriptUnit] { units.filter { $0.sceneId == sceneId }.sorted { $0.order < $1.order } }
    func character(_ id: String?) -> CastMember? { characters.first { $0.id == id } }
    func sceneState(_ sceneId: String) -> String {
        let lines = assignedLines.filter { $0.sceneId == sceneId }
        guard !lines.isEmpty else { return "Listen together" }
        if lines.allSatisfy({ progress[$0.id]?.state(settings: settings) == .mastered }) { return "Ready" }
        return lines.contains { progress[$0.id] != nil } ? "Practicing" : "Needs Practice"
    }
    var validationErrors: [String] {
        var errors: [String] = []
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.append("Add a show title.") }
        if scenes.isEmpty { errors.append("Add at least one scene.") }
        if !units.contains(where: { $0.type.isSpoken }) { errors.append("Add at least one line of dialogue or lyrics.") }
        let sceneIds = Set(scenes.map(\.id)), castIds = Set(characters.map(\.id))
        if sceneIds.count != scenes.count || castIds.count != characters.count || Set(units.map(\.id)).count != units.count { errors.append("Duplicate identifiers in script.") }
        if scenes.contains(where: { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { errors.append("Every scene needs a title.") }
        if characters.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { errors.append("Every character needs a name.") }
        if units.contains(where: { !sceneIds.contains($0.sceneId) }) { errors.append("Assign every line to an existing scene.") }
        if units.contains(where: { $0.type.isSpoken && !castIds.contains($0.characterId ?? "") }) { errors.append("Assign a speaker to every dialogue and lyric line.") }
        if units.contains(where: { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { errors.append("Remove or fill empty script lines.") }
        if !Set(childRoles).isSubset(of: castIds) { errors.append("Assigned roles must belong to the cast.") }
        return errors
    }

    /// Retain learning credit only while the learned words and role are unchanged.
    mutating func reconcileProgress(previous: Show?) {
        let validIds = Set(units.filter { line in
            guard let old = previous?.units.first(where: { $0.id == line.id }) else { return false }
            return line.type.isSpoken && old.text == line.text && old.characterId == line.characterId && old.type == line.type
        }.map(\.id))
        progress = progress.filter { validIds.contains($0.key) }
        if !scenes.contains(where: { $0.id == lastSceneId }) { lastSceneId = nil; lastUnitId = nil }
        if !units.contains(where: { $0.id == lastUnitId && $0.sceneId == lastSceneId }) { lastUnitId = nil }
    }

    mutating func mergeCharacter(_ source: String, into destination: String) {
        guard source != destination, characters.contains(where: { $0.id == destination }) else { return }
        for index in units.indices where units[index].characterId == source { units[index].characterId = destination }
        characters.removeAll { $0.id == source }
        if childRoles.contains(source) { childRoles.removeAll { $0 == source }; if !childRoles.contains(destination) { childRoles.append(destination) } }
        reviewed = false
    }
}

struct LibraryState: Codable {
    var schemaVersion = 1
    var shows: [Show] = []
    var activeShowId: String?
}

enum Demo {
    static let text = """
    SCENE 1: A light in the garden
    [The garden is quiet. A little star rests beside a flower.]
    LUNA: Hello, little star. How did you get here?
    STAR: I fell asleep and tumbled from the sky.
    LUNA: Then we will find your way home together.
    OWL: Every journey begins with one brave step.
    LUNA: I am ready. Will you come with me?
    STAR: Of course! Let us follow the moonlight.
    SCENE 2: The hill of wishes
    [They reach the top of a grassy hill.]
    OWL: Look up. Your friends are waiting.
    STAR: But the sky is so far away!
    LUNA: You are brighter than you think.
    SONG: A little light
    LUNA: ♪ One little light can show the way. ♪
    STAR: Thank you for believing in me.
    LUNA: Good night, little star. See you in the sky!
    """
    static func show() -> Show {
        var show = LocalScriptParser.parse(text: text, title: "The Little Star")
        show.childRoles = show.characters.filter { $0.name == "LUNA" }.map(\.id)
        show.reviewed = true
        return show
    }
}

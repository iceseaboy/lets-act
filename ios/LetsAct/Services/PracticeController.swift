import SwiftUI
import AudioToolbox

@MainActor
final class PracticeController: ObservableObject {
    @Published var engine: PracticeEngine
    @Published var running = false
    @Published var status = "Ready when you are"
    @Published var feedback: String?
    @Published var notice: String?
    @Published var awaitingNext = false
    let speaker = SpeechPlayer()
    let listener = SpeechListener()
    private var work: Task<Void, Never>?
    private var generation = UUID()
    private var didComplete = false
    private var scoredTurn = false
    private weak var store: ShowStore?

    init(show: Show, sceneId: String, mode: PracticeMode) {
        var engine = PracticeEngine(show: show, sceneId: sceneId, mode: mode)
        if show.lastSceneId == sceneId, let saved = show.lastUnitId, let index = engine.lines.firstIndex(where: { $0.id == saved }) { engine.index = index }
        self.engine = engine
    }
    func attach(_ store: ShowStore) { self.store = store }
    func toggle() { if running { pause() } else { play() } }
    func play() {
        guard !engine.finished else { return }
        running = true
        if engine.show.settings.soundEffects { AudioServicesPlaySystemSound(1104) }
        perform()
    }
    func pause() {
        generation = UUID(); work?.cancel(); work = nil
        speaker.stop(); listener.stop(); running = false
        if !engine.finished { status = "Take your time" }
    }
    func next() {
        pause(); engine.next(); scoredTurn = false; feedback = nil; awaitingNext = false; notice = nil
        if engine.finished { complete(); return }
        running = true; perform()
    }
    func previous() { pause(); engine.previous(); scoredTurn = false; feedback = nil; awaitingNext = false; notice = nil; running = true; perform() }
    func hint() { engine.hint() }
    func tryAgain() {
        pause(); scoredTurn = false; feedback = nil; awaitingNext = false; running = true
        perform()
    }
    func demonstrate() {
        guard let line = engine.current else { return }
        pause(); running = true; engine.usedDemonstration = true
        let token = generation
        status = "Listen to your line"
        do {
            try speaker.speak(line.text, character: engine.show.character(line.characterId), settings: engine.show.settings) { [weak self] in
                guard let self, self.generation == token else { return }
                self.engine.didDemonstrate(); self.perform()
            }
        } catch { notice = "Audio is unavailable. You can keep going with the text."; running = false }
    }
    private func perform() {
        guard running, let line = engine.current else { if engine.finished { complete() }; return }
        notice = nil; feedback = nil; awaitingNext = false
        store?.bookmark(showId: engine.show.id, sceneId: engine.sceneId, unitId: line.id)
        let token = generation
        switch engine.action {
        case .speak, .demonstrate:
            let demonstration = engine.action == .demonstrate
            status = demonstration ? "Listen, then it’s your turn" : "\(engine.show.character(line.characterId)?.name.capitalized ?? "The stage") is speaking"
            do {
                try speaker.speak(line.text, character: engine.show.character(line.characterId), settings: engine.show.settings) { [weak self] in
                    guard let self, self.generation == token, self.running else { return }
                    if demonstration { self.engine.didDemonstrate(); self.perform() } else { self.next() }
                }
            } catch { notice = "Audio is unavailable. Read the line and tap Next."; running = false }
        case .listen:
            status = "Your turn"
            work = Task { [weak self] in
                guard let self else { return }
                await self.listener.start(locale: self.engine.show.settings.locale) { [weak self] transcript, message in
                    guard let self, self.generation == token, self.running else { return }
                    self.notice = message
                    guard let transcript else { self.running = false; self.status = "Your turn"; return }
                    let result = LineMatcher.compare(target: line.text, spoken: transcript, age: self.engine.show.settings.age)
                    self.feedback = result.feedback
                    self.status = result.success ? "Nicely done" : "We can try that together"
                    // Never record a skipped/manual turn or a second result from one recognition task.
                    if !self.scoredTurn {
                        self.store?.record(showId: self.engine.show.id, unitId: line.id, attempt: Attempt(sessionId: self.engine.sessionId, score: result.score, success: result.success, lowPrompt: self.engine.lowPrompt))
                        self.scoredTurn = true
                    }
                    if result.success && self.engine.mode != .repeatLine {
                        self.work = Task { @MainActor in
                            do { try await Task.sleep(for: .seconds(1.0)) } catch { return }
                            guard self.generation == token else { return }
                            self.next()
                        }
                    } else { self.running = false; self.awaitingNext = true }
                }
            }
        case .display: running = false; status = "Take a moment"; awaitingNext = true
        }
    }
    private func complete() {
        pause(); status = "A lovely rehearsal."
        guard !didComplete else { return }
        didComplete = true
        store?.complete(showId: engine.show.id)
        if engine.show.settings.soundEffects { AudioServicesPlaySystemSound(1025) }
    }
}

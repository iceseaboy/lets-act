import SwiftUI

@MainActor
final class ShowStore: ObservableObject {
    @Published private(set) var state = LibraryState()
    @Published var error: String?
    private let file: URL
    private var loadFailed = false

    init() {
        // Test data uses a separate container; a UI test can never reset a user's shows.
        #if DEBUG
        let testing = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let preserveTestData = ProcessInfo.processInfo.arguments.contains("--preserve-ui-test-data")
        #else
        let testing = false
        let preserveTestData = false
        #endif
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent(testing ? "LetsAct-UITests" : "LetsAct", isDirectory: true)
        file = directory.appendingPathComponent("shows-v1.json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if testing && !preserveTestData && FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
            if FileManager.default.fileExists(atPath: file.path) {
                let loaded = try JSONDecoder().decode(LibraryState.self, from: Data(contentsOf: file))
                guard loaded.schemaVersion == 1 else { throw CocoaError(.fileReadCorruptFile) }
                state = loaded
            } else {
                let demo = Demo.show()
                state = LibraryState(shows: [demo], activeShowId: demo.id)
                persist()
            }
        } catch {
            loadFailed = true
            self.error = "Your saved shows could not be opened. The original file has been preserved. Close and reopen the app, or restore a device backup."
        }
    }
    var activeShow: Show? { state.shows.first { $0.id == state.activeShowId } ?? state.shows.first }
    func show(_ id: String) -> Show? { state.shows.first { $0.id == id } }
    func save(_ show: Show) {
        guard !loadFailed else { error = "Saving is unavailable while the existing library cannot be read. Your original file is preserved; restore it before making changes."; return }
        var show = show
        show.reconcileProgress(previous: self.show(show.id))
        if let index = state.shows.firstIndex(where: { $0.id == show.id }) { state.shows[index] = show }
        else { state.shows.append(show) }
        state.activeShowId = show.id
        persist()
    }
    func activate(_ id: String) { state.activeShowId = id; persist() }
    func delete(_ id: String) {
        state.shows.removeAll { $0.id == id }
        if state.activeShowId == id { state.activeShowId = state.shows.first?.id }
        persist()
    }
    func record(showId: String, unitId: String, attempt: Attempt) {
        guard let index = state.shows.firstIndex(where: { $0.id == showId }) else { return }
        var progress = state.shows[index].progress[unitId] ?? LineProgress()
        progress.attempts.append(attempt)
        state.shows[index].progress[unitId] = progress
        persist()
    }
    func bookmark(showId: String, sceneId: String, unitId: String?) {
        guard let index = state.shows.firstIndex(where: { $0.id == showId }) else { return }
        state.shows[index].lastSceneId = sceneId
        state.shows[index].lastUnitId = unitId
        persist()
    }
    func complete(showId: String) {
        guard let index = state.shows.firstIndex(where: { $0.id == showId }) else { return }
        state.shows[index].completedSessions += 1
        state.shows[index].lastUnitId = nil
        persist()
    }
    private func persist() {
        guard !loadFailed else { return }
        do { try JSONEncoder().encode(state).write(to: file, options: [.atomic, .completeFileProtection]) }
        catch { self.error = "We couldn’t save your latest changes. Please check the device’s available storage." }
    }
}

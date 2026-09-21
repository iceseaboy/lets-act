import XCTest
@testable import LetsActCore

final class CoreTests: XCTestCase {
    func testDemoHasMultipleScenesAndLyrics() {
        let show = Demo.show()
        XCTAssertEqual(show.scenes.count, 2)
        XCTAssertEqual(show.characters.count, 3)
        XCTAssertTrue(show.units.contains { $0.type == .lyrics })
        XCTAssertTrue(show.readyToPractice)
        XCTAssertEqual(show.sourceText, Demo.text)
    }
    func testCJKAndBlockSpeakerParsing() {
        let show = LocalScriptParser.parse(text: "第一场：花园\n小月：你好！\nSTAR\nHello there.\n[The star waves.]", title: "Garden")
        XCTAssertEqual(show.characters.map(\.name), ["小月", "STAR"])
        XCTAssertEqual(show.units.filter { $0.type == .dialogue }.count, 2)
        XCTAssertTrue(show.validationErrors.isEmpty)
        XCTAssertFalse(show.reviewed)
    }
    func testProseIsNotInventedDialogue() {
        let show = LocalScriptParser.parse(text: "A garden in the moonlight.", title: "Garden")
        XCTAssertTrue(show.characters.isEmpty)
        XCTAssertFalse(show.readyToPractice)
    }
    func testExactNotSemanticMatching() {
        XCTAssertTrue(LineMatcher.compare(target: "Get out of here!", spoken: "get out of here", age: .older).success)
        XCTAssertFalse(LineMatcher.compare(target: "Get out of here!", spoken: "Go away!", age: .young).success)
        XCTAssertFalse(LineMatcher.compare(target: "Come here", spoken: "Come", age: .young).success)
        XCTAssertFalse(LineMatcher.compare(target: "I can go", spoken: "I cannot go", age: .young).success)
        XCTAssertFalse(LineMatcher.compare(target: "", spoken: "", age: .young).success)
    }
    func testNormalizationAndWordOrder() {
        XCTAssertEqual(LineMatcher.tokens("DON’T stop, café!"), ["dont", "stop", "cafe"])
        XCTAssertTrue(LineMatcher.compare(target: "你好，小星星！", spoken: "你好小星星", age: .middle).success)
        XCTAssertFalse(LineMatcher.compare(target: "You follow me", spoken: "Me follow you", age: .young).success)
    }
    func testMasteryRequiresUnpromptedPracticeAcrossSessions() {
        let settings = PracticeSettings()
        var progress = LineProgress()
        XCTAssertEqual(progress.state(settings: settings), .new)
        progress.attempts.append(Attempt(sessionId: "a", score: 1, success: true, lowPrompt: false))
        XCTAssertEqual(progress.state(settings: settings), .learning)
        for _ in 0..<3 { progress.attempts.append(Attempt(sessionId: "a", score: 1, success: true, lowPrompt: true)) }
        XCTAssertEqual(progress.state(settings: settings), .remembered)
        progress.attempts.append(Attempt(sessionId: "b", score: 1, success: true, lowPrompt: true))
        XCTAssertEqual(progress.state(settings: settings), .mastered)
    }
    func testAllModesAndHintLadder() {
        let show = Demo.show(), scene = show.scenes[0].id
        XCTAssertEqual(PracticeEngine(show: show, sceneId: scene, mode: .listen).action, .speak)
        XCTAssertEqual(PracticeEngine(show: show, sceneId: scene, mode: .read).action, .listen)
        var repeating = PracticeEngine(show: show, sceneId: scene, mode: .repeatLine)
        XCTAssertEqual(repeating.action, .demonstrate)
        repeating.didDemonstrate()
        XCTAssertEqual(repeating.action, .listen)
        XCTAssertFalse(repeating.lowPrompt)
        var engine = PracticeEngine(show: show, sceneId: scene, mode: .offBook)
        XCTAssertEqual(engine.visibleText, "Your turn")
        XCTAssertTrue(engine.lowPrompt)
        engine.hint()
        XCTAssertEqual(engine.visibleText, "Hello,…")
        XCTAssertFalse(engine.lowPrompt)
        engine.hint()
        XCTAssertEqual(engine.visibleText, "Hello, little star.…")
        engine.hint()
        XCTAssertEqual(engine.visibleText, engine.current?.text)
        engine.next()
        XCTAssertEqual(engine.action, .speak)
        XCTAssertEqual(engine.hintLevel, 0)
    }
    func testMultipleChildRolesAndMerge() {
        var show = Demo.show()
        let star = show.characters.first { $0.name == "STAR" }!.id
        let luna = show.childRoles[0]
        show.childRoles.append(star)
        var engine = PracticeEngine(show: show, sceneId: show.scenes[0].id, mode: .practice)
        engine.next()
        XCTAssertTrue(engine.isChildTurn)
        show.mergeCharacter(star, into: luna)
        XCTAssertFalse(show.units.contains { $0.characterId == star })
        XCTAssertEqual(show.childRoles, [luna])
        XCTAssertFalse(show.reviewed)
    }
    func testInvalidReferencesAndPersistenceRoundTrip() throws {
        var show = Demo.show()
        let data = try JSONEncoder().encode(show)
        XCTAssertEqual(show, try JSONDecoder().decode(Show.self, from: data))
        show.units[1].sceneId = "missing"
        XCTAssertFalse(show.validationErrors.isEmpty)
        XCTAssertFalse(show.readyToPractice)
    }
    func testCompletionAndBoundaries() {
        let show = Demo.show()
        var engine = PracticeEngine(show: show, sceneId: show.scenes[0].id, mode: .practice)
        engine.previous()
        XCTAssertEqual(engine.index, 0)
        for _ in engine.lines { engine.next() }
        XCTAssertTrue(engine.finished)
        XCTAssertNil(engine.current)
    }
}

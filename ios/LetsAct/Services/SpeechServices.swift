import AVFoundation
import Speech
import SwiftUI

@MainActor
final class SpeechPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var wordRange: NSRange?
    @Published var speaking = false
    private let synthesizer = AVSpeechSynthesizer()
    private var current: AVSpeechUtterance?
    private var completion: (() -> Void)?

    override init() { super.init(); synthesizer.delegate = self }
    func speak(_ text: String, character: CastMember?, settings: PracticeSettings, completion: @escaping () -> Void) throws {
        stop()
        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.playback, mode: .spokenAudio)
        try audio.setActive(true)
        let utterance = AVSpeechUtterance(string: text)
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == settings.locale }
        if let identifier = character?.voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: identifier) { utterance.voice = voice }
        else if !voices.isEmpty { utterance.voice = voices[(character?.colorIndex ?? 0) % voices.count] }
        else { utterance.voice = AVSpeechSynthesisVoice(language: settings.locale) }
        utterance.rate = Float(settings.speechRate)
        // Distinct pitch is a fallback when only one system voice is installed.
        utterance.pitchMultiplier = [1.0, 0.88, 1.12, 0.95, 1.06, 0.82][(character?.colorIndex ?? 0) % 6]
        current = utterance; self.completion = completion; speaking = true
        synthesizer.speak(utterance)
    }
    func stop() {
        current = nil; completion = nil; speaking = false; wordRange = nil
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in guard self.current === utterance else { return }; self.wordRange = characterRange }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.current === utterance else { return }
            self.speaking = false; self.wordRange = nil; self.current = nil
            let callback = self.completion; self.completion = nil
            callback?()
        }
    }
}

@MainActor
final class SpeechListener: ObservableObject {
    @Published var listening = false
    @Published var transcript = ""
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var hasTap = false
    private var generation = UUID()
    private var completion: ((String?, String?) -> Void)?

    func start(locale: String, completion: @escaping (String?, String?) -> Void) async {
        stop()
        let token = generation
        let authorization = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard token == generation else { return }
        guard authorization == .authorized else { completion(nil, "Microphone practice is unavailable. You can still say your line and tap Next."); return }
        let allowed = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard token == generation else { return }
        guard allowed else { completion(nil, "Allow microphone access in Settings, or say your line and tap Next."); return }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            completion(nil, "On-device recognition isn’t available for this language. Say your line and tap Next. Your voice stays on this device."); return
        }
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.record, mode: .measurement)
            try audio.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            self.request = request; self.completion = completion; transcript = ""
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            hasTap = true
            engine.prepare(); try engine.start(); listening = true
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self, self.generation == token, self.listening else { return }
                    if let result {
                        let text = result.bestTranscription.formattedString
                        if text != self.transcript {
                            self.transcript = text
                            self.silenceTask?.cancel()
                            self.silenceTask = Task { @MainActor in
                                do { try await Task.sleep(for: .seconds(1.8)) } catch { return }
                                guard self.generation == token else { return }
                                self.finish()
                            }
                        }
                        if result.isFinal { self.finish(); return }
                    }
                    if error != nil { self.finish(message: self.transcript.isEmpty ? "Let’s try again, or tap Next to keep going." : nil) }
                }
            }
            timeoutTask = Task { @MainActor in
                do { try await Task.sleep(for: .seconds(45)) } catch { return }
                guard self.generation == token else { return }
                self.finish(message: self.transcript.isEmpty ? "Take your time. Tap the microphone to try again." : nil)
            }
        } catch {
            stop()
            completion(nil, "The microphone is busy. Try again, or say your line and tap Next.")
        }
    }
    func finish(message: String? = nil) {
        let text = transcript, callback = completion
        stop()
        callback?(text.isEmpty ? nil : text, message)
    }
    func stop() {
        generation = UUID(); listening = false
        silenceTask?.cancel(); timeoutTask?.cancel(); silenceTask = nil; timeoutTask = nil
        engine.stop()
        if hasTap { engine.inputNode.removeTap(onBus: 0); hasTap = false }
        request?.endAudio(); task?.cancel(); task = nil; request = nil; completion = nil
        transcript = ""
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

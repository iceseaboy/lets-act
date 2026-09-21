import SwiftUI
import AVFoundation

struct PracticeView: View {
    @EnvironmentObject private var store: ShowStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller: PracticeController

    init(show: Show, sceneId: String, mode: PracticeMode) {
        _controller = StateObject(wrappedValue: PracticeController(show: show, sceneId: sceneId, mode: mode))
    }
    var body: some View {
        VStack(spacing: 0) {
            header
            if controller.engine.finished { completed }
            else {
                ScrollView {
                    let layout = sizeClass == .regular ? AnyLayout(HStackLayout(alignment: .center, spacing: 32)) : AnyLayout(VStackLayout(spacing: 20))
                    layout {
                        if sizeClass == .regular { castPanel.frame(width: 190) }
                        dialogue.frame(maxWidth: .infinity, minHeight: sizeClass == .regular ? 440 : 340)
                    }.padding(sizeClass == .regular ? 36 : 20).frame(maxWidth: 1360).frame(maxWidth: .infinity)
                }
                controls
            }
        }
        .background(StageStyle.ivory).foregroundStyle(StageStyle.ink)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: controller.engine.index)
        .onAppear { controller.attach(store) }
        .onDisappear { controller.pause() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { controller.pause() } }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in controller.pause() }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { notification in
            if let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt, reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue { controller.pause() }
        }
    }
    private var header: some View {
        HStack(spacing: 16) {
            Button { controller.pause(); dismiss() } label: { Image(systemName: "xmark").frame(width: 56, height: 56).background(.white, in: Circle()) }.accessibilityLabel("End practice")
            VStack(alignment: .leading, spacing: 4) {
                Text(controller.engine.show.title).font(.system(.headline, design: .rounded))
                Text(controller.engine.show.scenes.first { $0.id == controller.engine.sceneId }?.title ?? "").font(.caption).foregroundStyle(StageStyle.muted)
            }
            Spacer()
            Label(controller.engine.mode.title, systemImage: controller.engine.mode.symbol).font(.system(.subheadline, design: .rounded)).padding(12).background(.white.opacity(0.8), in: Capsule())
        }.padding(.horizontal, sizeClass == .regular ? 36 : 20).padding(.top, 16)
    }
    private var castPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            Eyebrow(text: "On stage")
            ForEach(controller.engine.show.characters.filter { character in controller.engine.lines.contains { $0.characterId == character.id } }) { character in
                let active = controller.engine.current?.characterId == character.id
                HStack(spacing: 14) {
                    RoleAvatar(character: character, size: 52, active: active)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.name.capitalized).font(.system(.headline, design: .rounded))
                        Text(controller.engine.show.childRoles.contains(character.id) ? "You" : "Scene partner").font(.caption).foregroundStyle(StageStyle.muted)
                    }
                }.opacity(active ? 1 : 0.6)
            }
            Spacer(minLength: 16)
            Text("One line at a time.").font(.system(.subheadline, design: .rounded)).foregroundStyle(StageStyle.muted)
        }.padding(.vertical, 28)
    }
    private var dialogue: some View {
        VStack(spacing: 28) {
            HStack(spacing: 12) {
                if let member = controller.engine.show.character(controller.engine.current?.characterId) {
                    RoleAvatar(character: member, size: 42, active: controller.engine.isChildTurn)
                    Text(member.name.capitalized).font(.system(.title3, design: .rounded).weight(.semibold))
                }
                Spacer()
                Text("\(min(controller.engine.index + 1, controller.engine.lines.count)) / \(controller.engine.lines.count)").font(.caption.monospacedDigit()).foregroundStyle(StageStyle.muted).accessibilityLabel("Line \(controller.engine.index + 1) of \(controller.engine.lines.count)")
            }
            Spacer(minLength: 12)
            SpokenDialogue(text: controller.engine.visibleText, originalText: controller.engine.current?.text ?? "", speaker: controller.speaker, young: controller.engine.show.settings.age == .young)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer(minLength: 12)
            VStack(spacing: 12) {
                ListeningCue(listener: controller.listener, status: controller.status)
                if let feedback = controller.feedback { Label(feedback, systemImage: feedback == "Got it" ? "checkmark.circle" : "arrow.counterclockwise").font(.system(.headline, design: .rounded)) }
                if let notice = controller.notice { Text(notice).font(.footnote).foregroundStyle(StageStyle.muted).multilineTextAlignment(.center).accessibilityAddTraits(.updatesFrequently) }
            }
        }
        .padding(sizeClass == .regular ? 40 : 24)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(controller.engine.isChildTurn ? StageStyle.red.opacity(0.35) : .clear, lineWidth: 2))
    }
    private var controls: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(controller.engine.index), total: Double(max(1, controller.engine.lines.count))).tint(StageStyle.red).accessibilityLabel("Scene progress")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { secondaryControls; playButton; nextButton }
                VStack(spacing: 12) { HStack { playButton; nextButton }; secondaryControls }
            }
        }.padding(.horizontal, sizeClass == .regular ? 40 : 20).padding(.bottom, 24).padding(.top, 12)
    }
    private var secondaryControls: some View {
        HStack(spacing: 12) {
            Button { controller.previous() } label: { Image(systemName: "backward.end").frame(width: 56, height: 56) }.accessibilityLabel("Previous line").disabled(controller.engine.index == 0)
            Button { controller.demonstrate() } label: { Label("Repeat", systemImage: "repeat") }.buttonStyle(StageButtonStyle(primary: false))
            if controller.engine.isChildTurn && controller.engine.hidesText { Button { controller.hint() } label: { Label("Hint", systemImage: "lightbulb") }.buttonStyle(StageButtonStyle(primary: false)).disabled(controller.engine.hintLevel >= 3) }
        }
    }
    private var playButton: some View {
        Button {
            if controller.awaitingNext { controller.tryAgain() } else { controller.toggle() }
        } label: {
            Label(controller.running ? "Pause" : controller.awaitingNext ? "Try again" : "Let’s begin", systemImage: controller.running ? "pause.fill" : "play.fill").frame(minWidth: 100)
        }.buttonStyle(StageButtonStyle()).accessibilityIdentifier("player-play")
    }
    private var nextButton: some View {
        Button { controller.next() } label: { Label("Next", systemImage: "arrow.right") }.buttonStyle(StageButtonStyle(primary: false)).accessibilityHint("Continue without marking this line as remembered")
    }
    private var completed: some View {
        ScrollView {
            VStack(spacing: 24) {
                SpotlightArtwork().frame(width: 240, height: 240)
                Eyebrow(text: "Scene complete")
                Text("You showed up.\nYour part is growing.").font(.system(.largeTitle, design: .rounded).bold()).multilineTextAlignment(.center)
                Text("A little rest, then another moment in the spotlight.").foregroundStyle(StageStyle.muted).multilineTextAlignment(.center)
                Button("Back to my role") { dismiss() }.buttonStyle(StageButtonStyle())
            }.padding(32).frame(maxWidth: .infinity)
        }
    }
}

private struct ListeningCue: View {
    @ObservedObject var listener: SpeechListener
    let status: String
    var body: some View {
        Label(listener.listening ? (listener.transcript.isEmpty ? "Your turn · I’m listening" : "I can hear you") : status, systemImage: listener.listening ? "mic.fill" : "circle.dotted")
            .font(.system(.subheadline, design: .rounded).weight(.medium)).foregroundStyle(StageStyle.muted)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

private struct SpokenDialogue: View {
    let text: String
    let originalText: String
    @ObservedObject var speaker: SpeechPlayer
    let young: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var fontSize: CGFloat = 36
    var body: some View {
        rendered.font(.system(size: fontSize + (young ? 4 : 0), weight: .medium, design: .rounded))
            .lineSpacing(10).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
    }
    private var rendered: Text {
        guard text == originalText, let range = speaker.wordRange, range.location != NSNotFound, NSMaxRange(range) <= (text as NSString).length else { return Text(text).foregroundColor(StageStyle.ink) }
        let ns = text as NSString
        return Text(ns.substring(to: range.location)).foregroundColor(StageStyle.muted)
            + Text(ns.substring(with: range)).fontWeight(.bold).underline().foregroundColor(StageStyle.ink)
            + Text(ns.substring(from: NSMaxRange(range))).foregroundColor(StageStyle.ink)
    }
}

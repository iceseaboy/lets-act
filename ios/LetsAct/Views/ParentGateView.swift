import SwiftUI
import LocalAuthentication

struct ParentGateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    let onUnlock: () -> Void
    @State private var first = Int.random(in: 12...29)
    @State private var second = Int.random(in: 12...29)
    @State private var answer = ""
    @State private var message = ""
    @State private var busy = false
    @State private var context: LAContext?
    @State private var isVisible = true

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "lock.shield").font(.system(size: 44, weight: .light)).foregroundStyle(StageStyle.muted)
                Text("A moment for the grown-ups").font(.system(.title2, design: .rounded).bold()).multilineTextAlignment(.center)
                Text("Ask your parent or director to open this area.").foregroundStyle(StageStyle.muted).multilineTextAlignment(.center)
                Button("Unlock with this device", systemImage: "faceid") { authenticate() }.buttonStyle(StageButtonStyle()).disabled(busy)
                Text("Or solve this together").font(.subheadline).foregroundStyle(StageStyle.muted)
                Text("\(first) × \(second) = ?").font(.title2.monospacedDigit())
                TextField("Answer", text: $answer).keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(maxWidth: 180).accessibilityIdentifier("parent-answer")
                Button("Continue") { verifyAnswer() }.buttonStyle(StageButtonStyle(primary: false))
                Text(message).font(.footnote).foregroundStyle(StageStyle.muted)
            }
            .padding(32).frame(maxWidth: .infinity)
            }.background(StageStyle.ivory)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Unlock director area") { verifyAnswer() }
                }
            }
        }
        .onDisappear { isVisible = false; context?.invalidate() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                isVisible = false
                context?.invalidate()
                dismiss()
            }
        }
    }
    private func unlock() { guard isVisible else { return }; onUnlock(); dismiss() }
    private func verifyAnswer() {
        if Int(answer) == first * second { unlock() }
        else { message = "Please ask a grown-up to try again."; answer = ""; first = Int.random(in: 12...29); second = Int.random(in: 12...29) }
    }
    private func authenticate() {
        let context = LAContext(); self.context = context
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { message = "Device unlock is unavailable. Use the grown-up question below."; return }
        busy = true
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Open the parent and director area") { success, _ in
            Task { @MainActor in busy = false; if success { unlock() } }
        }
    }
}

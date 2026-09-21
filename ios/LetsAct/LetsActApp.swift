import SwiftUI

@main
struct LetsActApp: App {
    @StateObject private var store = ShowStore()
    var body: some SwiftUI.Scene {
        WindowGroup {
            ChildHomeView()
                .environmentObject(store)
                .tint(StageStyle.red)
                .preferredColorScheme(.light)
                .alert("A note about your shows", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("OK") { store.error = nil }
                } message: { Text(store.error ?? "") }
        }
    }
}

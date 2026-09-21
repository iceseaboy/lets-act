import SwiftUI

private struct PracticeRoute: Identifiable {
    let id = UUID()
    let show: Show
    let sceneId: String
    let mode: PracticeMode
}

struct ChildHomeView: View {
    @EnvironmentObject private var store: ShowStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var parentGate = false
    @State private var director = false
    @State private var unlocked = false
    @State private var route: PracticeRoute?
    @State private var selectedScene: String?
    @State private var progress = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "theatermasks.fill").foregroundStyle(StageStyle.red)
                            Text("let’s act").font(.system(.title2, design: .rounded).bold())
                        }
                        Spacer()
                        Button { parentGate = true } label: { Image(systemName: "lock").frame(width: 52, height: 52) }.foregroundStyle(StageStyle.muted).accessibilityLabel("Parent and director area")
                    }
                    if let show = store.activeShow, show.readyToPractice {
                        roleHome(show)
                    } else {
                        VStack(spacing: 24) {
                            SpotlightArtwork().frame(width: 260, height: 260)
                            Text("Every story needs you.").font(.system(.largeTitle, design: .rounded).bold())
                            Text("Ask a grown-up to add a show and choose your part.").foregroundStyle(StageStyle.muted)
                            Button("Set the stage") { parentGate = true }.buttonStyle(StageButtonStyle())
                        }.frame(maxWidth: .infinity).padding(.vertical, 40)
                    }
                }.padding(sizeClass == .regular ? 44 : 24).frame(maxWidth: 1200)
                .frame(maxWidth: .infinity)
            }.background(StageStyle.ivory).foregroundStyle(StageStyle.ink)
                .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $parentGate, onDismiss: { if unlocked { unlocked = false; director = true } }) { ParentGateView { unlocked = true } }
        .fullScreenCover(isPresented: $director) { DirectorHomeView() }
        .fullScreenCover(item: $route) { route in PracticeView(show: route.show, sceneId: route.sceneId, mode: route.mode) }
        .sheet(isPresented: $progress) { if let show = store.activeShow { NavigationStack { ProgressScreen(show: show) } } }
    }

    @ViewBuilder private func roleHome(_ show: Show) -> some View {
        let scene = show.scenes.first { $0.id == selectedScene } ?? show.scenes.first { $0.id == show.lastSceneId } ?? show.scenes.first!
        let roles = show.characters.filter { show.childRoles.contains($0.id) }
        let layout = sizeClass == .regular ? AnyLayout(HStackLayout(spacing: 24)) : AnyLayout(VStackLayout(spacing: 16))
        layout {
            VStack(alignment: .leading, spacing: 18) {
                Eyebrow(text: show.title)
                Text("The stage is yours.").font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("You are playing").foregroundStyle(StageStyle.muted)
                HStack(spacing: 12) {
                    ForEach(roles.prefix(3)) { RoleAvatar(character: $0, size: 60, active: true) }
                    Text(roles.map { $0.name.capitalized }.joined(separator: " & ")).font(.system(.title, design: .rounded).weight(.semibold))
                }
                Text("A little practice. A little more courage.").font(.system(.body, design: .rounded)).foregroundStyle(StageStyle.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            SpotlightArtwork().frame(width: sizeClass == .regular ? 280 : 180, height: sizeClass == .regular ? 260 : 130)
        }.padding(sizeClass == .regular ? 36 : 24).background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 28))

        StageCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Your next rehearsal")
                        Text(scene.title).font(.system(.title2, design: .rounded).bold())
                        let total = show.assignedLines.filter { $0.sceneId == scene.id }.count
                        Text("\(total) of your lines · \(show.sceneState(scene.id))").font(.subheadline).foregroundStyle(StageStyle.muted)
                    }
                    Spacer()
                    if show.scenes.count > 1 {
                        Menu { ForEach(show.scenes) { scene in Button(scene.title) { selectedScene = scene.id } } } label: { Image(systemName: "list.bullet").frame(width: 52, height: 52) }.accessibilityLabel("Choose a scene")
                    }
                }
                Button { open(show, scene.id, show.settings.age.defaultMode) } label: { Label("Continue Practice", systemImage: "play.fill").frame(maxWidth: .infinity) }.buttonStyle(StageButtonStyle()).accessibilityIdentifier("continue-practice")
            }
        }
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(text: "Find your rhythm")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: sizeClass == .regular ? 170 : 140), spacing: 12)], spacing: 12) {
                ForEach(PracticeMode.allCases) { mode in
                    Button { open(show, scene.id, mode) } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: mode.symbol).font(.title2).foregroundStyle(mode == .practice ? StageStyle.red : StageStyle.muted)
                            Text(mode.title).font(.system(.headline, design: .rounded))
                            Text(mode.subtitle).font(.caption).foregroundStyle(StageStyle.muted).multilineTextAlignment(.leading)
                        }.frame(maxWidth: .infinity, minHeight: 116, alignment: .leading).padding(20).background(.white, in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain).accessibilityIdentifier("mode-\(mode.rawValue)")
                }
            }
        }
        Button { progress = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "leaf").font(.title2).foregroundStyle(StageStyle.muted)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your part is growing").font(.system(.headline, design: .rounded))
                    Text("\(show.masteredCount) of \(show.assignedLines.count) lines mastered").font(.subheadline).foregroundStyle(StageStyle.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(StageStyle.muted)
            }.padding(22)
        }.buttonStyle(.plain)
    }
    private func open(_ show: Show, _ sceneId: String, _ mode: PracticeMode) { route = PracticeRoute(show: show, sceneId: sceneId, mode: mode) }
}

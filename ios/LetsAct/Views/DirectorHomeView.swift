import SwiftUI

struct DirectorHomeView: View {
    @EnvironmentObject private var store: ShowStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: String?
    @State private var importing = false
    @State private var settings = false
    @State private var deleting: Show?
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            List(selection: $selection) {
                Section("Your shows") {
                    ForEach(store.state.shows) { show in
                        NavigationLink(value: show.id) {
                          VStack(alignment: .leading, spacing: 6) {
                            Text(show.title).font(.headline)
                            Text("\(show.scenes.count) scenes · \(show.readyToPractice ? "Ready" : "Needs review")").font(.caption).foregroundStyle(.secondary)
                          }.padding(.vertical, 8)
                        }.tag(show.id).accessibilityIdentifier("show-\(show.title)")
                    }
                }
                Button("Create a show", systemImage: "plus") { importing = true }.frame(minHeight: 48)
                Button("Private parsing service", systemImage: "network") { settings = true }.frame(minHeight: 48)
            }
            .navigationTitle("Director’s chair")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Child mode", systemImage: "arrow.left") { dismiss() } } }
            .scrollContentBackground(.hidden).background(StageStyle.ivory)
        } detail: {
            if let show = store.show(selection ?? store.activeShow?.id ?? "") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Eyebrow(text: "Make room for their next big moment")
                        Text(show.title).font(.largeTitle.bold())
                        HStack { Label("\(show.scenes.count) scenes", systemImage: "rectangle.stack"); Label("\(show.characters.count) characters", systemImage: "person.2") }.foregroundStyle(StageStyle.muted)
                        if !show.reviewed { Label("Review the script before handing it to your child.", systemImage: "doc.text.magnifyingglass").foregroundStyle(StageStyle.muted) }
                        NavigationLink { ShowEditorView(show: show) } label: { Label("Review script & roles", systemImage: "pencil.line").frame(maxWidth: .infinity) }.buttonStyle(StageButtonStyle())
                        NavigationLink { PracticeSettingsView(show: show) } label: { Label("Practice settings", systemImage: "slider.horizontal.3").frame(maxWidth: .infinity) }.buttonStyle(StageButtonStyle(primary: false))
                        NavigationLink { ProgressScreen(show: show, embedded: true) } label: { Label("Learning progress", systemImage: "chart.bar").frame(maxWidth: .infinity) }.buttonStyle(StageButtonStyle(primary: false))
                        StageCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Their cast").font(.title2.bold())
                                ForEach(show.characters) { member in
                                    HStack {
                                        RoleAvatar(character: member, size: 44)
                                        VStack(alignment: .leading) {
                                            Text(member.name).font(.headline)
                                            let lines = show.units.filter { $0.characterId == member.id && $0.type.isSpoken }
                                            Text("\(lines.count) lines · \(Set(lines.map(\.sceneId)).count) scenes").font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if show.childRoles.contains(member.id) { Label("My role", systemImage: "checkmark.circle.fill").foregroundStyle(StageStyle.red).font(.caption) }
                                    }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button("Open this show in child mode", systemImage: "play.fill") { store.activate(show.id); dismiss() }.buttonStyle(StageButtonStyle()).disabled(!show.readyToPractice)
                        Button("Delete show", role: .destructive) { deleting = show }.padding(.top, 20)
                    }.padding(32).frame(maxWidth: 850).frame(maxWidth: .infinity)
                }.background(StageStyle.ivory)
            } else {
                ContentUnavailableView { Label("Set the stage", systemImage: "theatermasks") } description: { Text("Bring a script to life. Add your first show.") } actions: { Button("Create a show") { importing = true }.buttonStyle(StageButtonStyle()) }
            }
        }
        .sheet(isPresented: $importing) { ImportShowView { show in store.save(show); selection = show.id; compactColumn = .detail } }
        .sheet(isPresented: $settings) { ParserSettingsView() }
        .confirmationDialog("Delete this show and its progress from this device?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Delete show", role: .destructive) { if let show = deleting { store.delete(show.id); selection = nil }; deleting = nil }
        }
        .onChange(of: scenePhase) { _, phase in if phase == .background { dismiss() } }
    }
}

struct ParserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("parserEndpoint") private var endpoint = ""
    @State private var token = ""
    @State private var draftEndpoint = ""
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Optional script understanding") {
                    Text("Local import and practice work without a service. To use AI script understanding, connect your private parsing service. You will confirm each upload before any script text leaves this device.")
                    TextField("HTTPS service URL", text: $draftEndpoint).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    SecureField("Service access token", text: $token).textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                Section {
                    Text("Only script text is sent. Microphone audio is never sent to this service. Your provider’s retention policy applies to uploaded scripts. The service token is stored in the device Keychain.")
                    Text("This field is for your service access token. Keep the model provider’s API key on your server.").foregroundStyle(.secondary)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Parsing service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") {
                    let trimmed = draftEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty, (URL(string: trimmed)?.scheme != "https" || URL(string: trimmed)?.host == nil) { error = ScriptError.invalidEndpoint.localizedDescription; return }
                    do { try SecureToken.save(token); endpoint = trimmed; dismiss() } catch { self.error = error.localizedDescription }
                } }
            }
            .onAppear { token = SecureToken.read(); draftEndpoint = endpoint }
        }
    }
}

struct PracticeSettingsView: View {
    @EnvironmentObject private var store: ShowStore
    @Environment(\.dismiss) private var dismiss
    @State var show: Show
    var body: some View {
        Form {
            Section("Your young performer") {
                Picker("Age range", selection: $show.settings.age) { ForEach(AgeBand.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Script language", selection: $show.settings.locale) {
                    Text("English (US)").tag("en-US"); Text("English (UK)").tag("en-GB"); Text("简体中文").tag("zh-CN")
                }
            }
            Section("Rehearsal") {
                VStack(alignment: .leading) { Text("Speaking pace"); Slider(value: $show.settings.speechRate, in: 0.3...0.55, step: 0.01); HStack { Text("Gentle"); Spacer(); Text("Lively") }.font(.caption).foregroundStyle(.secondary) }
                Toggle("Show my lines in Practice", isOn: $show.settings.showPracticeText)
                Toggle("Read stage directions aloud", isOn: $show.settings.speakStageDirections)
                Toggle("Quiet start and finish sounds", isOn: $show.settings.soundEffects)
            }
            Section("Remembering a line") {
                Stepper("\(show.settings.masterySuccesses) successful unprompted attempts", value: $show.settings.masterySuccesses, in: 3...10)
                Stepper("Across \(show.settings.masterySessions) separate sessions", value: $show.settings.masterySessions, in: 2...5)
                Text("Reading, repeating a demonstration, using a hint, and tapping Next do not count as unprompted mastery.").font(.footnote)
            }
            Section("Privacy") { Text("Speech recognition must run on this device. If it is unavailable, your child can keep rehearsing with manual controls. Audio and transcripts are not saved.") }
        }.navigationTitle("Practice settings").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { store.save(show); dismiss() } } }
    }
}

struct ProgressScreen: View {
    @Environment(\.dismiss) private var dismiss
    let show: Show
    var embedded = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Every line is a little more yours.").font(.system(.largeTitle, design: .rounded).bold())
                Text("\(show.masteredCount) of \(show.assignedLines.count) lines mastered").foregroundStyle(StageStyle.muted)
                ProgressView(value: Double(show.masteredCount), total: Double(max(1, show.assignedLines.count))).tint(StageStyle.red)
                ForEach(show.scenes) { scene in
                    StageCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(scene.title).font(.headline)
                            Label(show.sceneState(scene.id), systemImage: show.sceneState(scene.id) == "Ready" ? "checkmark.circle" : "leaf").foregroundStyle(StageStyle.muted)
                            ForEach(show.assignedLines.filter { $0.sceneId == scene.id }) { line in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(line.text).font(.system(.body, design: .rounded))
                                    Text(show.progress[line.id]?.state(settings: show.settings).rawValue ?? "New").font(.caption.weight(.semibold)).foregroundStyle(StageStyle.muted)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }.padding(28).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(StageStyle.ivory).navigationTitle("My progress")
            .toolbar { if !embedded { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } } }
    }
}

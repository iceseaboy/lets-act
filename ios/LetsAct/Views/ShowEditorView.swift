import SwiftUI
import AVFoundation

struct ShowEditorView: View {
    @EnvironmentObject private var store: ShowStore
    @Environment(\.dismiss) private var dismiss
    @State var show: Show
    var aliases: [ParsedScript.AliasSuggestion] = []
    var onSave: ((Show) -> Void)?
    @State private var tab = "Script"
    @State private var selectedScene = ""
    @State private var mergeFrom = ""
    @State private var mergeTo = ""
    @State private var mergeConfirmation = false
    @State private var showSource = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Review section", selection: $tab) { Text("Script").tag("Script"); Text("Cast & roles").tag("Cast"); Text("Confirm").tag("Confirm") }.pickerStyle(.segmented).padding()
            if tab == "Script" { scriptEditor }
            else if tab == "Cast" { castEditor }
            else { confirmation }
        }
        .navigationTitle("Review your show")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Save draft") { save(reviewed: false) } }
            ToolbarItem(placement: .topBarTrailing) { Button { showSource = true } label: { Image(systemName: "doc.plaintext") }.accessibilityLabel("View original extracted text") }
        }
        .sheet(isPresented: $showSource) {
            NavigationStack { ScrollView { Text(show.sourceText).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding() }.navigationTitle("Original source").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSource = false } } } }
        }
        .confirmationDialog("Merge these characters? Their lines and assigned roles will be combined.", isPresented: $mergeConfirmation, titleVisibility: .visible) {
            Button("Merge characters") { show.mergeCharacter(mergeFrom, into: mergeTo); mergeFrom = ""; mergeTo = "" }
        }
        .onAppear { if selectedScene.isEmpty { selectedScene = show.scenes.first?.id ?? "" } }
    }

    private var scriptEditor: some View {
        List {
            Section("Show") { TextField("Title", text: $show.title) }
            Section("Scenes") {
                ForEach($show.scenes) { $scene in TextField("Scene heading", text: $scene.title) }
                .onDelete { indices in
                    let ids = Set(indices.map { show.scenes[$0].id })
                    // Keep lines intact: only empty scenes can be removed.
                    show.scenes.removeAll { scene in ids.contains(scene.id) && !show.units.contains(where: { $0.sceneId == scene.id }) }
                    if !show.scenes.contains(where: { $0.id == selectedScene }) { selectedScene = show.scenes.first?.id ?? "" }
                }
                Button("Add scene", systemImage: "plus") { let scene = Scene(title: "Scene \(show.scenes.count + 1)"); show.scenes.append(scene); selectedScene = scene.id }
            }
            Section {
                Picker("Showing", selection: $selectedScene) { ForEach(show.scenes) { Text($0.title).tag($0.id) } }
                ForEach(show.units.filter { $0.sceneId == selectedScene }.sorted { $0.order < $1.order }) { unit in
                    if let index = show.units.firstIndex(where: { $0.id == unit.id }) {
                        NavigationLink { UnitEditorView(unit: $show.units[index], scenes: show.scenes, characters: show.characters) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(unit.type.isSpoken ? (show.character(unit.characterId)?.name ?? "Choose speaker") : unit.type.label).font(.caption.weight(.semibold)).foregroundStyle(StageStyle.muted)
                                Text(unit.text).lineLimit(3)
                            }.padding(.vertical, 5)
                        }
                        .swipeActions { Button("Delete", role: .destructive) { show.units.removeAll { $0.id == unit.id } } }
                        .contextMenu {
                            Button("Move earlier", systemImage: "arrow.up") { move(unit, by: -1) }
                            Button("Move later", systemImage: "arrow.down") { move(unit, by: 1) }
                        }
                    }
                }
                Button("Add missing line", systemImage: "plus") {
                    guard !selectedScene.isEmpty else { return }
                    show.units.append(ScriptUnit(type: .dialogue, sceneId: selectedScene, characterId: show.characters.first?.id, text: "New line", order: (show.units.map(\.order).max() ?? -1) + 1))
                }.disabled(show.scenes.isEmpty)
            } header: { Text("Lines") } footer: { Text("Tap to edit text, speaker, scene or type. Swipe to remove OCR noise. Touch and hold to reorder a line. Move a scene’s lines elsewhere before deleting the scene.") }
        }
    }
    private var castEditor: some View {
        Form {
            Section {
                Text("Select every role your child plays. The app will perform the rest.")
                ForEach($show.characters) { $character in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            RoleAvatar(character: character, size: 40)
                            TextField("Character name", text: $character.name)
                            Toggle("Child role", isOn: Binding(get: { show.childRoles.contains(character.id) }, set: { selected in
                                if selected { if !show.childRoles.contains(character.id) { show.childRoles.append(character.id) } }
                                else { show.childRoles.removeAll { $0 == character.id } }
                            })).labelsHidden().accessibilityLabel("Child plays \(character.name)")
                        }
                        let lines = show.units.filter { $0.characterId == character.id && $0.type.isSpoken }
                        Text("\(lines.count) lines in \(Set(lines.map(\.sceneId)).count) scenes").font(.caption).foregroundStyle(.secondary)
                        Picker("Voice", selection: Binding(get: { character.voiceIdentifier ?? "" }, set: { character.voiceIdentifier = $0.isEmpty ? nil : $0 })) {
                            Text("Automatic cast voice").tag("")
                            ForEach(AVSpeechSynthesisVoice.speechVoices().filter { $0.language == show.settings.locale }, id: \.identifier) { voice in Text(voice.name).tag(voice.identifier) }
                        }
                    }.padding(.vertical, 8)
                }
                Button("Add / split a character", systemImage: "person.badge.plus") { show.characters.append(CastMember(name: "New character", colorIndex: show.characters.count % 6)) }
                Text("To split an incorrectly merged character, add a character here, then assign the affected lines to them in Script.").font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Who is your child playing?") }
            if !aliases.isEmpty {
                Section("Suggested aliases — review before merging") {
                    ForEach(aliases) { alias in
                        if let source = show.character(alias.sourceId), let target = show.character(alias.targetId) {
                            Button { mergeFrom = source.id; mergeTo = target.id; mergeConfirmation = true } label: {
                                VStack(alignment: .leading) { Text("\(source.name) → \(target.name)"); Text(alias.reason).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }
            }
            Section("Merge duplicate characters") {
                Picker("Merge", selection: $mergeFrom) { Text("Choose character").tag(""); ForEach(show.characters) { Text($0.name).tag($0.id) } }
                Picker("Into", selection: $mergeTo) { Text("Choose character").tag(""); ForEach(show.characters) { Text($0.name).tag($0.id) } }
                Button("Review merge") { mergeConfirmation = true }.disabled(mergeFrom.isEmpty || mergeTo.isEmpty || mergeFrom == mergeTo)
            }
        }
    }
    private var confirmation: some View {
        Form {
            Section("Before the curtain rises") {
                Label("\(show.scenes.count) scenes", systemImage: "rectangle.stack")
                Label("\(show.characters.count) characters", systemImage: "person.2")
                Label("\(show.assignedLines.count) child lines", systemImage: "text.bubble")
                Text("Check every line, speaker, scene, and child role. Confirming makes this script available in child mode.")
            }
            if !show.validationErrors.isEmpty || show.childRoles.isEmpty {
                Section("Still to review") {
                    ForEach(show.validationErrors, id: \.self) { Text($0).foregroundStyle(.red) }
                    if show.childRoles.isEmpty { Text("Choose at least one child role in Cast & roles.") }
                    if !show.childRoles.isEmpty && show.assignedLines.isEmpty { Text("The selected child roles need dialogue or lyrics.") }
                }
            }
            Section { Button("I reviewed this — ready to practice", systemImage: "checkmark.circle") { save(reviewed: true) }.disabled(!show.validationErrors.isEmpty || show.assignedLines.isEmpty) }
        }
    }
    private func move(_ unit: ScriptUnit, by offset: Int) {
        let lines = show.units(in: unit.sceneId)
        guard let position = lines.firstIndex(where: { $0.id == unit.id }), lines.indices.contains(position + offset),
              let first = show.units.firstIndex(where: { $0.id == unit.id }), let second = show.units.firstIndex(where: { $0.id == lines[position + offset].id }) else { return }
        let old = show.units[first].order; show.units[first].order = show.units[second].order; show.units[second].order = old
    }
    private func save(reviewed: Bool) {
        show.reviewed = reviewed
        if let old = store.show(show.id) {
            for line in show.units {
                if let previous = old.units.first(where: { $0.id == line.id }), previous.text != line.text || previous.characterId != line.characterId || previous.type != line.type {
                    show.progress.removeValue(forKey: line.id)
                }
            }
        }
        let ids = Set(show.units.map(\.id))
        show.progress = show.progress.filter { ids.contains($0.key) }
        if let onSave { onSave(show) } else { store.save(show); dismiss() }
    }
}

private struct UnitEditorView: View {
    @Binding var unit: ScriptUnit
    let scenes: [Scene]
    let characters: [CastMember]
    var body: some View {
        Form {
            Section("Text") { TextEditor(text: $unit.text).frame(minHeight: 220) }
            Section("Structure") {
                Picker("Type", selection: $unit.type) { ForEach(UnitType.allCases) { Text($0.label).tag($0) } }
                Picker("Scene", selection: $unit.sceneId) { ForEach(scenes) { Text($0.title).tag($0.id) } }
                Picker("Speaker", selection: Binding(get: { unit.characterId ?? "" }, set: { unit.characterId = $0.isEmpty ? nil : $0 })) {
                    Text("No speaker").tag(""); ForEach(characters) { Text($0.name).tag($0.id) }
                }
            }
        }.navigationTitle("Edit line")
    }
}

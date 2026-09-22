import SwiftUI
import PhotosUI
import VisionKit
import UniformTypeIdentifiers

struct ImportShowView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("parserEndpoint") private var endpoint = ""
    let onSave: (Show) -> Void
    @State private var title = ""
    @State private var text = ""
    @State private var originalExtraction: String?
    @State private var photos: [PhotosPickerItem] = []
    @State private var scanning = false
    @State private var importingPDF = false
    @State private var busy = false
    @State private var error: String?
    @State private var cloudConsent = false
    @State private var draft: Show?
    @State private var aliases: [ParsedScript.AliasSuggestion] = []

    var body: some View {
        NavigationStack {
            Group {
                if let draft {
                    ShowEditorView(show: draft, aliases: aliases, onSave: { show in onSave(show); dismiss() })
                } else {
                    Form {
                        Section("Name your show") { TextField("e.g. The Little Star", text: $title).accessibilityIdentifier("show-title") }
                        Section("Bring your script") {
                            Button("Scan pages", systemImage: "doc.viewfinder") { scanning = true }.disabled(!VNDocumentCameraViewController.isSupported)
                            PhotosPicker(selection: $photos, maxSelectionCount: 20, matching: .images) { Label("Choose photos", systemImage: "photo.on.rectangle") }
                            Button("Import PDF", systemImage: "doc") { importingPDF = true }
                        }.disabled(busy)
                        Section {
                            TextEditor(text: $text).frame(minHeight: 250).font(.body).accessibilityIdentifier("script-text")
                            Text("Paste or type here. For local parsing, put speakers before a colon, e.g. LUNA: Hello! Review and correct scanned text before continuing.").font(.footnote).foregroundStyle(.secondary)
                            Text("\(text.count) / 30,000 characters").font(.caption).foregroundStyle(text.count > 30_000 ? .red : .secondary)
                        } header: { Text("Review the extracted text") }
                        if busy { ProgressView("Preparing your script…") }
                        if let error { Text(error).foregroundStyle(.red) }
                        Section {
                            Button("Review with local parsing") { parseLocally() }.disabled(!canParse)
                            if !endpoint.isEmpty { Button("Understand script with AI") { cloudConsent = true }.disabled(!canParse) }
                        } footer: { Text("You will review scenes, characters and lines next. Nothing is ready for your child until you confirm it.") }
                    }.navigationTitle("Create a show")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(busy) }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done editing") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
            .interactiveDismissDisabled(busy)
            .sheet(isPresented: $scanning) { DocumentScanner { result in
                switch result { case .success(let images): recognize(images); case .failure(let failure): error = failure.localizedDescription }
            } }
            .fileImporter(isPresented: $importingPDF, allowedContentTypes: [.pdf]) { result in
                switch result {
                case .success(let url):
                    busy = true
                    Task {
                        do { let extracted = try await Task.detached(priority: .userInitiated) { try ScriptImport.extractPDF(url) }.value; applyExtracted(extracted) }
                        catch { self.error = error.localizedDescription }
                        busy = false
                    }
                case .failure(let error): self.error = error.localizedDescription
                }
            }
            .onChange(of: photos) { _, items in
                guard !items.isEmpty else { return }
                busy = true; error = nil
                Task {
                    do {
                        var images: [UIImage] = []
                        for item in items {
                            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { throw ScriptError.emptyText }
                            images.append(image)
                        }
                        let extracted = try await Task.detached(priority: .userInitiated) { try images.map { try ScriptImport.recognize($0) }.joined(separator: "\n\n") }.value
                        applyExtracted(extracted)
                    } catch { self.error = error.localizedDescription }
                    busy = false; photos = []
                }
            }
            .confirmationDialog("Send this script text for AI understanding?", isPresented: $cloudConsent, titleVisibility: .visible) {
                Button("Send script text") { parseCloud() }
            } message: { Text("The reviewed script text will be sent to \(URL(string: endpoint)?.host ?? endpoint) and its AI provider. No photos or child audio are sent. Check that you may share this script. You can use local parsing instead.") }
        }
    }
    private var canParse: Bool { !busy && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= 30_000 }
    private func applyExtracted(_ extracted: String) {
        guard !extracted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { error = ScriptError.emptyText.localizedDescription; return }
        guard text.count + extracted.count + 2 <= 30_000 else { error = ScriptError.tooLarge.localizedDescription; return }
        text += (text.isEmpty ? "" : "\n\n") + extracted
        originalExtraction = (originalExtraction ?? "") + (originalExtraction == nil ? "" : "\n\n") + extracted
        error = nil
    }
    private func recognize(_ images: [UIImage]) {
        busy = true; error = nil
        Task {
            do { let extracted = try await Task.detached(priority: .userInitiated) { try images.map { try ScriptImport.recognize($0) }.joined(separator: "\n\n") }.value; applyExtracted(extracted) }
            catch { self.error = error.localizedDescription }
            busy = false
        }
    }
    private func parseLocally() {
        var show = LocalScriptParser.parse(text: text, title: title)
        show.sourceText = originalExtraction ?? text
        draft = show
    }
    private func parseCloud() {
        busy = true; error = nil
        Task {
            do {
                let parsed = try await CloudParser.parse(text: text, endpoint: endpoint, token: SecureToken.read())
                let show = try parsed.makeShow(title: title, originalText: originalExtraction ?? text)
                aliases = parsed.aliases; draft = show
            } catch { self.error = error.localizedDescription }
            busy = false
        }
    }
}

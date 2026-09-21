import Vision
import VisionKit
import PDFKit
import SwiftUI

enum ScriptImport {
    static func recognize(_ image: UIImage) throws -> String {
        guard let data = image.pngData() else { throw ScriptError.emptyText }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "zh-Hans"]
        request.automaticallyDetectsLanguage = true
        try VNImageRequestHandler(data: data).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
    static func extractPDF(_ url: URL) throws -> String {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let document = PDFDocument(url: url), !document.isLocked else { throw ScriptError.emptyText }
        guard document.pageCount <= 30 else { throw ScriptError.tooLarge }
        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if text.isEmpty {
                let image = page.thumbnail(of: CGSize(width: 1800, height: 2400), for: .mediaBox)
                pages.append(try recognize(image))
            } else { pages.append(text) }
        }
        let text = pages.joined(separator: "\n\n")
        guard text.count <= 30_000 else { throw ScriptError.tooLarge }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ScriptError.emptyText }
        return text
    }
}

struct DocumentScanner: UIViewControllerRepresentable {
    let onResult: (Result<[UIImage], Error>) -> Void
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        init(_ parent: DocumentScanner) { self.parent = parent }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount <= 30 else { parent.onResult(.failure(ScriptError.tooLarge)); parent.dismiss(); return }
            parent.onResult(.success((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })); parent.dismiss()
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) { parent.dismiss() }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) { parent.onResult(.failure(error)); parent.dismiss() }
    }
}

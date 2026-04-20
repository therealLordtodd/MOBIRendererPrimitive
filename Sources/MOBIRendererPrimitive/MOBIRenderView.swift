import ContentModelPrimitive
import CryptoKit
import FilePreviewPrimitiveHTML
import Foundation
import SwiftUI
import UniformTypeIdentifiers

public struct MOBIRenderView: View {
    private let book: MOBIRenderedBook

    @State private var currentChapterID: String

    public init?(source: ContentRenderSource) {
        guard let context = MOBIRendererPrimitiveSupport.context(for: source) else {
            return nil
        }

        self.book = context.book
        _currentChapterID = State(initialValue: context.book.chapters.first?.id ?? "")
    }

    private var currentChapter: MOBIRenderedChapter? {
        book.chapters.first(where: { $0.id == currentChapterID }) ?? book.chapters.first
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if book.chapters.count > 1 {
                Picker("Chapter", selection: $currentChapterID) {
                    ForEach(book.chapters) { chapter in
                        Text(chapter.title).tag(chapter.id)
                    }
                }
                .pickerStyle(.menu)
            }

            if let chapter = currentChapter {
                HTMLPreviewView(document: chapter.renderedDocument)
                    .id(chapter.id)
            } else {
                ContentUnavailableView(
                    "No MOBI Content",
                    systemImage: "book.closed",
                    description: Text("This MOBI file did not produce any readable chapters.")
                )
            }
        }
    }
}

public enum MOBIRendererPrimitiveSupport {
    public struct Context: Sendable {
        public let book: MOBIRenderedBook
        public let url: URL
    }

    public static func canRender(_ source: ContentRenderSource) -> Bool {
        context(for: source) != nil
    }

    public static func context(for source: ContentRenderSource) -> Context? {
        guard source.contentKind == .mobi,
              let url = materializedURL(for: source) else {
            return nil
        }

        guard let book = try? MOBIRenderingSupport.loadBook(at: url) else {
            return nil
        }

        return Context(book: book, url: url)
    }

    private static func materializedURL(for source: ContentRenderSource) -> URL? {
        switch source {
        case .fileURL(let url):
            return url
        case .data(let data, let suggestedType, let filename):
            guard let suggestedType else {
                return nil
            }

            let root = FileManager.default.temporaryDirectory
                .appendingPathComponent("MOBIRendererPrimitive", isDirectory: true)
            let basename = filename.flatMap {
                URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent
            } ?? "book"
            let safeBasename = sanitizeFilename(basename)
            let ext = resolvedFilenameExtension(
                fileType: suggestedType,
                filename: filename
            )
            let identity = stableDataIdentity(
                data: data,
                fileType: suggestedType,
                filename: filename
            )
            let url = root.appendingPathComponent("\(safeBasename)-\(identity).\(ext)")

            do {
                try FileManager.default.createDirectory(
                    at: root,
                    withIntermediateDirectories: true
                )
                try data.write(to: url, options: .atomic)
                return url
            } catch {
                return nil
            }
        case .markdown, .plainText:
            return nil
        }
    }

    private static func stableDataIdentity(
        data: Data,
        fileType: UTType,
        filename: String?
    ) -> String {
        let digest = SHA256.hash(data: data)
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return [
            filename ?? "untitled",
            fileType.identifier,
            digest,
        ].joined(separator: "::")
    }

    private static func resolvedFilenameExtension(
        fileType: UTType,
        filename: String?
    ) -> String {
        if let explicitExtension = filename.flatMap({
            URL(fileURLWithPath: $0).pathExtension
        }), explicitExtension.isEmpty == false {
            return explicitExtension
        }

        if let preferredExtension = fileType.preferredFilenameExtension,
           preferredExtension.isEmpty == false {
            return preferredExtension
        }

        return "mobi"
    }

    private static func sanitizeFilename(_ filename: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = filename.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let sanitized = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return sanitized.isEmpty ? "book" : sanitized
    }
}

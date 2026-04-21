import ContentModelPrimitive
import CryptoKit
import Foundation
import HTMLRendererPrimitive
import SwiftUI
import UniformTypeIdentifiers

public struct MOBIRenderView: View {
    @Environment(\.mobiRenderTheme) private var theme

    private let context: MOBIRendererPrimitiveSupport.Context

    @State private var currentChapterID: String
    @State private var pendingRevealTarget: MOBIRevealTarget?

    public init?(source: ContentRenderSource) {
        guard let context = MOBIRendererPrimitiveSupport.context(for: source) else {
            return nil
        }

        self.context = context
        _currentChapterID = State(initialValue: context.book.chapters.first?.id ?? "")
    }

    private var book: MOBIRenderedBook {
        context.book
    }

    private var currentChapter: MOBIRenderedChapter? {
        book.chapters.first(where: { $0.id == currentChapterID }) ?? book.chapters.first
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.chapterControlSpacing) {
            if book.chapters.count > 1 {
                Picker("Chapter", selection: $currentChapterID) {
                    ForEach(book.chapters) { chapter in
                        Text(chapter.title).tag(chapter.id)
                    }
                }
                .pickerStyle(.menu)
            }

            if let chapter = currentChapter {
                HTMLRenderDocumentView(
                    document: chapter.renderedDocument,
                    revealKey: chapterRevealKey(for: chapter.id)
                )
                    .id(chapter.id)
            } else {
                ContentUnavailableView(
                    "No MOBI Content",
                    systemImage: "book.closed",
                    description: Text("This MOBI file did not produce any readable chapters.")
                )
            }
        }
        .task(id: context.revealKey) {
            for await target in MOBIPreviewRevealCoordinator.stream(for: context.revealKey) {
                pendingRevealTarget = target
                if context.chapterOrder[target.chapterID] != nil {
                    currentChapterID = target.chapterID
                }
            }
        }
        .task(id: currentChapterID) {
            await MOBIPreviewSelectionCoordinator.publish(nil, in: context.revealKey)

            guard let chapter = currentChapter else {
                return
            }

            if let pendingRevealTarget,
               pendingRevealTarget.chapterID == chapter.id {
                await HTMLRenderRevealCoordinator.reveal(
                    pendingRevealTarget.targetID,
                    in: chapterRevealKey(for: chapter.id)
                )
                if self.pendingRevealTarget?.chapterID == chapter.id {
                    self.pendingRevealTarget = nil
                }
            }

            let stream = HTMLRenderSelectionCoordinator.stream(
                for: chapterRevealKey(for: chapter.id)
            )
            for await selection in stream {
                guard !Task.isCancelled else {
                    return
                }

                await MOBIPreviewSelectionCoordinator.publish(
                    translatedSelection(selection, chapter: chapter),
                    in: context.revealKey
                )
            }
        }
    }

    private func chapterRevealKey(for chapterID: String) -> String {
        "\(context.revealKey)::chapter::\(chapterID)"
    }

    private func translatedSelection(
        _ selection: ReaderSelectionSnapshot?,
        chapter: MOBIRenderedChapter
    ) -> ReaderSelectionSnapshot? {
        guard var selection else {
            return nil
        }

        let translatedAnchor: TextAnchor
        if case .text(let textAnchor) = selection.anchor {
            let targetID = textAnchor.containerID
                ?? textAnchor.selector
                ?? chapter.rootTargetID
            let qualifiedID = MOBIRendererPrimitiveSupport.qualifiedContainerID(
                chapterID: chapter.id,
                targetID: targetID
            )
            translatedAnchor = TextAnchor(
                startOffset: textAnchor.startOffset,
                length: textAnchor.length,
                selector: qualifiedID,
                quotedText: textAnchor.quotedText,
                containerID: qualifiedID,
                prefixContext: textAnchor.prefixContext,
                suffixContext: textAnchor.suffixContext,
                representsWholeContainer: textAnchor.representsWholeContainer
            )
        } else {
            translatedAnchor = MOBIRendererPrimitiveSupport.wholeChapterTextAnchor(
                chapterID: chapter.id,
                targetID: chapter.rootTargetID,
                text: selection.text
            )
        }

        selection.anchor = .text(translatedAnchor)
        selection.chapterIndex = chapter.index
        return selection
    }
}

public enum MOBIRendererPrimitiveSupport {
    public struct Context: Sendable {
        public let book: MOBIRenderedBook
        public let url: URL
        public let documentID: DocumentID
        public let revealKey: String
        public let chapterOrder: [String: Int]
    }

    public static func canRender(_ source: ContentRenderSource) -> Bool {
        context(for: source) != nil
    }

    public static func context(for source: ContentRenderSource) -> Context? {
        guard source.contentKind == .mobi,
              let url = materializedURL(for: source) else {
            return nil
        }

        let revealKey = url.absoluteString
        return context(
            url: url,
            documentID: ContentIdentity(revealKey),
            revealKey: revealKey
        )
    }

    static func context(
        url: URL,
        documentID: DocumentID,
        revealKey: String
    ) -> Context? {
        guard let book = try? MOBIRenderingSupport.loadBook(at: url) else {
            return nil
        }

        let chapterOrder = Dictionary(
            uniqueKeysWithValues: book.chapters.map { chapter in
                (chapter.id, chapter.index)
            }
        )

        return Context(
            book: book,
            url: url,
            documentID: documentID,
            revealKey: revealKey,
            chapterOrder: chapterOrder
        )
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

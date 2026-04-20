import ContentModelPrimitive
import Foundation
import HTMLRendererPrimitive

private struct MOBIDocumentTOCProvider: TOCProvider, Sendable {
    let documentID: DocumentID
    let nodes: [TOCNode]

    func tableOfContents() async throws -> [TOCNode] {
        nodes
    }
}

private struct MOBIDocumentAnnotationSurfaceProvider: AnnotationSurfaceProvider, Sendable {
    let documentID: DocumentID
    let revealKey: String
    let chapterOrder: [String: Int]

    var selectionUpdates: AsyncStream<ReaderSelectionSnapshot?> {
        MOBIPreviewSelectionCoordinator.stream(for: revealKey)
    }

    func coordinate(for anchor: AnyContentAnchor) async -> AnnotationSurfaceCoordinate? {
        guard let target = MOBIRendererPrimitiveSupport.revealTarget(for: anchor),
              let order = chapterOrder[target.chapterID] else {
            return nil
        }

        return AnnotationSurfaceCoordinate(
            x: 0,
            y: Double(order),
            width: 1,
            height: 0.1
        )
    }

    func reveal(anchor: AnyContentAnchor) async {
        guard let target = MOBIRendererPrimitiveSupport.revealTarget(for: anchor) else {
            return
        }

        await MOBIPreviewRevealCoordinator.reveal(target, in: revealKey)
    }
}

private struct MOBIDocumentSearchProvider: DocumentSearchProvider, Sendable {
    let documentID: DocumentID
    let chapters: [MOBIRenderedChapter]

    func search(query: SearchQuery) -> AsyncThrowingStream<SearchMatch, Error> {
        let normalizedQuery = query.text.trimmingCharacters(in: .whitespacesAndNewlines)

        return AsyncThrowingStream { continuation in
            guard normalizedQuery.isEmpty == false else {
                continuation.finish()
                return
            }

            Task {
                let matches = chapters.flatMap { chapter in
                    resolvedMatches(
                        in: chapter,
                        query: normalizedQuery,
                        documentID: documentID
                    )
                }

                for match in matches {
                    continuation.yield(match)
                }
                continuation.finish()
            }
        }
    }

    private func resolvedMatches(
        in chapter: MOBIRenderedChapter,
        query: String,
        documentID: DocumentID
    ) -> [SearchMatch] {
        let nsText = chapter.text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        var searchRange = fullRange
        var matches: [SearchMatch] = []
        var matchIndex = 0

        while searchRange.length > 0 {
            let range = nsText.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchRange
            )
            guard range.location != NSNotFound else {
                break
            }

            let matchedText = nsText.substring(with: range)
            let location = max(0, range.location)
            let end = max(location, location + range.length)
            let anchor = MOBIRendererPrimitiveSupport.wholeChapterTextAnchor(
                chapterID: chapter.id,
                targetID: chapter.rootTargetID,
                text: chapter.text
            )

            matches.append(
                SearchMatch(
                    id: ContentIdentity("\(documentID.rawValue):\(chapter.id):\(matchIndex)"),
                    text: matchedText,
                    anchor: .text(anchor),
                    range: location..<end,
                    score: 1
                )
            )

            matchIndex += 1
            let nextLocation = range.location + max(range.length, 1)
            guard nextLocation < nsText.length else {
                break
            }
            searchRange = NSRange(
                location: nextLocation,
                length: nsText.length - nextLocation
            )
        }

        return matches
    }
}

struct MOBIRevealTarget: Sendable, Equatable {
    let chapterID: String
    let targetID: String
}

enum MOBIPreviewRevealCoordinator {
    static func stream(for revealKey: String) -> AsyncStream<MOBIRevealTarget> {
        AsyncStream { continuation in
            let streamID = UUID()
            Task { @MainActor in
                MOBIPreviewRevealRegistry.shared.register(
                    continuation,
                    for: revealKey,
                    streamID: streamID
                )
            }

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    MOBIPreviewRevealRegistry.shared.unregister(
                        streamID: streamID,
                        for: revealKey
                    )
                }
            }
        }
    }

    static func reveal(
        _ target: MOBIRevealTarget,
        in revealKey: String
    ) async {
        await MainActor.run {
            MOBIPreviewRevealRegistry.shared.publish(target, for: revealKey)
        }
    }
}

enum MOBIPreviewSelectionCoordinator {
    static func stream(for revealKey: String) -> AsyncStream<ReaderSelectionSnapshot?> {
        AsyncStream { continuation in
            let streamID = UUID()
            Task { @MainActor in
                MOBIPreviewSelectionRegistry.shared.register(
                    continuation,
                    for: revealKey,
                    streamID: streamID
                )
            }

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    MOBIPreviewSelectionRegistry.shared.unregister(
                        streamID: streamID,
                        for: revealKey
                    )
                }
            }
        }
    }

    static func publish(
        _ selection: ReaderSelectionSnapshot?,
        in revealKey: String
    ) async {
        await MainActor.run {
            MOBIPreviewSelectionRegistry.shared.publish(selection, for: revealKey)
        }
    }
}

@MainActor
private final class MOBIPreviewRevealRegistry {
    static let shared = MOBIPreviewRevealRegistry()

    private var continuations: [String: [UUID: AsyncStream<MOBIRevealTarget>.Continuation]] = [:]

    func register(
        _ continuation: AsyncStream<MOBIRevealTarget>.Continuation,
        for revealKey: String,
        streamID: UUID
    ) {
        continuations[revealKey, default: [:]][streamID] = continuation
    }

    func unregister(
        streamID: UUID,
        for revealKey: String
    ) {
        continuations[revealKey]?[streamID] = nil
        if continuations[revealKey]?.isEmpty == true {
            continuations[revealKey] = nil
        }
    }

    func publish(
        _ target: MOBIRevealTarget,
        for revealKey: String
    ) {
        continuations[revealKey]?.values.forEach { continuation in
            continuation.yield(target)
        }
    }
}

@MainActor
private final class MOBIPreviewSelectionRegistry {
    static let shared = MOBIPreviewSelectionRegistry()

    private var continuations: [String: [UUID: AsyncStream<ReaderSelectionSnapshot?>.Continuation]] = [:]

    func register(
        _ continuation: AsyncStream<ReaderSelectionSnapshot?>.Continuation,
        for revealKey: String,
        streamID: UUID
    ) {
        continuations[revealKey, default: [:]][streamID] = continuation
    }

    func unregister(
        streamID: UUID,
        for revealKey: String
    ) {
        continuations[revealKey]?[streamID] = nil
        if continuations[revealKey]?.isEmpty == true {
            continuations[revealKey] = nil
        }
    }

    func publish(
        _ selection: ReaderSelectionSnapshot?,
        for revealKey: String
    ) {
        continuations[revealKey]?.values.forEach { continuation in
            continuation.yield(selection)
        }
    }
}

extension MOBIRendererPrimitiveSupport {
    public static func annotationSurfaceProvider(
        documentID: DocumentID,
        revealKey: String,
        url: URL
    ) -> (any AnnotationSurfaceProvider)? {
        guard let context = context(
            url: url,
            documentID: documentID,
            revealKey: revealKey
        ) else {
            return nil
        }

        return MOBIDocumentAnnotationSurfaceProvider(
            documentID: context.documentID,
            revealKey: context.revealKey,
            chapterOrder: context.chapterOrder
        )
    }

    public static func annotationSurfaceProvider(
        for source: ContentRenderSource
    ) -> (any AnnotationSurfaceProvider)? {
        guard let context = context(for: source) else {
            return nil
        }

        return MOBIDocumentAnnotationSurfaceProvider(
            documentID: context.documentID,
            revealKey: context.revealKey,
            chapterOrder: context.chapterOrder
        )
    }

    public static func tocProvider(
        documentID: DocumentID,
        url: URL
    ) -> (any TOCProvider)? {
        guard let context = context(
            url: url,
            documentID: documentID,
            revealKey: url.absoluteString
        ),
        context.book.chapters.isEmpty == false else {
            return nil
        }

        let nodes = context.book.chapters.map { chapter in
            TOCNode(
                id: ContentIdentity("\(context.documentID.rawValue):\(chapter.id)"),
                title: chapter.title,
                anchor: .text(
                    wholeChapterTextAnchor(
                        chapterID: chapter.id,
                        targetID: chapter.rootTargetID,
                        text: chapter.text
                    )
                )
            )
        }

        return MOBIDocumentTOCProvider(
            documentID: context.documentID,
            nodes: nodes
        )
    }

    public static func tocProvider(
        for source: ContentRenderSource
    ) -> (any TOCProvider)? {
        guard let context = context(for: source),
              context.book.chapters.isEmpty == false else {
            return nil
        }

        let nodes = context.book.chapters.map { chapter in
            TOCNode(
                id: ContentIdentity("\(context.documentID.rawValue):\(chapter.id)"),
                title: chapter.title,
                anchor: .text(
                    wholeChapterTextAnchor(
                        chapterID: chapter.id,
                        targetID: chapter.rootTargetID,
                        text: chapter.text
                    )
                )
            )
        }

        return MOBIDocumentTOCProvider(
            documentID: context.documentID,
            nodes: nodes
        )
    }

    public static func documentSearchProvider(
        documentID: DocumentID,
        url: URL
    ) -> (any DocumentSearchProvider)? {
        guard let context = context(
            url: url,
            documentID: documentID,
            revealKey: url.absoluteString
        ),
        context.book.chapters.isEmpty == false else {
            return nil
        }

        return MOBIDocumentSearchProvider(
            documentID: context.documentID,
            chapters: context.book.chapters
        )
    }

    public static func documentSearchProvider(
        for source: ContentRenderSource
    ) -> (any DocumentSearchProvider)? {
        guard let context = context(for: source),
              context.book.chapters.isEmpty == false else {
            return nil
        }

        return MOBIDocumentSearchProvider(
            documentID: context.documentID,
            chapters: context.book.chapters
        )
    }

    static func wholeChapterTextAnchor(
        chapterID: String,
        targetID: String,
        text: String
    ) -> TextAnchor {
        let qualifiedID = qualifiedContainerID(
            chapterID: chapterID,
            targetID: targetID
        )
        return TextAnchor(
            startOffset: 0,
            length: text.count,
            selector: qualifiedID,
            quotedText: text.isEmpty ? nil : text,
            containerID: qualifiedID,
            representsWholeContainer: true
        )
    }

    static func revealTarget(for anchor: AnyContentAnchor) -> MOBIRevealTarget? {
        guard case .text(let textAnchor) = anchor else {
            return nil
        }

        let rawID = textAnchor.containerID ?? textAnchor.selector
        return decodeRevealTarget(from: rawID)
    }

    static func qualifiedContainerID(
        chapterID: String,
        targetID: String
    ) -> String {
        "mobi://\(chapterID)#\(targetID)"
    }

    static func decodeRevealTarget(from rawID: String?) -> MOBIRevealTarget? {
        guard let rawID,
              rawID.hasPrefix("mobi://") else {
            return nil
        }

        let remainder = String(rawID.dropFirst("mobi://".count))
        let components = remainder.split(
            separator: "#",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        guard let chapterComponent = components.first,
              chapterComponent.isEmpty == false else {
            return nil
        }

        let chapterID = String(chapterComponent)
        let targetID = components.count > 1 && components[1].isEmpty == false
            ? String(components[1])
            : "mobi-chapter-root-0"
        return MOBIRevealTarget(
            chapterID: chapterID,
            targetID: targetID
        )
    }
}

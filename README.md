# MOBIRendererPrimitive

MOBIRendererPrimitive is the standalone MOBI rendering lane for the reader stack. It parses local MOBI-family content, extracts readable chapters, renders chapter content through the shared HTML renderer path, and exposes first-pass reader provider seams for TOC, document search, annotation-surface reveal, and selection publishing.

Use this package when a host needs MOBI files to be readable in the same general architecture as EPUB, HTML, PDF, and Office documents. It is the format-specific engine behind `ReaderKitMOBI`, but it can also be imported directly by smaller hosts that only need a MOBI view.

The package is intentionally practical rather than magical. MOBI is a messy family of formats. Current support focuses on `.mobi` and `.prc` style content, with `.azw3` and `.kf8` routed at the content-kind level but not promised as fully faithful in every case. The goal is a usable reader lane that can improve with real files and user feedback, not a speculative all-format reimplementation.

## What The Package Provides

- `MOBIRenderView`, the direct SwiftUI render view.
- `MOBIRendererPrimitiveFeature`, the `ContentRendererEntry` for registry composition.
- `MOBIRenderingSupport.loadBook(at:)`, which extracts a `MOBIRenderedBook`.
- `MOBIRenderedBook` and `MOBIRenderedChapter` models.
- MOBI parser error reporting through `MOBIParserError`.
- Provider seams for TOC, document search, and annotation surfaces.
- HTML-based chapter presentation through `HTMLRendererPrimitive`.

## Example: Direct MOBI Rendering

```swift
import ContentModelPrimitive
import MOBIRendererPrimitive
import SwiftUI

struct MOBIBookView: View {
    let url: URL

    var body: some View {
        if let view = MOBIRenderView(source: .fileURL(url)) {
            view
                .frame(minHeight: 560)
        } else {
            ContentUnavailableView("Cannot render MOBI", systemImage: "book")
        }
    }
}
```

Use this when a host wants a direct local MOBI reading surface.

## Example: Inspect Parsed Chapters

```swift
import MOBIRendererPrimitive

let book = try MOBIRenderingSupport.loadBook(at: mobiURL)

for chapter in book.chapters {
    print(chapter.title ?? chapter.id)
}
```

This is useful for debugging real-world files, building simple navigation, or deciding whether to fall back to a generic preview.

## Example: Registry Installation

```swift
import ContentModelPrimitive
import MOBIRendererPrimitive

let registry = ContentRendererRegistry()
registry.register(MOBIRendererPrimitiveFeature.self)
```

ReaderKit normally reaches this through `ReaderKitMOBI`, which also adapts ReaderKit annotations into the HTML presentation layer used by MOBI chapters.

## How To Wire It Into A Host App

1. Add `MOBIRendererPrimitive` to the host target. This also brings in `HTMLRendererPrimitive`.
2. Represent local files as `ContentRenderSource.fileURL(mobiURL)`.
3. Use `MOBIRenderView(source:)` for direct display.
4. Use `MOBIRenderingSupport.loadBook(at:)` when the host wants chapter metadata or parser errors before rendering.
5. Use `MOBIRendererPrimitiveFeature` for registry-driven readers.
6. For full reader behavior, import `ReaderKitMOBI` or `ReaderKitStandard`.
7. Keep a fallback path for unsupported or low-fidelity MOBI-family files. Real user files should drive fidelity improvements.

## Relationship To ReaderKit

`ReaderKitMOBI` installs this primitive into ReaderKit and maps `ContentAnnotation` values into `HTMLRenderPresentedAnnotation`. ReaderKit owns session orchestration, cross-document search, annotation mutation, selection actions, and chrome. MOBIRendererPrimitive owns MOBI parsing and chapter/provider behavior.

## Current Boundaries

- `.mobi` and `.prc` are the intended first-pass coverage.
- `.azw3` and `.kf8` are routed as MOBI-family inputs but should be treated as best-effort until real-file validation expands confidence.
- DRM, cloud-library behavior, and durable reading progress are out of scope.
- Provider fidelity is chapter-oriented rather than full CFI-style precision.

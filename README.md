# MOBIRendererPrimitive

Standalone MOBI rendering for `ContentRenderSource` inputs that resolve to `.mobi`.

What it provides:
- `MOBIRenderView` for direct host use
- `MOBIRendererPrimitiveFeature` as a `ContentRendererEntry`
- first-pass `.mobi` / `.prc` parsing and chapter rendering without a `ReaderKit` dependency
- first-pass reader-facing seams for chapter TOC, chapter search, and annotation-surface reveal

What it does not provide yet:
- guaranteed `.azw3` / `.kf8` coverage in the first pass
- EPUB-grade intra-chapter provider fidelity
- reader chrome or session orchestration

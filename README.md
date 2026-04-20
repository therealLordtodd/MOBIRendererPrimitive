# MOBIRendererPrimitive

Standalone MOBI rendering for `ContentRenderSource` inputs that resolve to `.mobi`.

What it provides:
- `MOBIRenderView` for direct host use
- `MOBIRendererPrimitiveFeature` as a `ContentRendererEntry`
- first-pass `.mobi` / `.prc` parsing and chapter rendering without a `ReaderKit` dependency

What it does not provide yet:
- full ReaderKit provider seams such as TOC, search, or annotation-surface support
- guaranteed `.azw3` / `.kf8` coverage in the first pass
- reader chrome or session orchestration

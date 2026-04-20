import ContentModelPrimitive
import SwiftUI

public enum MOBIRendererPrimitiveFeature: ContentRendererEntry {
    public static let supportedKinds: Set<ContentKind> = [.mobi]

    public static func canRender(_ source: ContentRenderSource) -> Bool {
        MOBIRendererPrimitiveSupport.canRender(source)
    }

    @MainActor
    public static func view(for source: ContentRenderSource) -> AnyView? {
        guard let view = MOBIRenderView(source: source) else {
            return nil
        }

        return AnyView(view)
    }

    public static func annotationSurfaceProvider(
        for source: ContentRenderSource
    ) -> (any AnnotationSurfaceProvider)? {
        MOBIRendererPrimitiveSupport.annotationSurfaceProvider(for: source)
    }

    public static func tocProvider(for source: ContentRenderSource) -> (any TOCProvider)? {
        MOBIRendererPrimitiveSupport.tocProvider(for: source)
    }

    public static func documentSearchProvider(
        for source: ContentRenderSource
    ) -> (any DocumentSearchProvider)? {
        MOBIRendererPrimitiveSupport.documentSearchProvider(for: source)
    }
}

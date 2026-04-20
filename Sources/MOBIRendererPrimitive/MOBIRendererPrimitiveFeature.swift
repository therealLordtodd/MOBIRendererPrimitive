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
}

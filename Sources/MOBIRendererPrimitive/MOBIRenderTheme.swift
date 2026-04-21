import CoreGraphics
import SwiftUI

public struct MOBIRenderTheme: Sendable {
    public var chapterControlSpacing: CGFloat

    public init(chapterControlSpacing: CGFloat = 12) {
        self.chapterControlSpacing = chapterControlSpacing
    }

    public static let `default` = MOBIRenderTheme()
}

private struct MOBIRenderThemeKey: EnvironmentKey {
    static let defaultValue: MOBIRenderTheme = .default
}

public extension EnvironmentValues {
    var mobiRenderTheme: MOBIRenderTheme {
        get { self[MOBIRenderThemeKey.self] }
        set { self[MOBIRenderThemeKey.self] = newValue }
    }
}

public extension View {
    func mobiRenderTheme(_ theme: MOBIRenderTheme) -> some View {
        environment(\.mobiRenderTheme, theme)
    }
}

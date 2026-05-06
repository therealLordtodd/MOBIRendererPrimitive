import Foundation

enum MOBIRendererLocalization {
    static var chapterPickerTitle: String {
        localizedString("mobiRenderer.chapterPicker.title")
    }

    static var noContentTitle: String {
        localizedString("mobiRenderer.empty.title")
    }

    static var noContentDescription: String {
        localizedString("mobiRenderer.empty.description")
    }

    static var previewFailureTitle: String {
        localizedString("mobiRenderer.preview.failure.title")
    }

    static var invalidFileError: String {
        localizedString("mobiRenderer.error.invalidFile")
    }

    static func unsupportedCompressionError(type: UInt16) -> String {
        formattedString("mobiRenderer.error.unsupportedCompression", type.formatted())
    }

    static var unsupportedEncryptionError: String {
        localizedString("mobiRenderer.error.unsupportedEncryption")
    }

    static var noTextContentError: String {
        localizedString("mobiRenderer.error.noTextContent")
    }

    static func malformedHeaderError(detail: String) -> String {
        formattedString("mobiRenderer.error.malformedHeader", detail)
    }

    private static func localizedString(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    private static func formattedString(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localizedString(key), locale: .current, arguments: arguments)
    }
}

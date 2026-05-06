#if DEBUG
import ContentModelPrimitive
import SwiftUI
import UniformTypeIdentifiers

#Preview("MOBI reader") {
    if let view = MOBIRenderView(source: MOBIRenderPreviewData.source) {
        view
            .frame(minHeight: 520)
            .padding()
    } else {
        ContentUnavailableView(MOBIRendererLocalization.previewFailureTitle, systemImage: "book.closed")
    }
}

private enum MOBIRenderPreviewData {
    static let source = ContentRenderSource.data(
        makeMinimalMOBIData(
            html: """
            <html><body>
            <h1>Opening Notes</h1>
            <p>This synthetic MOBI sample exercises the chapter picker and HTML render path.</p>
            <mbp:pagebreak/>
            <h1>Second Chapter</h1>
            <p>Preview content stays small while still proving the parser-backed reader surface.</p>
            </body></html>
            """,
            title: "Preview MOBI"
        ),
        suggestedType: UTType(filenameExtension: "mobi"),
        filename: "preview.mobi"
    )

    private static func makeMinimalMOBIData(
        html: String,
        title: String
    ) -> Data {
        let textData = Data(html.utf8)
        var record0 = Data(repeating: 0, count: 148 + title.utf8.count)

        writeUInt16BE(1, to: &record0, at: 0)
        writeUInt32BE(UInt32(textData.count), to: &record0, at: 4)
        writeUInt16BE(1, to: &record0, at: 8)
        writeUInt16BE(4096, to: &record0, at: 10)
        writeUInt16BE(0, to: &record0, at: 12)

        record0.replaceSubrange(16..<20, with: Data("MOBI".utf8))
        writeUInt32BE(132, to: &record0, at: 20)
        writeUInt32BE(2, to: &record0, at: 24)
        writeUInt32BE(65001, to: &record0, at: 28)

        let titleOffset = 148
        let titleData = Data(title.utf8)
        writeUInt32BE(UInt32(titleOffset), to: &record0, at: 100)
        writeUInt32BE(UInt32(titleData.count), to: &record0, at: 104)
        record0.replaceSubrange(titleOffset..<(titleOffset + titleData.count), with: titleData)

        let headerLength = 78 + 16
        let record0Offset = headerLength
        let record1Offset = record0Offset + record0.count
        let eofOffset = record1Offset + textData.count

        var data = Data(repeating: 0, count: headerLength)
        let nameData = Data("Preview MOBI".utf8)
        data.replaceSubrange(0..<min(32, nameData.count), with: nameData.prefix(32))
        writeUInt16BE(2, to: &data, at: 76)
        writeUInt32BE(UInt32(record0Offset), to: &data, at: 78)
        writeUInt32BE(UInt32(record1Offset), to: &data, at: 86)

        data.append(record0)
        data.append(textData)

        if data.count < eofOffset {
            data.append(Data(repeating: 0, count: eofOffset - data.count))
        }

        return data
    }

    private static func writeUInt16BE(_ value: UInt16, to data: inout Data, at offset: Int) {
        data[offset] = UInt8((value >> 8) & 0xFF)
        data[offset + 1] = UInt8(value & 0xFF)
    }

    private static func writeUInt32BE(_ value: UInt32, to data: inout Data, at offset: Int) {
        data[offset] = UInt8((value >> 24) & 0xFF)
        data[offset + 1] = UInt8((value >> 16) & 0xFF)
        data[offset + 2] = UInt8((value >> 8) & 0xFF)
        data[offset + 3] = UInt8(value & 0xFF)
    }
}
#endif

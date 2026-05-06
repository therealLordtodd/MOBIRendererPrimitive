import ContentModelPrimitive
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MOBIRendererPrimitive

@Suite("MOBIRendererPrimitive")
struct MOBIRendererPrimitiveTests {
    @MainActor
    @Test func mobiFeatureBuildsForDataSources() throws {
        let source = ContentRenderSource.data(
            makeMinimalMOBIData(
                html: "<html><body><h1>Overview</h1><p>Hello world.</p></body></html>"
            ),
            suggestedType: UTType(filenameExtension: "mobi"),
            filename: "sample.mobi"
        )

        #expect(MOBIRendererPrimitiveFeature.canRender(source))
        #expect(MOBIRendererPrimitiveFeature.view(for: source) != nil)
    }

    @Test func mobiSupportParsesTitleAndChapters() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sample-\(UUID().uuidString).mobi")
        try makeMinimalMOBIData(
            html: "<html><body><h1>Intro</h1><p>Hello world.</p><mbp:pagebreak/><h1>Next</h1><p>More text.</p></body></html>",
            title: "My MOBI"
        ).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let book = try MOBIRenderingSupport.loadBook(at: url)

        #expect(book.title == "My MOBI")
        #expect(book.chapters.count == 2)
        #expect(book.chapters.first?.title == "Intro")
        #expect(book.chapters.first?.text.contains("Hello world.") == true)
    }

    @MainActor
    @Test func mobiFeatureProvidesReaderFacingProviders() async throws {
        let source = ContentRenderSource.data(
            makeMinimalMOBIData(
                html: """
                <html><body>
                <h1>Intro</h1><p>Hello world.</p>
                <mbp:pagebreak/>
                <h1>Next</h1><p>More text.</p>
                </body></html>
                """
            ),
            suggestedType: UTType(filenameExtension: "mobi"),
            filename: "sample.mobi"
        )

        let toc = try #require(MOBIRendererPrimitiveFeature.tocProvider(for: source))
        let surface = try #require(MOBIRendererPrimitiveFeature.annotationSurfaceProvider(for: source))
        let search = try #require(MOBIRendererPrimitiveFeature.documentSearchProvider(for: source))

        let nodes = try await toc.tableOfContents()
        #expect(nodes.count == 2)
        #expect(nodes.map(\.title) == ["Intro", "Next"])

        let coordinate = await surface.coordinate(for: nodes[1].anchor)
        #expect(coordinate?.y == 1)

        var matches: [SearchMatch] = []
        for try await match in search.search(query: SearchQuery(text: "More")) {
            matches.append(match)
        }

        #expect(matches.isEmpty == false)
    }

    @Test func explicitURLProvidersHonorCallerOwnedDocumentID() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sample-\(UUID().uuidString).mobi")
        try makeMinimalMOBIData(
            html: """
            <html><body>
            <h1>Overview</h1><p>Hello world.</p>
            <mbp:pagebreak/>
            <h1>Appendix</h1><p>More text.</p>
            </body></html>
            """
        ).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let documentID = ContentIdentity("mobi-doc")
        let toc = try #require(
            MOBIRendererPrimitiveSupport.tocProvider(
                documentID: documentID,
                url: url
            )
        )
        let search = try #require(
            MOBIRendererPrimitiveSupport.documentSearchProvider(
                documentID: documentID,
                url: url
            )
        )
        let surface = try #require(
            MOBIRendererPrimitiveSupport.annotationSurfaceProvider(
                documentID: documentID,
                revealKey: "mobi-reveal",
                url: url
            )
        )

        let nodes = try await toc.tableOfContents()
        #expect(nodes.first?.id.rawValue.contains("mobi-doc") == true)

        var matches: [SearchMatch] = []
        for try await match in search.search(query: SearchQuery(text: "More")) {
            matches.append(match)
        }
        #expect(matches.first?.id.rawValue.contains("mobi-doc") == true)

        let coordinate = await surface.coordinate(for: try #require(nodes.last?.anchor))
        #expect(coordinate?.y == 1)
    }

    @Test func packageOwnedChromeAndParserErrorsResolveThroughModuleResources() {
        #expect(MOBIRendererLocalization.chapterPickerTitle == "Chapter")
        #expect(MOBIRendererLocalization.noContentTitle == "No MOBI Content")
        #expect(
            MOBIRendererLocalization.noContentDescription
                == "This MOBI file did not produce any readable chapters."
        )
        #expect(MOBIRendererLocalization.previewFailureTitle == "Cannot render preview MOBI")
        #expect(MOBIParserError.invalidFile.errorDescription == "Not a valid MOBI/PRC file")
        #expect(MOBIParserError.unsupportedCompression(99).errorDescription == "Unsupported compression type: 99")
        #expect(MOBIParserError.unsupportedEncryption.errorDescription == "DRM-encrypted MOBI files are not supported")
        #expect(MOBIParserError.noTextContent.errorDescription == "No readable text content found")
        #expect(MOBIParserError.malformedHeader("Record table overflow").errorDescription == "Malformed MOBI header: Record table overflow")
    }
}

private func makeMinimalMOBIData(
    html: String,
    title: String = "Sample MOBI"
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
    let nameData = Data("Sample MOBI".utf8)
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

private func writeUInt16BE(_ value: UInt16, to data: inout Data, at offset: Int) {
    data[offset] = UInt8((value >> 8) & 0xFF)
    data[offset + 1] = UInt8(value & 0xFF)
}

private func writeUInt32BE(_ value: UInt32, to data: inout Data, at offset: Int) {
    data[offset] = UInt8((value >> 24) & 0xFF)
    data[offset + 1] = UInt8((value >> 16) & 0xFF)
    data[offset + 2] = UInt8((value >> 8) & 0xFF)
    data[offset + 3] = UInt8(value & 0xFF)
}

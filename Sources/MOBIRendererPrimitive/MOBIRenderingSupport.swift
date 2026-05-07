import Foundation
import HTMLRendererPrimitive

private enum MOBIHTMLRegex {
    static let body = try! NSRegularExpression(pattern: "(?is)<body\\b([^>]*)>(.*)</body>")
    static let styleScriptBlock = try! NSRegularExpression(pattern: "(?is)<(?:style|script)[^>]*>[\\s\\S]*?</(?:style|script)>")
    static let blockOpeningTag = try! NSRegularExpression(pattern: "(?is)<(?:p|div|h[1-6]|li|blockquote|tr)(?:\\s[^>]*)?>")
    static let blockClosingTag = try! NSRegularExpression(pattern: "(?is)</(?:p|div|h[1-6]|li|blockquote|tr)>")
    static let lineBreakTag = try! NSRegularExpression(pattern: "(?is)<br\\s*/?>")
    static let imageTag = try! NSRegularExpression(pattern: "(?is)<img\\b[^>]*\\/?>")
    static let svgImageTag = try! NSRegularExpression(pattern: "(?is)<image\\b[^>]*\\/?>")
    static let htmlTag = try! NSRegularExpression(pattern: "<[^>]+>")
    static let horizontalWhitespace = try! NSRegularExpression(pattern: "[ \\t]+")
    static let repeatedBlankLines = try! NSRegularExpression(pattern: "[ \\t]*\\n[ \\t]*\\n\\s*")
    static let decimalEntity = try! NSRegularExpression(pattern: "&#(\\d+);")
    static let hexadecimalEntity = try! NSRegularExpression(pattern: "&#x([0-9A-Fa-f]+);")
}

public struct MOBIRenderedChapter: Sendable, Identifiable {
    public let id: String
    public let index: Int
    public let title: String
    public let text: String
    public let rootTargetID: String
    public let renderedDocument: HTMLRenderDocument
}

public struct MOBIRenderedBook: Sendable {
    public let title: String
    public let author: String?
    public let chapters: [MOBIRenderedChapter]
}

public enum MOBIRenderingSupport {
    public static func loadBook(at url: URL) throws -> MOBIRenderedBook {
        try MOBIParsingSupport.parseBook(at: url)
    }
}

private enum MOBIParsingSupport {
    private static let maxFileSize = 200_000_000
    private static let huffCdicCompression: UInt16 = 17480
    private static let pageBreakRegex = try! NSRegularExpression(
        pattern: "<mbp:pagebreak\\s*/?>",
        options: .caseInsensitive
    )
    private static let headingBreakRegex = try! NSRegularExpression(
        pattern: "<h[1-3][^>]*>",
        options: .caseInsensitive
    )

    private struct PDBHeader {
        let name: String
        let recordCount: Int
        let recordOffsets: [Int]
    }

    private struct PalmDocHeader {
        let compressionType: UInt16
        let textLength: UInt32
        let textRecordCount: UInt16
        let encryptionType: UInt16
    }

    private struct MOBIHeader {
        let headerLength: UInt32
        let encoding: UInt32
        let fullNameOffset: UInt32
        let fullNameLength: UInt32
        let hasEXTH: Bool
    }

    private struct EXTHMetadata {
        var title: String?
        var author: String?
    }

    private struct ParsedChapter: Sendable {
        let title: String
        let index: Int
        let content: String
        let htmlContent: String
    }

    static func parseBook(at url: URL) throws -> MOBIRenderedBook {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? Int, fileSize > maxFileSize {
            throw MOBIParserError.malformedHeader("File too large (\(fileSize / 1_000_000) MB, limit is \(maxFileSize / 1_000_000) MB)")
        }

        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.count > 78 else {
            throw MOBIParserError.invalidFile
        }

        let pdb = try parsePDBHeader(data)
        guard pdb.recordCount > 0 else {
            throw MOBIParserError.invalidFile
        }

        let record0Start = pdb.recordOffsets[0]
        let record0End = pdb.recordCount > 1 ? pdb.recordOffsets[1] : data.count
        let record0 = data.subdata(in: record0Start..<record0End)

        let palmDoc = try parsePalmDocHeader(record0)
        let mobi = try parseMOBIHeader(record0)

        guard palmDoc.encryptionType == 0 else {
            throw MOBIParserError.unsupportedEncryption
        }

        let textRecordCount = Int(palmDoc.textRecordCount)
        guard textRecordCount > 0 else {
            throw MOBIParserError.noTextContent
        }

        let encoding: String.Encoding = mobi.encoding == 65001 ? .utf8 : .windowsCP1252
        let expectedTextSize = Int(palmDoc.textLength)
        var htmlParts: [String] = []

        for index in 1...textRecordCount {
            guard index < pdb.recordOffsets.count else { break }
            let start = pdb.recordOffsets[index]
            let end = (index + 1) < pdb.recordOffsets.count ? pdb.recordOffsets[index + 1] : data.count
            guard start < end, end <= data.count else { continue }

            let recordData = data.subdata(in: start..<end)
            let decompressed: Data
            switch palmDoc.compressionType {
            case 1:
                decompressed = recordData
            case 2:
                decompressed = decompressPalmDoc(recordData, maxOutputSize: expectedTextSize + 4096)
            case huffCdicCompression:
                throw MOBIParserError.unsupportedCompression(palmDoc.compressionType)
            default:
                throw MOBIParserError.unsupportedCompression(palmDoc.compressionType)
            }

            if let text = String(data: decompressed, encoding: encoding) {
                htmlParts.append(text)
            }
        }

        let fullHTML = htmlParts.joined()
        guard !fullHTML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MOBIParserError.noTextContent
        }

        let exth = parseEXTHHeader(record0, mobi: mobi)
        let title = exth.title
            ?? extractMOBITitle(record0, mobi: mobi, encoding: encoding)
            ?? url.deletingPathExtension().lastPathComponent

        let parsedChapters = splitIntoChapters(html: fullHTML, bookTitle: title)
        guard !parsedChapters.isEmpty else {
            throw MOBIParserError.noTextContent
        }

        let renderedChapters = parsedChapters.map(renderedChapter(from:))
        return MOBIRenderedBook(
            title: title,
            author: exth.author,
            chapters: renderedChapters
        )
    }

    private static func renderedChapter(from chapter: ParsedChapter) -> MOBIRenderedChapter {
        let rootTargetID = "mobi-chapter-root-\(chapter.index)"
        let documentHTML = ensureRevealRoot(
            in: ensureHTMLDocument(chapter.htmlContent),
            rootTargetID: rootTargetID
        )
        let policy = HTMLRenderPolicy.default
        let sanitizedHTML = HTMLRenderSupport.sanitize(
            documentHTML,
            policy: policy
        )

        return MOBIRenderedChapter(
            id: "mobi-chapter-\(chapter.index)",
            index: chapter.index,
            title: chapter.title,
            text: chapter.content,
            rootTargetID: rootTargetID,
            renderedDocument: HTMLRenderDocument(
                source: documentHTML,
                sanitizedHTML: sanitizedHTML,
                limitations: [
                    HTMLRenderLimitation.scriptsBlocked,
                    HTMLRenderLimitation.remoteBlocked,
                ]
            )
        )
    }

    private static func ensureRevealRoot(
        in html: String,
        rootTargetID: String
    ) -> String {
        let nsHTML = html as NSString
        let fullRange = NSRange(location: 0, length: nsHTML.length)
        guard let match = MOBIHTMLRegex.body.firstMatch(in: html, range: fullRange),
              match.numberOfRanges == 3 else {
            return """
            <html>
            <body><div id="\(rootTargetID)">\(html)</div></body>
            </html>
            """
        }

        let bodyAttributes = nsHTML.substring(with: match.range(at: 1))
        let bodyInnerHTML = nsHTML.substring(with: match.range(at: 2))
        return """
        <html>
        <body\(bodyAttributes)><div id="\(rootTargetID)">\(bodyInnerHTML)</div></body>
        </html>
        """
    }

    private static func parsePDBHeader(_ data: Data) throws -> PDBHeader {
        let nameData = data.subdata(in: 0..<32)
        let name = String(data: nameData, encoding: .utf8)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0")) ?? "Untitled"

        guard data.count >= 78 else {
            throw MOBIParserError.invalidFile
        }

        let recordCount = Int(data.readUInt16BE(at: 76))
        let tableEnd = 78 + recordCount * 8
        guard data.count >= tableEnd else {
            throw MOBIParserError.malformedHeader("Record table extends past end of file")
        }

        var offsets: [Int] = []
        for i in 0..<recordCount {
            let entryOffset = 78 + i * 8
            let recordOffset = Int(data.readUInt32BE(at: entryOffset))
            guard recordOffset <= data.count else {
                throw MOBIParserError.malformedHeader("Record \(i) offset \(recordOffset) exceeds file size \(data.count)")
            }
            offsets.append(recordOffset)
        }

        return PDBHeader(name: name, recordCount: recordCount, recordOffsets: offsets)
    }

    private static func parsePalmDocHeader(_ record0: Data) throws -> PalmDocHeader {
        guard record0.count >= 16 else {
            throw MOBIParserError.malformedHeader("Record 0 too short for PalmDOC header")
        }

        return PalmDocHeader(
            compressionType: record0.readUInt16BE(at: 0),
            textLength: record0.readUInt32BE(at: 4),
            textRecordCount: record0.readUInt16BE(at: 8),
            encryptionType: record0.readUInt16BE(at: 12)
        )
    }

    private static func parseMOBIHeader(_ record0: Data) throws -> MOBIHeader {
        let mobiStart = 16
        guard record0.count >= mobiStart + 132 else {
            throw MOBIParserError.malformedHeader("Record 0 too short for MOBI header")
        }

        let identifier = String(data: record0.subdata(in: mobiStart..<mobiStart + 4), encoding: .ascii) ?? ""
        guard identifier == "MOBI" else {
            throw MOBIParserError.invalidFile
        }

        let headerLength = record0.readUInt32BE(at: mobiStart + 4)
        let encoding = record0.readUInt32BE(at: mobiStart + 12)
        let fullNameOffset = record0.count >= mobiStart + 92 ? record0.readUInt32BE(at: mobiStart + 84) : 0
        let fullNameLength = record0.count >= mobiStart + 92 ? record0.readUInt32BE(at: mobiStart + 88) : 0
        let exthFlags = record0.count >= mobiStart + 132 ? record0.readUInt32BE(at: mobiStart + 128) : 0

        return MOBIHeader(
            headerLength: headerLength,
            encoding: encoding,
            fullNameOffset: fullNameOffset,
            fullNameLength: fullNameLength,
            hasEXTH: (exthFlags & 0x40) != 0
        )
    }

    private static func extractMOBITitle(
        _ record0: Data,
        mobi: MOBIHeader,
        encoding: String.Encoding
    ) -> String? {
        let offset = Int(mobi.fullNameOffset)
        let length = Int(mobi.fullNameLength)
        guard offset > 0, length > 0, offset + length <= record0.count else {
            return nil
        }
        return String(data: record0.subdata(in: offset..<offset + length), encoding: encoding)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseEXTHHeader(
        _ record0: Data,
        mobi: MOBIHeader
    ) -> EXTHMetadata {
        guard mobi.hasEXTH else {
            return EXTHMetadata()
        }

        let exthStart = 16 + Int(mobi.headerLength)
        guard record0.count >= exthStart + 12 else {
            return EXTHMetadata()
        }

        let exthID = String(data: record0.subdata(in: exthStart..<exthStart + 4), encoding: .ascii) ?? ""
        guard exthID == "EXTH" else {
            return EXTHMetadata()
        }

        let recordCount = min(Int(record0.readUInt32BE(at: exthStart + 8)), 1000)
        let encoding: String.Encoding = mobi.encoding == 65001 ? .utf8 : .windowsCP1252
        var metadata = EXTHMetadata()
        var offset = exthStart + 12

        for _ in 0..<recordCount {
            guard offset + 8 <= record0.count else { break }
            let recordType = record0.readUInt32BE(at: offset)
            let recordLength = Int(record0.readUInt32BE(at: offset + 4))
            guard recordLength >= 8, offset + recordLength <= record0.count else {
                offset += max(recordLength, 8)
                continue
            }

            let valueData = record0.subdata(in: (offset + 8)..<(offset + recordLength))
            switch recordType {
            case 100:
                metadata.author = String(data: valueData, encoding: encoding)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            case 503:
                metadata.title = String(data: valueData, encoding: encoding)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            default:
                break
            }

            offset += recordLength
        }

        return metadata
    }

    private static func decompressPalmDoc(
        _ input: Data,
        maxOutputSize: Int
    ) -> Data {
        let bytes = [UInt8](input)
        var output = [UInt8]()
        output.reserveCapacity(min(input.count * 2, maxOutputSize))
        var i = 0

        while i < bytes.count, output.count < maxOutputSize {
            let byte = bytes[i]
            i += 1

            if byte == 0x00 {
                output.append(byte)
            } else if byte <= 0x08 {
                let count = Int(byte)
                let end = min(i + count, bytes.count)
                output.append(contentsOf: bytes[i..<end])
                i = end
            } else if byte <= 0x7F {
                output.append(byte)
            } else if byte <= 0xBF {
                guard i < bytes.count else { break }
                let nextByte = bytes[i]
                i += 1

                let distance = ((Int(byte) << 8) | Int(nextByte)) >> 3 & 0x7FF
                let length = (Int(nextByte) & 0x07) + 3
                guard distance > 0 else { continue }

                for _ in 0..<length {
                    let srcIndex = output.count - distance
                    if srcIndex >= 0 && srcIndex < output.count {
                        output.append(output[srcIndex])
                    }
                }
            } else {
                output.append(0x20)
                output.append(byte ^ 0x80)
            }
        }

        return Data(output)
    }

    private static func splitIntoChapters(
        html: String,
        bookTitle: String
    ) -> [ParsedChapter] {
        var chapters: [ParsedChapter] = []
        let nsHTML = html as NSString
        let fullRange = NSRange(location: 0, length: nsHTML.length)

        var splitPoints: [Int] = [0]
        let pageBreakMatches = pageBreakRegex.matches(in: html, range: fullRange)
        let headingMatches = headingBreakRegex.matches(in: html, range: fullRange)
        let matches = pageBreakMatches.isEmpty ? headingMatches : pageBreakMatches
        for match in matches.prefix(5000) {
            splitPoints.append(match.range.location)
        }
        splitPoints = Array(Set(splitPoints)).sorted()

        if splitPoints.count <= 1 {
            let plainText = html.strippingHTMLTags()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !plainText.isEmpty else { return [] }
            return [
                ParsedChapter(
                    title: bookTitle,
                    index: 0,
                    content: plainText,
                    htmlContent: html
                ),
            ]
        }

        for (index, splitIndex) in splitPoints.enumerated() {
            let endIndex = (index + 1) < splitPoints.count ? splitPoints[index + 1] : nsHTML.length
            guard splitIndex < endIndex else { continue }

            let chapterHTML = nsHTML.substring(with: NSRange(location: splitIndex, length: endIndex - splitIndex))
            let plainText = chapterHTML.strippingHTMLTags()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !plainText.isEmpty else { continue }

            chapters.append(
                ParsedChapter(
                    title: extractChapterTitle(from: chapterHTML)
                        ?? MOBIRendererLocalization.fallbackChapterTitle(chapters.count + 1),
                    index: chapters.count,
                    content: plainText,
                    htmlContent: chapterHTML
                )
            )
        }

        if chapters.isEmpty {
            let plainText = html.strippingHTMLTags()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !plainText.isEmpty else { return [] }
            chapters.append(
                ParsedChapter(
                    title: bookTitle,
                    index: 0,
                    content: plainText,
                    htmlContent: html
                )
            )
        }

        return chapters
    }

    private static func extractChapterTitle(from html: String) -> String? {
        for tag in ["h1", "h2", "h3"] {
            if let start = html.range(of: "<\(tag)", options: .caseInsensitive),
               let closeAngle = html.range(of: ">", range: start.upperBound..<html.endIndex),
               let end = html.range(of: "</\(tag)>", options: .caseInsensitive, range: closeAngle.upperBound..<html.endIndex) {
                let heading = String(html[closeAngle.upperBound..<end.lowerBound])
                    .strippingHTMLTags()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !heading.isEmpty && heading.count <= 120 {
                    return heading
                }
            }
        }
        return nil
    }

    private static func ensureHTMLDocument(_ html: String) -> String {
        if html.range(of: "<html", options: .caseInsensitive) != nil {
            return html
        }

        if html.range(of: "<body", options: .caseInsensitive) != nil {
            return "<html>\(html)</html>"
        }

        return """
        <html>
        <body>\(html)</body>
        </html>
        """
    }
}

public enum MOBIParserError: Error, LocalizedError {
    case invalidFile
    case unsupportedCompression(UInt16)
    case unsupportedEncryption
    case noTextContent
    case malformedHeader(String)

    public var errorDescription: String? {
        switch self {
        case .invalidFile:
            MOBIRendererLocalization.invalidFileError
        case .unsupportedCompression(let type):
            MOBIRendererLocalization.unsupportedCompressionError(type: type)
        case .unsupportedEncryption:
            MOBIRendererLocalization.unsupportedEncryptionError
        case .noTextContent:
            MOBIRendererLocalization.noTextContentError
        case .malformedHeader(let detail):
            MOBIRendererLocalization.malformedHeaderError(detail: detail)
        }
    }
}

private extension Data {
    func readUInt16BE(at offset: Int) -> UInt16 {
        guard offset + 2 <= count else { return 0 }
        return (UInt16(self[offset]) << 8) | UInt16(self[offset + 1])
    }

    func readUInt32BE(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        return (UInt32(self[offset]) << 24)
            | (UInt32(self[offset + 1]) << 16)
            | (UInt32(self[offset + 2]) << 8)
            | UInt32(self[offset + 3])
    }
}

private extension String {
    func strippingHTMLTags() -> String {
        var text = self
        text = replace(regex: MOBIHTMLRegex.styleScriptBlock, in: text, with: "")
        text = replace(regex: MOBIHTMLRegex.blockOpeningTag, in: text, with: "\n")
        text = replace(regex: MOBIHTMLRegex.blockClosingTag, in: text, with: "\n")
        text = replace(regex: MOBIHTMLRegex.lineBreakTag, in: text, with: "\n")
        text = replace(regex: MOBIHTMLRegex.imageTag, in: text, with: "\u{FFFC}")
        text = replace(regex: MOBIHTMLRegex.svgImageTag, in: text, with: "\u{FFFC}")
        text = replace(regex: MOBIHTMLRegex.htmlTag, in: text, with: "")
        text = decodingHTMLEntities()
        text = replace(regex: MOBIHTMLRegex.horizontalWhitespace, in: text, with: " ")
        text = replace(regex: MOBIHTMLRegex.repeatedBlankLines, in: text, with: "\n\n")
        return text
    }

    private func decodingHTMLEntities() -> String {
        var decoded = self
        let namedEntities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&nbsp;", " "),
            ("&#160;", " "),
        ]

        for (entity, value) in namedEntities {
            decoded = decoded.replacingOccurrences(of: entity, with: value)
        }

        decoded = decodeNumericEntities(in: decoded, regex: MOBIHTMLRegex.decimalEntity, radix: 10)
        decoded = decodeNumericEntities(in: decoded, regex: MOBIHTMLRegex.hexadecimalEntity, radix: 16)
        return decoded
    }

    private func decodeNumericEntities(
        in text: String,
        regex: NSRegularExpression,
        radix: Int
    ) -> String {
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else {
            return text
        }

        let mutableText = NSMutableString(string: text)
        for match in matches.reversed() {
            let valueText = nsText.substring(with: match.range(at: 1))
            guard let scalarValue = UInt32(valueText, radix: radix),
                  let scalar = UnicodeScalar(scalarValue) else {
                continue
            }
            mutableText.replaceCharacters(in: match.range, with: String(Character(scalar)))
        }

        return mutableText as String
    }

    private func replace(regex: NSRegularExpression, in text: String, with replacement: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }
}

import Compression
import Foundation

enum ZipArchiveError: LocalizedError {
    case missingEndOfCentralDirectory
    case invalidCentralDirectory
    case unsupportedCompressionMethod(UInt16)
    case invalidEntry(String)
    case decompressionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingEndOfCentralDirectory:
            return "没有找到有效的 ZIP 文件结构。"
        case .invalidCentralDirectory:
            return "ZIP 文件目录损坏。"
        case .unsupportedCompressionMethod(let method):
            return "ZIP 中包含暂不支持的压缩方式：\(method)。"
        case .invalidEntry(let name):
            return "ZIP 中包含无效文件：\(name)。"
        case .decompressionFailed(let name):
            return "解压失败：\(name)。"
        }
    }
}

struct ZipArchiveReader {
    struct Entry {
        let name: String
        let compressionMethod: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int

        var isDirectory: Bool {
            name.hasSuffix("/")
        }
    }

    private let data: Data

    init(data: Data) {
        self.data = data
    }

    func extractImages(to destinationDirectory: URL) throws -> [URL] {
        let entries = try readEntries()
        var extractedURLs: [URL] = []
        let fileManager = FileManager.default

        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        for entry in entries where !entry.isDirectory && Self.isImagePath(entry.name) {
            let outputURL = try safeOutputURL(for: entry.name, in: destinationDirectory)
            try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let fileData = try extract(entry)
            try fileData.write(to: outputURL, options: [.atomic])
            extractedURLs.append(outputURL)
        }

        return extractedURLs
    }

    private func readEntries() throws -> [Entry] {
        let eocdOffset = try findEndOfCentralDirectory()
        let entryCount = Int(try readUInt16(at: eocdOffset + 10))
        let centralDirectoryOffset = Int(try readUInt32(at: eocdOffset + 16))
        var offset = centralDirectoryOffset
        var entries: [Entry] = []

        for _ in 0..<entryCount {
            guard try readUInt32(at: offset) == 0x02014b50 else {
                throw ZipArchiveError.invalidCentralDirectory
            }

            let compressionMethod = try readUInt16(at: offset + 10)
            let compressedSize = Int(try readUInt32(at: offset + 20))
            let uncompressedSize = Int(try readUInt32(at: offset + 24))
            let nameLength = Int(try readUInt16(at: offset + 28))
            let extraLength = Int(try readUInt16(at: offset + 30))
            let commentLength = Int(try readUInt16(at: offset + 32))
            let localHeaderOffset = Int(try readUInt32(at: offset + 42))
            let nameStart = offset + 46
            let nameEnd = nameStart + nameLength

            guard data.indices.contains(nameStart), nameEnd <= data.count,
                  let name = String(data: data[nameStart..<nameEnd], encoding: .utf8) else {
                throw ZipArchiveError.invalidCentralDirectory
            }

            entries.append(
                Entry(
                    name: name,
                    compressionMethod: compressionMethod,
                    compressedSize: compressedSize,
                    uncompressedSize: uncompressedSize,
                    localHeaderOffset: localHeaderOffset
                )
            )

            offset = nameEnd + extraLength + commentLength
        }

        return entries
    }

    private func extract(_ entry: Entry) throws -> Data {
        let offset = entry.localHeaderOffset
        guard try readUInt32(at: offset) == 0x04034b50 else {
            throw ZipArchiveError.invalidEntry(entry.name)
        }

        let nameLength = Int(try readUInt16(at: offset + 26))
        let extraLength = Int(try readUInt16(at: offset + 28))
        let compressedStart = offset + 30 + nameLength + extraLength
        let compressedEnd = compressedStart + entry.compressedSize
        guard data.indices.contains(compressedStart), compressedEnd <= data.count else {
            throw ZipArchiveError.invalidEntry(entry.name)
        }

        let compressedData = Data(data[compressedStart..<compressedEnd])
        switch entry.compressionMethod {
        case 0:
            return compressedData
        case 8:
            return try inflate(compressedData, expectedSize: entry.uncompressedSize, name: entry.name)
        default:
            throw ZipArchiveError.unsupportedCompressionMethod(entry.compressionMethod)
        }
    }

    private func inflate(_ compressedData: Data, expectedSize: Int, name: String) throws -> Data {
        guard expectedSize >= 0 else {
            throw ZipArchiveError.decompressionFailed(name)
        }

        let decoded = compressedData.withUnsafeBytes { sourceBuffer -> Data? in
            guard let sourceAddress = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
            var output = Data(count: expectedSize)
            let decodedCount = output.withUnsafeMutableBytes { destinationBuffer in
                guard let destinationAddress = destinationBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_decode_buffer(
                    destinationAddress,
                    expectedSize,
                    sourceAddress,
                    compressedData.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
            guard decodedCount == expectedSize else { return nil }
            return output
        }

        guard let decoded else {
            throw ZipArchiveError.decompressionFailed(name)
        }
        return decoded
    }

    private func safeOutputURL(for entryName: String, in destinationDirectory: URL) throws -> URL {
        let normalizedName = entryName.replacingOccurrences(of: "\\", with: "/")
        let components = normalizedName.split(separator: "/").map(String.init)
        guard !components.isEmpty,
              !components.contains(".."),
              !normalizedName.hasPrefix("/") else {
            throw ZipArchiveError.invalidEntry(entryName)
        }

        return components.reduce(destinationDirectory) { partialURL, component in
            partialURL.appendingPathComponent(component, isDirectory: false)
        }
    }

    private func findEndOfCentralDirectory() throws -> Int {
        let signature: [UInt8] = [0x50, 0x4b, 0x05, 0x06]
        let bytes = [UInt8](data)
        let minimumOffset = max(0, bytes.count - 65_557)
        guard bytes.count >= 22 else { throw ZipArchiveError.missingEndOfCentralDirectory }

        var offset = bytes.count - 22
        while offset >= minimumOffset {
            if Array(bytes[offset..<(offset + 4)]) == signature {
                return offset
            }
            offset -= 1
        }

        throw ZipArchiveError.missingEndOfCentralDirectory
    }

    private func readUInt16(at offset: Int) throws -> UInt16 {
        guard offset >= 0, offset + 2 <= data.count else { throw ZipArchiveError.invalidCentralDirectory }
        return data[offset..<offset + 2].enumerated().reduce(UInt16(0)) { result, pair in
            result | (UInt16(pair.element) << UInt16(pair.offset * 8))
        }
    }

    private func readUInt32(at offset: Int) throws -> UInt32 {
        guard offset >= 0, offset + 4 <= data.count else { throw ZipArchiveError.invalidCentralDirectory }
        return data[offset..<offset + 4].enumerated().reduce(UInt32(0)) { result, pair in
            result | (UInt32(pair.element) << UInt32(pair.offset * 8))
        }
    }

    private static func isImagePath(_ path: String) -> Bool {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "heif", "webp"].contains(ext)
    }
}

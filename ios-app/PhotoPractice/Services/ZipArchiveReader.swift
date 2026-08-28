import Foundation
import ZIPFoundation

enum ZipArchiveError: LocalizedError {
    case invalidArchive
    case invalidEntry(String)

    var errorDescription: String? {
        switch self {
        case .invalidArchive:
            return "没有找到有效的 ZIP 文件结构。"
        case .invalidEntry(let name):
            return "ZIP 中包含无效文件：\(name)。"
        }
    }
}

struct ZipArchiveReader {
    private let archiveURL: URL

    init(archiveURL: URL) {
        self.archiveURL = archiveURL
    }

    func extractImages(to destinationDirectory: URL) throws -> [URL] {
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw ZipArchiveError.invalidArchive
        }

        let fileManager = FileManager.default
        var extractedURLs: [URL] = []
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        for entry in archive where entry.type == .file && Self.isImagePath(entry.path) {
            let outputURL = try safeOutputURL(for: entry.path, in: destinationDirectory)
            try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            _ = try archive.extract(entry, to: outputURL)
            extractedURLs.append(outputURL)
        }

        return extractedURLs
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

    private static func isImagePath(_ path: String) -> Bool {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "heif", "webp"].contains(ext)
    }
}

import Foundation
import UIKit

enum PhotoLibraryError: LocalizedError {
    case missingManifest
    case missingImage(String)
    case noImagesInArchive

    var errorDescription: String? {
        switch self {
        case .missingManifest:
            return "没有找到图库清单。"
        case .missingImage(let path):
            return "没有找到图片：\(path)。"
        case .noImagesInArchive:
            return "压缩包里没有找到支持的图片。"
        }
    }
}

final class PhotoLibrary {
    private let resourceRoot = "PhotoLibrary"
    private let importedRootName = "ImportedPhotoLibrary"
    private let imageCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    init() {
        imageCache.countLimit = 120
        imageCache.totalCostLimit = 96 * 1024 * 1024
    }

    func loadPhotos() throws -> [PhotoItem] {
        if let importedManifestURL, fileManager.fileExists(atPath: importedManifestURL.path) {
            return try loadManifest(from: importedManifestURL)
        }

        guard let url = bundledManifestURL else {
            throw PhotoLibraryError.missingManifest
        }

        return try loadManifest(from: url)
    }

    func image(for photo: PhotoItem) -> UIImage? {
        let cacheKey = photo.id as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        guard let url = imageURL(for: photo) else { return nil }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }

        let pixelCount = image.size.width * image.scale * image.size.height * image.scale
        imageCache.setObject(image, forKey: cacheKey, cost: Int(pixelCount * 4))
        return image
    }

    func importArchive(from archiveURL: URL) throws -> Int {
        let archiveData = try Data(contentsOf: archiveURL)
        let destinationURL = try importedRootURL()
        let stagingURL = destinationURL.deletingLastPathComponent()
            .appendingPathComponent("\(importedRootName)-staging", isDirectory: true)

        if fileManager.fileExists(atPath: stagingURL.path) {
            try fileManager.removeItem(at: stagingURL)
        }
        try fileManager.createDirectory(at: stagingURL, withIntermediateDirectories: true)

        _ = try ZipArchiveReader(data: archiveData).extractImages(to: stagingURL)
        let photos = try scanImportedPhotos(in: stagingURL)
        guard !photos.isEmpty else {
            throw PhotoLibraryError.noImagesInArchive
        }

        let manifest = PhotoManifest(photos: photos)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: stagingURL.appendingPathComponent("photo-manifest.json"), options: [.atomic])

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: stagingURL, to: destinationURL)
        clearCache()
        return photos.count
    }

    func removeImportedLibrary() throws {
        let destinationURL = try importedRootURL()
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        clearCache()
    }

    func hasImportedLibrary() -> Bool {
        guard let importedManifestURL else { return false }
        return fileManager.fileExists(atPath: importedManifestURL.path)
    }

    func clearCache() {
        imageCache.removeAllObjects()
    }

    private func loadManifest(from url: URL) throws -> [PhotoItem] {
        let data = try Data(contentsOf: url)
        let manifest = try JSONDecoder().decode(PhotoManifest.self, from: data)
        return manifest.photos
    }

    private func scanImportedPhotos(in rootURL: URL) throws -> [PhotoItem] {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let imageURLs = enumerator.compactMap { item -> URL? in
            guard let url = item as? URL, Self.isImageURL(url) else { return nil }
            return url
        }

        return imageURLs
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            .map { photoItem(for: $0, rootURL: rootURL) }
    }

    private func photoItem(for imageURL: URL, rootURL: URL) -> PhotoItem {
        let relativePath = imageURL.path
            .replacingOccurrences(of: rootURL.path + "/", with: "")
            .replacingOccurrences(of: "\\", with: "/")
        let components = relativePath.split(separator: "/").map(String.init)
        let filename = imageURL.lastPathComponent
        let category = inferredCategory(from: components)
        let year = components.compactMap { component -> Int? in
            let digits = component.filter(\.isNumber)
            guard digits.count == 4 else { return nil }
            return Int(digits)
        }.first

        return PhotoItem(
            filename: filename,
            path: relativePath,
            title: imageURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " "),
            photographer: nil,
            source: components.first,
            website: nil,
            category: category,
            description: nil,
            tags: category.map { [$0] },
            year: year,
            award: nil,
            country: nil,
            location: nil,
            cameraInfo: nil,
            originalImageURL: nil
        )
    }

    private func inferredCategory(from components: [String]) -> String? {
        guard components.count > 1 else { return nil }
        if let photosIndex = components.firstIndex(where: { $0.lowercased() == "photos" }),
           components.indices.contains(photosIndex + 1) {
            return components[photosIndex + 1]
        }
        return components.dropLast().last
    }

    private func imageURL(for photo: PhotoItem) -> URL? {
        if let importedURL = try? importedRootURL().appendingPathComponent(photo.path),
           fileManager.fileExists(atPath: importedURL.path) {
            return importedURL
        }

        return Bundle.main.resourceURL?
            .appendingPathComponent(resourceRoot, isDirectory: true)
            .appendingPathComponent(photo.path, isDirectory: false)
    }

    private var bundledManifestURL: URL? {
        Bundle.main.url(forResource: "photo-manifest", withExtension: "json", subdirectory: resourceRoot)
    }

    private var importedManifestURL: URL? {
        try? importedRootURL().appendingPathComponent("photo-manifest.json")
    }

    private func importedRootURL() throws -> URL {
        let supportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return supportURL.appendingPathComponent(importedRootName, isDirectory: true)
    }

    private static func isImageURL(_ url: URL) -> Bool {
        ["jpg", "jpeg", "png", "heic", "heif", "webp"].contains(url.pathExtension.lowercased())
    }
}

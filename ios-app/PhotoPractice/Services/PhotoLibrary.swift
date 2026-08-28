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
    private let metadataRoot = "PhotoMetadata"
    private let importedRootName = "ImportedPhotoLibrary"
    private let imageCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private var importedImageIndex: [String: URL]?

    init() {
        imageCache.countLimit = 120
        imageCache.totalCostLimit = 96 * 1024 * 1024
    }

    func loadPhotos() throws -> [PhotoItem] {
        if let importedManifestURL, fileManager.fileExists(atPath: importedManifestURL.path) {
            return enrichImportedPhotos(try loadManifest(from: importedManifestURL))
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

        guard let url = imageURL(for: photo), let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        let pixelCount = image.size.width * image.scale * image.size.height * image.scale
        imageCache.setObject(image, forKey: cacheKey, cost: Int(pixelCount * 4))
        return image
    }

    func imageLoadStatus(for photo: PhotoItem) -> String {
        guard let url = imageURL(for: photo) else {
            return "未找到文件：\(photo.path)"
        }
        guard fileManager.fileExists(atPath: url.path) else {
            return "文件不存在：\(url.lastPathComponent)"
        }
        guard UIImage(contentsOfFile: url.path) != nil else {
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            let size = (attributes?[.size] as? NSNumber)?.intValue ?? 0
            return "图片无法解码：\(url.lastPathComponent)，\(size) bytes"
        }
        return "OK"
    }

    func importArchive(from archiveURL: URL) throws -> Int {
        let destinationURL = try importedRootURL()
        let stagingURL = destinationURL.deletingLastPathComponent()
            .appendingPathComponent("\(importedRootName)-staging", isDirectory: true)

        if fileManager.fileExists(atPath: stagingURL.path) {
            try fileManager.removeItem(at: stagingURL)
        }
        try fileManager.createDirectory(at: stagingURL, withIntermediateDirectories: true)

        _ = try ZipArchiveReader(archiveURL: archiveURL).extractLibraryFiles(to: stagingURL)
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
        importedImageIndex = nil
    }

    private func loadManifest(from url: URL) throws -> [PhotoItem] {
        let data = try Data(contentsOf: url)
        let manifest = try JSONDecoder().decode(PhotoManifest.self, from: data)
        return manifest.photos
    }

    private func scanImportedPhotos(in rootURL: URL) throws -> [PhotoItem] {
        let metadata = try importedMetadataByPath(in: rootURL)
        return allImageURLs(under: rootURL)
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            .map { photoItem(for: $0, rootURL: rootURL, metadata: metadata) }
    }

    private func allImageURLs(under rootURL: URL) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item -> URL? in
            guard let url = item as? URL, Self.isImageURL(url) else { return nil }
            return url
        }
    }

    private func photoItem(for imageURL: URL, rootURL: URL, metadata: [String: PhotoItem]) -> PhotoItem {
        let relativePath = relativePath(for: imageURL, under: rootURL)
        if let manifestPhoto = metadataMatch(forPath: relativePath, filename: imageURL.lastPathComponent, in: metadata) {
            return mergedPhoto(localPath: relativePath, localFilename: imageURL.lastPathComponent, metadata: manifestPhoto)
        }

        let components = relativePath.split(separator: "/").map(String.init)
        let filename = imageURL.lastPathComponent
        let category = inferredCategory(from: components)
        let year = inferredYear(from: components)

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

    private func importedMetadataByPath(in rootURL: URL) throws -> [String: PhotoItem] {
        var metadata: [String: PhotoItem] = [:]
        let decoder = JSONDecoder()

        for manifestURL in manifestURLs(under: rootURL) {
            guard let manifest = try? decoder.decode(PhotoManifest.self, from: Data(contentsOf: manifestURL)) else {
                continue
            }

            let manifestFolder = relativePath(for: manifestURL.deletingLastPathComponent(), under: rootURL)
            for photo in manifest.photos {
                let localPath = localPath(for: photo.path, manifestFolder: manifestFolder)
                let enriched = mergedPhoto(localPath: localPath, localFilename: photo.filename, metadata: photo)
                index(photo: enriched, localPath: localPath, in: &metadata)
            }
        }

        if let bundledMetadataManifestURL,
           let manifest = try? decoder.decode(PhotoManifest.self, from: Data(contentsOf: bundledMetadataManifestURL)) {
            for photo in manifest.photos {
                index(photo: photo, localPath: photo.path, in: &metadata)
            }
        }

        return metadata
    }

    private func enrichImportedPhotos(_ photos: [PhotoItem]) -> [PhotoItem] {
        guard let metadata = try? importedMetadataByPath(in: importedRootURL()) else {
            return photos
        }

        return photos.map { photo in
            guard let manifestPhoto = metadataMatch(forPath: photo.path, filename: photo.filename, in: metadata) else {
                return photo
            }
            return mergedPhoto(localPath: photo.path, localFilename: photo.filename, metadata: manifestPhoto)
        }
    }

    private func index(photo: PhotoItem, localPath: String, in metadata: inout [String: PhotoItem]) {
        metadata[normalizedPath(localPath)] = photo
        metadata[metadataLookupPath(for: localPath)] = photo
        metadata[normalizedFilename(photo.filename)] = photo
        metadata[normalizedFilename(URL(fileURLWithPath: localPath).lastPathComponent)] = photo
    }

    private func metadataMatch(forPath path: String, filename: String, in metadata: [String: PhotoItem]) -> PhotoItem? {
        metadata[normalizedPath(path)]
            ?? metadata[metadataLookupPath(for: path)]
            ?? metadata[normalizedFilename(filename)]
            ?? metadata[normalizedFilename(URL(fileURLWithPath: path).lastPathComponent)]
    }

    private func mergedPhoto(localPath: String, localFilename: String, metadata: PhotoItem) -> PhotoItem {
        PhotoItem(
            filename: localFilename,
            path: localPath,
            title: metadata.title,
            photographer: metadata.photographer,
            source: metadata.source,
            website: metadata.website,
            category: metadata.category,
            description: metadata.description,
            tags: metadata.tags,
            year: metadata.year,
            award: metadata.award,
            country: metadata.country,
            location: metadata.location,
            cameraInfo: metadata.cameraInfo,
            originalImageURL: metadata.originalImageURL
        )
    }

    private func manifestURLs(under rootURL: URL) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item -> URL? in
            guard let url = item as? URL else { return nil }
            let name = url.lastPathComponent.lowercased()
            return (name == "manifest.json" || name == "photo-manifest.json") ? url : nil
        }
    }

    private func localPath(for manifestPath: String, manifestFolder: String) -> String {
        let normalizedManifestPath = normalizedPath(manifestPath)
        if manifestFolder.isEmpty || normalizedManifestPath.hasPrefix(manifestFolder + "/") {
            return normalizedManifestPath
        }
        return normalizedPath(manifestFolder + "/" + normalizedManifestPath)
    }

    private func metadataLookupPath(for path: String) -> String {
        let normalized = normalizedPath(path)
        if let photosRange = normalized.range(of: "/photos/") {
            return String(normalized[photosRange.upperBound...])
        }
        return URL(fileURLWithPath: normalized).lastPathComponent
    }

    private func relativePath(for imageURL: URL, under rootURL: URL) -> String {
        let rootPath = normalizedPath(rootURL.path(percentEncoded: false))
        let imagePath = normalizedPath(imageURL.path(percentEncoded: false))
        if imagePath.hasPrefix(rootPath + "/") {
            return String(imagePath.dropFirst(rootPath.count + 1))
        }
        return imageURL.lastPathComponent
    }

    private func inferredCategory(from components: [String]) -> String? {
        guard components.count > 1 else { return nil }
        if let photosIndex = components.firstIndex(where: { $0.lowercased() == "photos" }),
           components.indices.contains(photosIndex + 1) {
            return components[photosIndex + 1]
        }
        return components.dropLast().last
    }

    private func inferredYear(from components: [String]) -> Int? {
        components.dropLast().compactMap { component -> Int? in
            let digits = component.filter(\.isNumber)
            guard digits.count == 4, let year = Int(digits), (1900...2100).contains(year) else {
                return nil
            }
            return year
        }.first
    }

    private func imageURL(for photo: PhotoItem) -> URL? {
        if let importedRootURL = try? importedRootURL(),
           let importedURL = existingImageURL(for: photo, under: importedRootURL) {
            return importedURL
        }

        guard let bundledRootURL = Bundle.main.resourceURL?
            .appendingPathComponent(resourceRoot, isDirectory: true)
        else {
            return nil
        }
        return existingImageURL(for: photo, under: bundledRootURL)
    }

    private func existingImageURL(for photo: PhotoItem, under rootURL: URL) -> URL? {
        for candidate in candidateRelativePaths(for: photo) {
            if let url = try? url(forRelativePath: candidate, under: rootURL), fileManager.fileExists(atPath: url.path) {
                return url
            }
        }

        if rootURL.lastPathComponent == importedRootName {
            return indexedImportedImageURL(for: photo, under: rootURL)
        }

        return nil
    }

    private func indexedImportedImageURL(for photo: PhotoItem, under rootURL: URL) -> URL? {
        if importedImageIndex == nil {
            importedImageIndex = buildImageIndex(under: rootURL)
        }

        let filename = normalizedFilename(photo.filename)
        if let url = importedImageIndex?[filename] {
            return url
        }

        let pathFilename = normalizedFilename(URL(fileURLWithPath: photo.path).lastPathComponent)
        return importedImageIndex?[pathFilename]
    }

    private func buildImageIndex(under rootURL: URL) -> [String: URL] {
        var index: [String: URL] = [:]
        for url in allImageURLs(under: rootURL) {
            index[normalizedFilename(url.lastPathComponent)] = url
        }
        return index
    }

    private func candidateRelativePaths(for photo: PhotoItem) -> [String] {
        let normalized = normalizedPath(photo.path.removingPercentEncoding ?? photo.path)
        var candidates: [String] = [normalized]

        if let range = normalized.range(of: "\(importedRootName)-staging/") {
            candidates.append(String(normalized[range.upperBound...]))
        }

        if let range = normalized.range(of: "\(importedRootName)/") {
            candidates.append(String(normalized[range.upperBound...]))
        }

        if normalized.hasPrefix("/") {
            candidates.append(URL(fileURLWithPath: normalized).lastPathComponent)
        }

        candidates.append(photo.filename)
        candidates.append(URL(fileURLWithPath: normalized).lastPathComponent)

        var seen: Set<String> = []
        return candidates.filter { candidate in
            guard !candidate.isEmpty, !seen.contains(candidate) else { return false }
            seen.insert(candidate)
            return true
        }
    }

    private func url(forRelativePath relativePath: String, under rootURL: URL) throws -> URL {
        let components = normalizedPath(relativePath)
            .split(separator: "/")
            .map(String.init)
        guard !components.isEmpty, !components.contains("..") else {
            throw PhotoLibraryError.missingImage(relativePath)
        }

        return components.reduce(rootURL) { url, component in
            url.appendingPathComponent(component, isDirectory: false)
        }
    }

    private func normalizedPath(_ path: String) -> String {
        path
            .replacingOccurrences(of: "\\", with: "/")
            .replacingOccurrences(of: "//", with: "/")
    }

    private func normalizedFilename(_ filename: String) -> String {
        (filename.removingPercentEncoding ?? filename).precomposedStringWithCanonicalMapping.lowercased()
    }

    private var bundledManifestURL: URL? {
        Bundle.main.url(forResource: "photo-manifest", withExtension: "json", subdirectory: resourceRoot)
    }

    private var bundledMetadataManifestURL: URL? {
        Bundle.main.url(forResource: "ippawards-metadata", withExtension: "json", subdirectory: metadataRoot) ?? Bundle.main.url(forResource: "ippawards-metadata", withExtension: "json")
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

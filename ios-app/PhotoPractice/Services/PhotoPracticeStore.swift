import Foundation
import UIKit

@MainActor
final class PhotoPracticeStore: ObservableObject {
    @Published private(set) var photos: [PhotoItem] = []
    @Published var progress = PhotoProgress() {
        didSet { saveProgress() }
    }
    @Published var selectedTab: AppTab = .today
    @Published var currentIndex: Int = 0 {
        didSet { rememberCurrentPhoto() }
    }
    @Published var noteText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var loadingMessage: String = "正在载入离线图库..."
    @Published private(set) var usesImportedLibrary: Bool = false

    private let library = PhotoLibrary()
    private let progressKey = "photo-practice-ios-progress-v1"

    var currentPhoto: PhotoItem? {
        guard photos.indices.contains(currentIndex) else { return nil }
        return photos[currentIndex]
    }

    var seenCount: Int { progress.viewedPhotoIDs.count }
    var favoriteCount: Int { progress.favoritePhotoIDs.count }
    var unseenCount: Int { max(photos.count - seenCount, 0) }

    var todayRecords: [ViewRecord] {
        records(on: Date())
    }

    init() {
        loadProgress()
    }

    func loadCatalog() async {
        do {
            let loaded = try library.loadPhotos()
            usesImportedLibrary = library.hasImportedLibrary()
            photos = loaded
            restoreCurrentIndex()
            loadingMessage = loaded.isEmpty ? "图库为空，请在设置中导入图片压缩包。" : ""
        } catch {
            usesImportedLibrary = false
            loadingMessage = "没有找到图库，请在设置中导入图片压缩包。"
        }
    }

    func image(for photo: PhotoItem) -> UIImage? {
        library.image(for: photo)
    }

    func importPhotoArchive(from url: URL) throws -> Int {
        let count = try library.importArchive(from: url)
        usesImportedLibrary = true
        photos = try library.loadPhotos()
        restoreCurrentIndex()
        loadingMessage = photos.isEmpty ? "图库为空，请重新导入图片压缩包。" : ""
        return count
    }

    func removeImportedLibrary() throws {
        try library.removeImportedLibrary()
        usesImportedLibrary = false
        photos = (try? library.loadPhotos()) ?? []
        restoreCurrentIndex()
        loadingMessage = photos.isEmpty ? "图库已移除，请在设置中导入图片压缩包。" : ""
    }

    func startSession(random: Bool = false) {
        guard !photos.isEmpty else { return }
        if random {
            currentIndex = Int.random(in: photos.indices)
        } else if progress.unseenFirst, let index = photos.firstIndex(where: { !progress.viewedPhotoIDs.contains($0.id) }) {
            currentIndex = index
        } else {
            restoreCurrentIndex()
        }
        selectedTab = .viewer
    }

    func showNext() {
        guard !photos.isEmpty else { return }
        currentIndex = (currentIndex + 1) % photos.count
        clearObservation()
    }

    func showPrevious() {
        guard !photos.isEmpty else { return }
        currentIndex = (currentIndex - 1 + photos.count) % photos.count
        clearObservation()
    }

    func markCurrent(favorite: Bool) {
        guard let photo = currentPhoto else { return }
        progress.viewedPhotoIDs.insert(photo.id)
        if favorite {
            progress.favoritePhotoIDs.insert(photo.id)
        }

        let note = composedNote()
        let record = ViewRecord(
            id: UUID(),
            photoID: photo.id,
            title: photo.title ?? photo.filename,
            photographer: photo.photographer ?? "",
            source: photo.source ?? "",
            favorite: favorite,
            note: note,
            viewedAt: Date()
        )
        progress.records.insert(record, at: 0)
        clearObservation()

        if progress.unseenFirst, let next = photos.firstIndex(where: { !progress.viewedPhotoIDs.contains($0.id) }) {
            currentIndex = next
        } else {
            showNext()
        }
    }

    func toggleFavorite(_ photo: PhotoItem) {
        if progress.favoritePhotoIDs.contains(photo.id) {
            progress.favoritePhotoIDs.remove(photo.id)
        } else {
            progress.favoritePhotoIDs.insert(photo.id)
        }
    }

    func records(on date: Date) -> [ViewRecord] {
        progress.records.filter { Calendar.current.isDate($0.viewedAt, inSameDayAs: date) }
    }

    func records(inMonthContaining date: Date) -> [ViewRecord] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: date) else { return [] }
        return progress.records.filter { interval.contains($0.viewedAt) }
    }

    func photo(withID id: String) -> PhotoItem? {
        photos.first { $0.id == id }
    }

    func clearRecords() {
        progress.records = []
        progress.viewedPhotoIDs = []
        progress.favoritePhotoIDs = []
    }

    func clearImageCache() {
        library.clearCache()
    }

    func exportProgressData() throws -> Data {
        let backup = PhotoProgressBackup(
            schemaVersion: 1,
            exportedAt: Date(),
            appName: "PhotoPractice",
            progress: progress
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    func importProgressData(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let backup = try? decoder.decode(PhotoProgressBackup.self, from: data) {
            progress = backup.progress
        } else {
            progress = try decoder.decode(PhotoProgress.self, from: data)
        }

        restoreCurrentIndex()
        clearObservation()
    }

    private func rememberCurrentPhoto() {
        progress.currentPhotoID = currentPhoto?.id
    }

    private func restoreCurrentIndex() {
        guard let id = progress.currentPhotoID,
              let index = photos.firstIndex(where: { $0.id == id }) else {
            currentIndex = 0
            return
        }
        currentIndex = index
    }

    private func clearObservation() {
        noteText = ""
        selectedTags = []
    }

    private func composedNote() -> String {
        let tagText = selectedTags.sorted().map { "#\($0)" }.joined(separator: " ")
        if tagText.isEmpty { return noteText.trimmingCharacters(in: .whitespacesAndNewlines) }
        if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return tagText }
        return "\(tagText) \(noteText.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            progress = try decoder.decode(PhotoProgress.self, from: data)
        } catch {
            progress = PhotoProgress()
        }
    }

    private func saveProgress() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(progress)
            UserDefaults.standard.set(data, forKey: progressKey)
        } catch {
            assertionFailure("Failed to save progress")
        }
    }
}

enum AppTab: Hashable {
    case today
    case viewer
    case library
    case review
    case settings
}

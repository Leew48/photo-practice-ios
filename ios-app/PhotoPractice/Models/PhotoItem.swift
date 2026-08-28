import Foundation

struct PhotoManifest: Codable {
    let photos: [PhotoItem]
}

struct PhotoItem: Codable, Identifiable, Hashable {
    var id: String { path }

    let filename: String
    let path: String
    let title: String?
    let photographer: String?
    let source: String?
    let website: String?
    let category: String?
    let description: String?
    let tags: [String]?
    let year: Int?
    let award: String?
    let country: String?
    let location: String?
    let cameraInfo: String?
    let originalImageURL: String?

    enum CodingKeys: String, CodingKey {
        case filename
        case path
        case title
        case photographer
        case source
        case website
        case category
        case description
        case tags
        case year
        case award
        case country
        case location
        case cameraInfo = "camera_info"
        case originalImageURL = "original_image_url"
    }
}

struct PhotoProgress: Codable, Equatable {
    var viewedPhotoIDs: Set<String> = []
    var favoritePhotoIDs: Set<String> = []
    var records: [ViewRecord] = []
    var currentPhotoID: String?
    var dailyTarget: Int = 100
    var unseenFirst: Bool = true
}

struct ViewRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let photoID: String
    let title: String
    let photographer: String
    let source: String
    let favorite: Bool
    let note: String
    let viewedAt: Date
}

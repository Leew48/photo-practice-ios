import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    @State private var searchText = ""
    @State private var selectedYear: Int?
    @State private var selectedCategory: String?
    @State private var selectedAward: String?
    @State private var showingFavoritesOnly = false

    private var filteredPhotos: [PhotoItem] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.photos.filter { photo in
            let matchesSearch = keyword.isEmpty
                || (photo.title ?? "").lowercased().contains(keyword)
                || (photo.photographer ?? "").lowercased().contains(keyword)
                || (photo.category ?? "").lowercased().contains(keyword)
                || (photo.award ?? "").lowercased().contains(keyword)
                || String(photo.year ?? 0).contains(keyword)
            let matchesYear = selectedYear == nil || photo.year == selectedYear
            let matchesCategory = selectedCategory == nil || photo.category == selectedCategory
            let matchesAward = selectedAward == nil || photo.award == selectedAward
            let matchesFavorite = !showingFavoritesOnly || store.progress.favoritePhotoIDs.contains(photo.id)
            return matchesSearch && matchesYear && matchesCategory && matchesAward && matchesFavorite
        }
    }

    private var yearOptions: [Int] {
        Array(Set(store.photos.compactMap(\.year))).sorted(by: >)
    }

    private var categoryOptions: [String] {
        uniqueOptions(store.photos.map(\.category))
    }

    private var awardOptions: [String] {
        uniqueOptions(store.photos.map(\.award))
    }

    private var hasActiveFilters: Bool {
        selectedYear != nil || selectedCategory != nil || selectedAward != nil || showingFavoritesOnly
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        StatTile(label: "总数", value: "\(store.photos.count)")
                        StatTile(label: "筛选", value: "\(filteredPhotos.count)")
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("筛选") {
                    Toggle("只看收藏", isOn: $showingFavoritesOnly)

                    Picker("年份", selection: $selectedYear) {
                        Text("全部年份").tag(Int?.none)
                        ForEach(yearOptions, id: \.self) { year in
                            Text(String(year)).tag(Int?.some(year))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("分类", selection: $selectedCategory) {
                        Text("全部分类").tag(String?.none)
                        ForEach(categoryOptions, id: \.self) { category in
                            Text(category).tag(String?.some(category))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("奖项", selection: $selectedAward) {
                        Text("全部奖项").tag(String?.none)
                        ForEach(awardOptions, id: \.self) { award in
                            Text(award).tag(String?.some(award))
                        }
                    }
                    .pickerStyle(.menu)

                    if hasActiveFilters {
                        Button {
                            selectedYear = nil
                            selectedCategory = nil
                            selectedAward = nil
                            showingFavoritesOnly = false
                        } label: {
                            Label("清除筛选", systemImage: "xmark.circle")
                        }
                    }
                }

                Section("照片") {
                    if filteredPhotos.isEmpty {
                        Text("没有匹配的照片。")
                            .foregroundStyle(Color.practiceMuted)
                    } else {
                        ForEach(filteredPhotos.prefix(500)) { photo in
                            Button {
                                if let index = store.photos.firstIndex(of: photo) {
                                    store.currentIndex = index
                                    store.selectedTab = .viewer
                                }
                            } label: {
                                PhotoListRow(photo: photo)
                            }
                        }

                        if filteredPhotos.count > 500 {
                            Text("当前显示前 500 张，可继续缩小筛选范围。")
                                .font(.footnote)
                                .foregroundStyle(Color.practiceMuted)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索年份、分类、奖项、摄影人")
            .navigationTitle("图库")
        }
    }

    private func uniqueOptions(_ values: [String?]) -> [String] {
        Array(Set(values.compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }))
        .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}

struct PhotoListRow: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    let photo: PhotoItem

    var body: some View {
        HStack(spacing: 12) {
            Thumbnail(photo: photo)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(photo.title ?? photo.filename)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("\(photo.photographer ?? "未知摄影人") · \(photo.year.map(String.init) ?? "未知年份")")
                    .font(.caption)
                    .foregroundStyle(Color.practiceMuted)
                HStack(spacing: 8) {
                    Text(store.progress.viewedPhotoIDs.contains(photo.id) ? "已看" : "未看")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(store.progress.viewedPhotoIDs.contains(photo.id) ? Color.practiceClay : Color.practiceForest)
                    if store.progress.favoritePhotoIDs.contains(photo.id) {
                        Image(systemName: "star.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.practiceGold)
                    }
                }
            }
        }
        .foregroundStyle(Color.practiceInk)
    }
}

struct Thumbnail: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    let photo: PhotoItem

    var body: some View {
        if let image = store.image(for: photo) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.practiceForest.opacity(0.18))
        }
    }
}

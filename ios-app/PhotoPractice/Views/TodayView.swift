import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    @State private var backgroundPhotoID: String?

    private var progressRatio: Double {
        guard store.progress.dailyTarget > 0 else { return 0 }
        return min(Double(store.todayRecords.count) / Double(store.progress.dailyTarget), 1)
    }

    private var backgroundPhoto: PhotoItem? {
        if let backgroundPhotoID, let photo = store.photo(withID: backgroundPhotoID) {
            return photo
        }
        return store.photos.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    backgroundLayer(size: proxy.size)

                    ScrollView {
                        VStack(spacing: 12) {
                            hero
                            actions
                            stats
                            todayRecords
                        }
                        .frame(maxWidth: proxy.size.width - 32)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 92)
                    }
                    .scrollIndicators(.hidden)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .navigationTitle("看图计划")
            .onAppear(perform: pickBackgroundPhotoIfNeeded)
            .onChange(of: store.photos.count) { _, _ in
                pickBackgroundPhoto(force: true)
            }
        }
    }

    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            Color.practicePaper

            if let backgroundPhoto, let image = store.image(for: backgroundPhoto) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .blur(radius: 1.2)
                    .overlay(Color.practiceInk.opacity(0.28))
                    .saturation(0.82)
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.practicePaper.opacity(0.72),
                    Color.practicePaper.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: size.width, height: size.height)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var hero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.practiceMint.opacity(0.38), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: progressRatio)
                    .stroke(Color.practicePeach, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(store.todayRecords.count)")
                        .font(.system(size: 28, weight: .bold))
                    Text("/ \(store.progress.dailyTarget)")
                        .font(.caption)
                        .opacity(0.72)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text("今天")
                    .font(.caption.weight(.semibold))
                    .opacity(0.76)
                Text(todayMessage)
                    .font(.headline.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text("离线图库 \(store.photos.count) 张")
                    .font(.caption)
                    .opacity(0.74)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color.practiceInk)
        .padding(14)
        .background(Color.practiceMint.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.56), lineWidth: 1)
        )
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                store.startSession()
            } label: {
                Label("看未看照片", systemImage: "play.fill")
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryPracticeButtonStyle())

            Button {
                store.startSession(random: true)
                pickBackgroundPhoto(force: true)
            } label: {
                Label("随机一张", systemImage: "shuffle")
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryPracticeButtonStyle())
        }
    }

    private var stats: some View {
        HStack(spacing: 8) {
            StatTile(label: "未看", value: "\(store.unseenCount)")
            StatTile(label: "已看", value: "\(store.seenCount)")
            StatTile(label: "收藏", value: "\(store.favoriteCount)")
        }
    }

    private var todayRecords: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日看过")
                .font(.headline)
                .foregroundStyle(Color.practiceInk)

            if store.todayRecords.isEmpty {
                EmptyPanel(text: store.loadingMessage.isEmpty ? "今天还没有记录，先看一张好照片。" : store.loadingMessage)
            } else {
                ForEach(store.todayRecords.prefix(20)) { record in
                    RecordRow(record: record)
                }
            }
        }
    }

    private var todayMessage: String {
        let count = store.todayRecords.count
        let target = store.progress.dailyTarget
        if store.photos.isEmpty { return "先准备离线图库。" }
        if count >= target { return "今天的训练完成了。" }
        if count > 0 { return "接着看，别让进度丢了。" }
        return "先看一张好照片。"
    }

    private func pickBackgroundPhotoIfNeeded() {
        guard backgroundPhotoID == nil else { return }
        pickBackgroundPhoto(force: true)
    }

    private func pickBackgroundPhoto(force: Bool = false) {
        guard force || backgroundPhotoID == nil else { return }
        backgroundPhotoID = store.photos.randomElement()?.id
    }
}

struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.practiceMuted)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.practiceInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.52), lineWidth: 1)
        )
    }
}

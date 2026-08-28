import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: PhotoPracticeStore

    private var progressRatio: Double {
        guard store.progress.dailyTarget > 0 else { return 0 }
        return min(Double(store.todayRecords.count) / Double(store.progress.dailyTarget), 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero
                    actions
                    stats
                    todayRecords
                }
                .padding()
            }
            .background(Color.practicePaper.ignoresSafeArea())
            .navigationTitle("看图计划")
        }
    }

    private var hero: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.24), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progressRatio)
                    .stroke(Color.practiceGold, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(store.todayRecords.count)")
                        .font(.system(size: 34, weight: .bold))
                    Text("/ \(store.progress.dailyTarget)")
                        .font(.footnote)
                        .opacity(0.72)
                }
            }
            .frame(width: 118, height: 118)

            VStack(alignment: .leading, spacing: 8) {
                Text("今天")
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.72)
                Text(todayMessage)
                    .font(.title3.weight(.bold))
                Text("离线图库 \(store.photos.count) 张")
                    .font(.footnote)
                    .opacity(0.74)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(colors: [.practiceForest, Color(red: 0.22, green: 0.49, blue: 0.57)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                store.startSession()
            } label: {
                Label("看未看照片", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryPracticeButtonStyle())

            Button {
                store.startSession(random: true)
            } label: {
                Label("随机一张", systemImage: "shuffle")
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
}

struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.practiceMuted)
            Text(value)
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

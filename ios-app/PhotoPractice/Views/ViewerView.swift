import SwiftUI

struct ViewerView: View {
    @EnvironmentObject private var store: PhotoPracticeStore

    private let observationTags = ["构图", "光线", "色彩", "主体", "瞬间", "层次"]

    var body: some View {
        NavigationStack {
            ScrollView {
                if let photo = store.currentPhoto {
                    VStack(spacing: 14) {
                        PhotoStage(photo: photo)
                        metadata(for: photo)
                        observationPanel
                    }
                    .padding()
                } else {
                    EmptyPanel(text: store.loadingMessage.isEmpty ? "离线图库里还没有照片。" : store.loadingMessage)
                        .padding()
                }
            }
            .background(Color.practicePaper.ignoresSafeArea())
            .navigationTitle("看图")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func metadata(for photo: PhotoItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(store.currentIndex + 1) / \(store.photos.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.practiceClay)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(photo.title ?? photo.filename)
                .font(.title3.weight(.bold))

            InfoGrid(items: [
                ("摄影人", photo.photographer ?? "未知"),
                ("年份", photo.year.map(String.init) ?? "未知"),
                ("分类", photo.category ?? "未分类"),
                ("奖项", photo.award ?? "无")
            ])

            if let camera = photo.cameraInfo, !camera.isEmpty {
                Text(camera)
                    .font(.footnote)
                    .foregroundStyle(Color.practiceMuted)
            }
        }
        .panelStyle()
    }

    private var observationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("一句观察")
                .font(.headline)

            TextEditor(text: $store.noteText)
                .frame(minHeight: 84)
                .padding(8)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(observationTags, id: \.self) { tag in
                    Button {
                        if store.selectedTags.contains(tag) {
                            store.selectedTags.remove(tag)
                        } else {
                            store.selectedTags.insert(tag)
                        }
                    } label: {
                        Text(tag)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TagButtonStyle(selected: store.selectedTags.contains(tag)))
                }
            }

            HStack(spacing: 8) {
                Button {
                    store.showPrevious()
                } label: {
                    Label("上一张", systemImage: "chevron.left")
                }
                .buttonStyle(SecondaryPracticeButtonStyle())

                Button {
                    store.showNext()
                } label: {
                    Label("稍后", systemImage: "forward")
                }
                .buttonStyle(SecondaryPracticeButtonStyle())
            }

            HStack(spacing: 8) {
                Button {
                    store.markCurrent(favorite: false)
                } label: {
                    Label("已看", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPracticeButtonStyle())

                Button {
                    store.markCurrent(favorite: true)
                } label: {
                    Label("收藏", systemImage: "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryPracticeButtonStyle())
            }
        }
        .panelStyle()
    }
}

struct PhotoStage: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    let photo: PhotoItem

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.09, blue: 0.12)

            if let image = store.image(for: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 8) {
                    Text("图片未找到")
                        .font(.headline)
                    Text(store.imageLoadStatus(for: photo))
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 420)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}


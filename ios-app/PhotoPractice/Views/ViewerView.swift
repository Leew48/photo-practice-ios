import SwiftUI

struct ViewerView: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    @FocusState private var isNoteFocused: Bool

    private let observationTags = ["构图", "光线", "色彩", "主体", "瞬间", "层次"]

    var body: some View {
        NavigationStack {
            Group {
                if let photo = store.currentPhoto {
                    VStack(spacing: 12) {
                        PhotoStage(photo: photo)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ScrollView {
                            VStack(spacing: 14) {
                                metadata(for: photo)
                                observationPanel
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 96)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                } else {
                    ScrollView {
                        EmptyPanel(text: store.loadingMessage.isEmpty ? "离线图库里还没有照片。" : store.loadingMessage)
                            .padding()
                    }
                }
            }
            .background(Color.practicePaper.ignoresSafeArea())
            .navigationTitle("看图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isNoteFocused = false
                    }
                }
            }
        }
    }

    private func metadata(for photo: PhotoItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(store.currentIndex + 1) / \(store.photos.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.practicePeach)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(photo.title ?? photo.filename)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.practiceInk)
                .fixedSize(horizontal: false, vertical: true)

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
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Color.practiceInk)
        .panelStyle()
    }

    private var observationPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("一句观察")
                    .font(.headline)
                    .foregroundStyle(Color.practiceInk)

                Spacer()

                if isNoteFocused {
                    Button("完成") {
                        isNoteFocused = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.practiceAqua)
                }
            }

            TextEditor(text: $store.noteText)
                .focused($isNoteFocused)
                .frame(minHeight: 84)
                .padding(8)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color.practiceInk)
                .background(Color.white.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.practiceAqua.opacity(isNoteFocused ? 0.44 : 0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(observationTags, id: \.self) { tag in
                    Button {
                        isNoteFocused = false
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
                    isNoteFocused = false
                    store.showPrevious()
                } label: {
                    Label("上一张", systemImage: "chevron.left")
                }
                .buttonStyle(SecondaryPracticeButtonStyle())

                Button {
                    isNoteFocused = false
                    store.showNext()
                } label: {
                    Label("稍后", systemImage: "forward")
                }
                .buttonStyle(SecondaryPracticeButtonStyle())
            }

            HStack(spacing: 8) {
                Button {
                    isNoteFocused = false
                    store.markCurrent(favorite: false)
                } label: {
                    Label("已看", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPracticeButtonStyle())

                Button {
                    isNoteFocused = false
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
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

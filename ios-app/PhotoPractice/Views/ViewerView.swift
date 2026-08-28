import SwiftUI
import UIKit

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

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.practiceLilac.opacity(0.18))

                if store.noteText.isEmpty {
                    Text("写下这一张照片最打动你的地方")
                        .font(.subheadline)
                        .foregroundStyle(Color.practiceMuted.opacity(0.72))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $store.noteText)
                    .focused($isNoteFocused)
                    .frame(minHeight: 84)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.practiceInk)
                    .background(Color.clear)
                    .tint(Color.practiceAqua)
            }
            .background(Color.white.opacity(0.62))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.practiceAqua.opacity(isNoteFocused ? 0.48 : 0.18), lineWidth: 1)
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
    @State private var isShowingFullscreen = false

    let photo: PhotoItem

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.09, blue: 0.12)

            if let image = store.image(for: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .contentShape(Rectangle())
                    .onLongPressGesture {
                        isShowingFullscreen = true
                    }
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
        .fullScreenCover(isPresented: $isShowingFullscreen) {
            if let image = store.image(for: photo) {
                FullscreenPhotoView(image: image, title: photo.title ?? photo.filename)
            }
        }
    }
}

struct FullscreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let title: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            ZoomableImage(image: image)
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.48))
                    .clipShape(Circle())
            }
            .accessibilityLabel("关闭")
            .padding(.top, 18)
            .padding(.trailing, 16)
        }
        .statusBarHidden(true)
    }
}

struct ZoomableImage: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 6
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let point = gesture.location(in: imageView)
                let zoomScale = min(scrollView.maximumZoomScale, 3)
                let width = scrollView.bounds.width / zoomScale
                let height = scrollView.bounds.height / zoomScale
                let originX = point.x - width / 2
                let originY = point.y - height / 2
                scrollView.zoom(to: CGRect(x: originX, y: originY, width: width, height: height), animated: true)
            }
        }
    }
}

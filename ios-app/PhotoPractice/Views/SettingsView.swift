import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var photoPracticeZip: UTType {
        UTType(filenameExtension: "zip") ?? .archive
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    @AppStorage("photo-practice-ios-has-seen-onboarding-v1") private var hasSeenOnboarding = false
    @State private var confirmClear = false
    @State private var confirmRemoveLibrary = false
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var showingPhotoArchiveImporter = false
    @State private var exportDocument = ProgressBackupDocument()
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("计划") {
                    Stepper("每日目标 \(store.progress.dailyTarget) 张", value: $store.progress.dailyTarget, in: 1...500)
                    Toggle("优先显示未看照片", isOn: $store.progress.unseenFirst)
                }

                Section("图片包") {
                    LabeledContent("图库来源", value: store.usesImportedLibrary ? "已导入压缩包" : "App 内置样例")
                    LabeledContent("照片数量", value: "\(store.photos.count)")

                    Button {
                        showingPhotoArchiveImporter = true
                    } label: {
                        Label("导入图片压缩包", systemImage: "archivebox")
                    }

                    if store.usesImportedLibrary {
                        Button(role: .destructive) {
                            confirmRemoveLibrary = true
                        } label: {
                            Label("移除导入图库", systemImage: "xmark.bin")
                        }
                    }

                    Text("压缩包内可以按文件夹分类，例如：人像、风景、建筑。导入后 App 会自动按文件夹建立分类。")
                        .font(.footnote)
                        .foregroundStyle(Color.practiceMuted)
                }

                Section("观看数据") {
                    LabeledContent("已看", value: "\(store.seenCount)")
                    LabeledContent("收藏", value: "\(store.favoriteCount)")
                    Button {
                        store.clearImageCache()
                        statusMessage = "图片缓存已清理。"
                    } label: {
                        Label("清理图片缓存", systemImage: "memorychip")
                    }
                }

                Section("进度备份") {
                    Button {
                        exportProgress()
                    } label: {
                        Label("导出进度", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Label("导入进度", systemImage: "square.and.arrow.down")
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.practiceMuted)
                    }
                }

                Section("首次说明") {
                    Button {
                        hasSeenOnboarding = false
                        statusMessage = "下次启动会显示首次说明。"
                    } label: {
                        Label("下次启动显示说明", systemImage: "info.circle")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Label("清空观看记录", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("设置")
            .confirmationDialog("清空所有观看记录？照片会保留。", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空记录", role: .destructive) {
                    store.clearRecords()
                    statusMessage = "观看记录已清空。"
                }
            }
            .confirmationDialog("移除导入的图库？观看记录会保留。", isPresented: $confirmRemoveLibrary, titleVisibility: .visible) {
                Button("移除导入图库", role: .destructive) {
                    removeImportedLibrary()
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "photo-practice-progress"
            ) { result in
                switch result {
                case .success:
                    statusMessage = "进度备份已导出。"
                case .failure(let error):
                    statusMessage = "导出失败：\(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importProgress(from: url)
                case .failure(let error):
                    statusMessage = "导入失败：\(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $showingPhotoArchiveImporter,
                allowedContentTypes: [.photoPracticeZip],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importPhotoArchive(from: url)
                case .failure(let error):
                    statusMessage = "导入图片包失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func exportProgress() {
        do {
            exportDocument = ProgressBackupDocument(data: try store.exportProgressData())
            showingExporter = true
        } catch {
            statusMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func importProgress(from url: URL) {
        do {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            try store.importProgressData(data)
            statusMessage = "进度已导入。"
        } catch {
            statusMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    private func importPhotoArchive(from url: URL) {
        do {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let count = try store.importPhotoArchive(from: url)
            statusMessage = "图片包已导入：\(count) 张。"
        } catch {
            statusMessage = "导入图片包失败：\(error.localizedDescription)"
        }
    }

    private func removeImportedLibrary() {
        do {
            try store.removeImportedLibrary()
            statusMessage = "导入图库已移除。"
        } catch {
            statusMessage = "移除失败：\(error.localizedDescription)"
        }
    }
}

import SwiftUI

@main
struct PhotoPracticeApp: App {
    @StateObject private var store = PhotoPracticeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    await store.loadCatalog()
                }
        }
    }
}

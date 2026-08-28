import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    @AppStorage("photo-practice-ios-has-seen-onboarding-v1") private var hasSeenOnboarding = false
    @State private var showingOnboarding = false

    var body: some View {
        TabView(selection: $store.selectedTab) {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "circle.dashed.inset.filled")
                }
                .tag(AppTab.today)

            ViewerView()
                .tabItem {
                    Label("看图", systemImage: "photo")
                }
                .tag(AppTab.viewer)

            LibraryView()
                .tabItem {
                    Label("图库", systemImage: "square.grid.2x2")
                }
                .tag(AppTab.library)

            ReviewView()
                .tabItem {
                    Label("回顾", systemImage: "calendar")
                }
                .tag(AppTab.review)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(.practiceForest)
        .onAppear {
            if !hasSeenOnboarding {
                showingOnboarding = true
            }
        }
        .sheet(isPresented: $showingOnboarding, onDismiss: markOnboardingSeen) {
            OnboardingView {
                markOnboardingSeen()
                showingOnboarding = false
            }
        }
    }

    private func markOnboardingSeen() {
        hasSeenOnboarding = true
    }
}

struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("看图计划")
                            .font(.largeTitle.weight(.bold))
                        Text("离线 iPhone 版")
                            .font(.headline)
                            .foregroundStyle(Color.practiceMuted)
                    }
                    .padding(.top, 8)

                    OnboardingRow(
                        icon: "iphone",
                        title: "离线使用",
                        text: "6078 张 IPPAWARDS 照片会随 App 一起安装，不需要家里的电脑在线。"
                    )

                    OnboardingRow(
                        icon: "checklist",
                        title: "每日训练",
                        text: "从今日页开始看图，记录观察、收藏喜欢的作品，进度会保存在本机。"
                    )

                    OnboardingRow(
                        icon: "signature",
                        title: "安装边界",
                        text: "真机安装仍需要 Apple 签名；没有 Mac 时可以用 Codemagic 先做云端构建。"
                    )

                    Button {
                        onDone()
                    } label: {
                        Label("开始看图", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryPracticeButtonStyle())
                    .padding(.top, 4)
                }
                .padding()
            }
            .background(Color.practicePaper.ignoresSafeArea())
            .navigationTitle("欢迎")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OnboardingRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.practiceClay)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.practiceMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension Color {
    static let practiceInk = Color(red: 0.07, green: 0.09, blue: 0.09)
    static let practiceMuted = Color(red: 0.38, green: 0.44, blue: 0.43)
    static let practicePaper = Color(red: 0.98, green: 0.98, blue: 0.95)
    static let practiceForest = Color(red: 0.07, green: 0.23, blue: 0.20)
    static let practiceClay = Color(red: 0.71, green: 0.36, blue: 0.23)
    static let practiceGold = Color(red: 0.83, green: 0.66, blue: 0.25)
}

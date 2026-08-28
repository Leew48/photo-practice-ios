import SwiftUI

struct EmptyPanel: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 34))
                .foregroundStyle(Color.practiceClay)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.practiceMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct InfoGrid: View {
    let items: [(String, String)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(Color.practiceMuted)
                    Text(item.1)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
                .padding(10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct PrimaryPracticeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color.practiceForest.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SecondaryPracticeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.practiceForest)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(.white.opacity(configuration.isPressed ? 0.68 : 0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.practiceMuted.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TagButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? .white : Color.practiceForest)
            .frame(minHeight: 38)
            .background(selected ? Color.practiceForest : Color.practiceForest.opacity(configuration.isPressed ? 0.2 : 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension View {
    func panelStyle() -> some View {
        self
            .padding(16)
            .background(.white.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

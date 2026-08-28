import SwiftUI

struct EmptyPanel: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 34))
                .foregroundStyle(Color.practicePeach)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.practiceMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white.opacity(0.74))
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
                .background(Color.white.opacity(0.72))
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
            .padding(.horizontal, 12)
            .frame(minHeight: 46)
            .background(Color.practiceAqua.opacity(configuration.isPressed ? 0.78 : 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SecondaryPracticeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.practiceForest)
            .padding(.horizontal, 12)
            .frame(minHeight: 46)
            .background(Color.white.opacity(configuration.isPressed ? 0.64 : 0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.practiceAqua.opacity(0.24), lineWidth: 1)
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
            .background(selected ? Color.practiceAqua : Color.practiceMint.opacity(configuration.isPressed ? 0.55 : 0.36))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension View {
    func panelStyle() -> some View {
        self
            .padding(16)
            .background(Color.white.opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// App/Sources/Popup/ClipRowView.swift
import SwiftUI
import ClipKeepCore

struct ClipRowView: View {
    let index: Int
    let clip: Clip
    let isSelected: Bool
    let thumbsDir: URL
    let now: Date

    var body: some View {
        HStack(spacing: 9) {
            Text(index < 9 ? "\(index + 1)" : " ")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                .frame(width: 15)

            thumbnail
                .frame(width: 30, height: 22)

            Text(clip.preview)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isSelected ? .white : .primary)

            Spacer(minLength: 6)

            Text(RelativeTime.string(for: clip.lastUsedAt, now: now))
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
    }

    @ViewBuilder private var thumbnail: some View {
        switch clip.kind {
        case .text:
            Image(systemName: "text.alignleft")
                .foregroundStyle(isSelected ? .white : .secondary)
        case .image:
            if let file = clip.thumbFile,
               let img = NSImage(contentsOf: thumbsDir.appendingPathComponent(file)) {
                Image(nsImage: img).resizable().scaledToFill()
                    .frame(width: 30, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo").foregroundStyle(.secondary)
            }
        }
    }
}

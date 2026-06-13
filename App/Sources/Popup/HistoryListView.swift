// App/Sources/Popup/HistoryListView.swift
import SwiftUI
import ClipKeepCore

struct HistoryListView: View {
    @ObservedObject var model: PopupViewModel
    let thumbsDir: URL
    let onPaste: (Clip, _ autoPaste: Bool) -> Void
    let onClose: () -> Void

    @FocusState private var searchFocused: Bool
    private let now = Date()

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search clipboard…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(11)
                .focused($searchFocused)
                .onSubmit { pasteSelected(autoPaste: true) }

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(model.clips.enumerated()), id: \.element.id) { idx, clip in
                            ClipRowView(index: idx, clip: clip,
                                        isSelected: idx == model.selectedIndex,
                                        thumbsDir: thumbsDir, now: now)
                                .id(idx)
                                .onTapGesture { model.selectedIndex = idx; pasteSelected(autoPaste: true) }
                        }
                    }
                    .padding(6)
                }
                .onChange(of: model.selectedIndex) { _, new in
                    withAnimation(.linear(duration: 0.08)) { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
        .frame(width: 360, height: 420)
        .background(.regularMaterial)
        .onAppear { searchFocused = true; model.reload() }
        .onKeyPress(.downArrow) { model.moveDown(); return .handled }
        .onKeyPress(.upArrow) { model.moveUp(); return .handled }
        .onKeyPress(.escape) { onClose(); return .handled }
        .onKeyPress(keys: ["1","2","3","4","5","6","7","8","9"]) { press in
            guard press.modifiers.contains(.command), let n = Int(press.characters) else { return .ignored }
            if let clip = model.clip(forQuickKey: n) { onPaste(clip, true); onClose() }
            return .handled
        }
        .onKeyPress(.deleteForward) { deleteSelected(); return .handled }
        .onKeyPress(.delete) { deleteSelected(); return .handled }
    }

    private func pasteSelected(autoPaste: Bool) {
        if let clip = model.selectedClip { onPaste(clip, autoPaste); onClose() }
    }
    private func deleteSelected() {
        if let clip = model.selectedClip { model.delete(clip) }
    }
}

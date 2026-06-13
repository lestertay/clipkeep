// App/Sources/Popup/PopupViewModel.swift
import SwiftUI
import ClipKeepCore

@MainActor
final class PopupViewModel: ObservableObject {
    @Published var query: String = "" { didSet { reload() } }
    @Published private(set) var clips: [Clip] = []
    @Published var selectedIndex: Int = 0

    private let store: HistoryStore
    private var state = ClipListState(count: 0)

    init(store: HistoryStore) { self.store = store }

    func reload() {
        clips = (try? store.search(query, limit: 50)) ?? []
        state.updateCount(clips.count)
        selectedIndex = state.selectedIndex
    }

    func moveDown() { state.moveDown(); selectedIndex = state.selectedIndex }
    func moveUp() { state.moveUp(); selectedIndex = state.selectedIndex }

    var selectedClip: Clip? { clips.indices.contains(selectedIndex) ? clips[selectedIndex] : nil }
    func clip(forQuickKey key: Int) -> Clip? {
        guard let i = state.indexForQuickKey(key) else { return nil }
        return clips[i]
    }

    func delete(_ clip: Clip) {
        guard let id = clip.id else { return }
        _ = try? store.delete(id: id)
        reload()
    }
}

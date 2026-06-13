// Core/Tests/ClipKeepCoreTests/Support/FakePasteboard.swift
import Foundation
@testable import ClipKeepCore

final class FakePasteboard: PasteboardReading {
    var changeCount: Int = 0
    var strings: [String: String] = [:]
    var datas: [String: Data] = [:]
    private var declaredTypes: [String] = []

    func setText(_ text: String) {
        declaredTypes = [PasteboardType.utf8PlainText]
        strings[PasteboardType.utf8PlainText] = text
        changeCount += 1
    }
    func setPNG(_ data: Data) {
        declaredTypes = [PasteboardType.png]
        datas[PasteboardType.png] = data
        changeCount += 1
    }
    func setRaw(types: [String], strings: [String: String] = [:], datas: [String: Data] = [:]) {
        declaredTypes = types
        self.strings = strings
        self.datas = datas
        changeCount += 1
    }

    func types() -> [String] { declaredTypes }
    func string(forType type: String) -> String? { strings[type] }
    func data(forType type: String) -> Data? { datas[type] }
}

// App/Sources/Settings/SettingsView.swift
import SwiftUI
import KeyboardShortcuts
import ClipKeepCore

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    let onClearHistory: () -> Void

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var newExclusion = ""

    var body: some View {
        Form {
            Section("Shortcut") {
                KeyboardShortcuts.Recorder("Show history:", name: .showPopup)
            }
            Section("Retention") {
                Stepper("Keep up to \(preferences.maxCount) clips", value: bindingMaxCount, in: 50...5000, step: 50)
                Stepper("Keep for \(preferences.maxAgeDays) days", value: bindingMaxAge, in: 1...365, step: 1)
                Stepper("Image store cap: \(preferences.maxImageMB) MB", value: bindingMaxImageMB, in: 128...8192, step: 128)
                Stepper("Skip images larger than \(preferences.maxSingleImageMB) MB", value: bindingMaxSingle, in: 5...200, step: 5)
            }
            Section("Privacy") {
                Text("Passwords and other concealed/transient clips are always skipped.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(preferences.excludedBundleIDs, id: \.self) { id in
                    HStack { Text(id); Spacer(); Button("Remove") { remove(id) } }
                }
                HStack {
                    TextField("Excluded app bundle id (e.g. com.agilebits.onepassword7)", text: $newExclusion)
                    Button("Add") { addExclusion() }.disabled(newExclusion.isEmpty)
                }
            }
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in LaunchAtLogin.set(on) }
                Button("Clear History…", role: .destructive, action: onClearHistory)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 540)
    }

    private var bindingMaxCount: Binding<Int> { .init(get: { preferences.maxCount }, set: { preferences.maxCount = $0; preferences.objectWillChange.send() }) }
    private var bindingMaxAge: Binding<Int> { .init(get: { preferences.maxAgeDays }, set: { preferences.maxAgeDays = $0; preferences.objectWillChange.send() }) }
    private var bindingMaxImageMB: Binding<Int> { .init(get: { preferences.maxImageMB }, set: { preferences.maxImageMB = $0; preferences.objectWillChange.send() }) }
    private var bindingMaxSingle: Binding<Int> { .init(get: { preferences.maxSingleImageMB }, set: { preferences.maxSingleImageMB = $0; preferences.objectWillChange.send() }) }

    private func addExclusion() {
        let id = newExclusion.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        preferences.excludedBundleIDs.append(id); preferences.objectWillChange.send(); newExclusion = ""
    }
    private func remove(_ id: String) {
        preferences.excludedBundleIDs.removeAll { $0 == id }; preferences.objectWillChange.send()
    }
}

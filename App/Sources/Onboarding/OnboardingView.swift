// App/Sources/Onboarding/OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    let onGrant: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to ClipKeep").font(.title2).bold()
            Text("ClipKeep records your clipboard history so you can paste anything you copied earlier — including items copied on your iPhone via Universal Clipboard.")
            Text("To paste straight into the app you're using, ClipKeep needs **Accessibility** permission. Without it, ClipKeep still records history and copies items to your clipboard; you just paste manually.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Grant Accessibility…") { onGrant() }
                Button("Continue") { onContinue() }
            }
            Text("Summon your history any time with ⌘⇧V.").font(.footnote).foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 460)
    }
}

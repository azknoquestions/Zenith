//
//  OnboardingView.swift
//  Zenith
//
//  First-launch only: prompt to add Topstep API key before entering the app.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var apiKeyText: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            ZenithColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(ZenithColors.accent)

                    Text("Connect Topstep")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(ZenithColors.textPrimary)

                    Text("To use Zenith with your Topstep accounts, add your TopstepX API key once. Log in at topstep.com, go to Settings → API (TopstepX), and create or copy your API key. Need help? See Topstep Help: TopstepX API Access.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 32)

                ZenithTextField(title: "TopstepX API key", text: $apiKeyText, keyboardType: .asciiCapable)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(ZenithColors.negative)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                Button {
                    saveAndContinue()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(ZenithColors.background)
                        } else {
                            Text("Save and continue")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(ZenithColors.background)
                    .background(ZenithColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.accent)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveAndContinue() {
        let trimmed = apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your API key."
            return
        }

        errorMessage = nil
        isSaving = true

        session.updateTopstepApiKey(trimmed)
        session.completeOnboarding()
        isSaving = false
    }
}

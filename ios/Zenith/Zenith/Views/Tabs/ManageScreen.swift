import SwiftUI

struct ManageScreen: View {
    @EnvironmentObject private var session: SessionStore
    @State private var apiKeyText: String = ""
    @State private var didSaveKey: Bool = false

    var body: some View {
        ZStack {
            ZenithColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ZenithCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connect Topstep")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)

                            Text("Paste your TopstepX API key once. Zenith will securely reuse it to pull your accounts, risk parameters, and positions. You can regenerate this key from your Topstep dashboard at any time.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textSecondary)

                            ZenithTextField(title: "TopstepX API key", text: $apiKeyText)

                            HStack {
                                Button {
                                    session.updateTopstepApiKey(apiKeyText)
                                    didSaveKey = true
                                } label: {
                                    Text("Save key")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(ZenithColors.background)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(ZenithColors.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                if didSaveKey {
                                    Text("Saved. Your accounts will refresh automatically.")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(ZenithColors.textMuted)
                                }

                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }

                    ZenithCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Accounts")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)

                            ForEach(session.accounts) { account in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(account.name)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(ZenithColors.textPrimary)
                                        Text(account.type)
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(ZenithColors.textMuted)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(account.equity, format: .currency(code: account.currency))
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                            .foregroundColor(ZenithColors.textPrimary)
                                        if let dd = account.drawdownLimit {
                                            Text("DD \(dd, format: .currency(code: account.currency))")
                                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                                .foregroundColor(ZenithColors.textMuted)
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }

                    ZenithCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                            Text("Once connected, your equity curve, win/loss statistics, and risk metrics will be visualized here without gamified badges or streaks.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textSecondary)
                        }
                    }

                    ZenithCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Risk Settings")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                            Text("Configure daily loss limits, max position sizes, and alerts. These guardrails are designed to keep you aligned with your process, not your dopamine.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }
}


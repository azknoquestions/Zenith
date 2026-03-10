import SwiftUI

private let kSoundAlertsEnabled = "SideMenuSoundAlertsEnabled"

struct SideMenuView: View {
    @EnvironmentObject private var session: SessionStore
    @Binding var isPresented: Bool
    var onSelectTab: (ZenithTab) -> Void

    @AppStorage(kSoundAlertsEnabled) private var soundAlertsEnabled = true

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().background(ZenithColors.separator)
                accountsSection
                Divider().background(ZenithColors.separator).padding(.vertical, 8)
                accountGroup
                tradingGroup
                Divider().background(ZenithColors.separator).padding(.vertical, 8)
                soundAlertsRow
                logOutRow
                Divider().background(ZenithColors.separator).padding(.vertical, 8)
                linksSection
                Spacer()
            }
            .frame(width: 290)
            .padding(.top, 40)
            .padding(.horizontal, 16)
            .background(ZenithColors.surfaceElevated.ignoresSafeArea())

            Spacer()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Zenith")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Text("Topstep Trading")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textMuted)
        }
        .padding(.bottom, 16)
    }

    private var accountGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)

            Button {
                onSelectTab(.manage)
                isPresented = false
            } label: { menuRow(icon: "info.circle", title: "Info") }
            .buttonStyle(.plain)

            Button {
                isPresented = false
            } label: { menuRow(icon: "person.3", title: "All Accounts") }
            .buttonStyle(.plain)
            .disabled(session.accounts.isEmpty)

            Button {
                onSelectTab(.trade)
                isPresented = false
            } label: { menuRow(icon: "chart.bar", title: "Positions") }
            .buttonStyle(.plain)

            Button {
                onSelectTab(.trade)
                isPresented = false
            } label: { menuRow(icon: "doc.text", title: "Orders") }
            .buttonStyle(.plain)

            Button {
                onSelectTab(.trade)
                isPresented = false
            } label: { menuRow(icon: "arrow.left.arrow.right", title: "Trades") }
            .buttonStyle(.plain)
        }
    }

    private var tradingGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trading")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)

            Button {
                onSelectTab(.trade)
                isPresented = false
            } label: { menuRow(icon: "creditcard", title: "Order Card") }
            .buttonStyle(.plain)

            Button {
                onSelectTab(.manage)
                isPresented = false
            } label: { menuRow(icon: "shield", title: "Risk Settings") }
            .buttonStyle(.plain)

            Button {
                onSelectTab(.trade)
                isPresented = false
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ZenithColors.textSecondary)
                        .frame(width: 26)
                    Text("DOM")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textPrimary)
                    Text("Soon")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                    Spacer()
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    private var soundAlertsRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.wave.2")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(ZenithColors.textSecondary)
                .frame(width: 26)
            Text("Sound Alerts")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Spacer()
            Toggle("", isOn: $soundAlertsEnabled)
                .labelsHidden()
                .tint(ZenithColors.accent)
        }
        .padding(.vertical, 6)
    }

    private var logOutRow: some View {
        Button {
            session.disconnect()
            isPresented = false
        } label: { menuRow(icon: "rectangle.portrait.and.arrow.right", title: "Log Out") }
        .buttonStyle(.plain)
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accounts")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)

            ForEach(session.accounts) { account in
                let isActive = session.activeAccountId == account.id
                Button {
                    session.setActiveAccount(id: account.id)
                    isPresented = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                            Text(account.type)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textMuted)
                        }
                        Spacer()
                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ZenithColors.accent)
                        } else {
                            Text(account.equity, format: .currency(code: account.currency))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(ZenithColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Support & Docs")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)

            Button {
                isPresented = false
                UIApplication.shared.open(ApiConfig.Support.faq)
            } label: { menuRow(icon: "questionmark.circle", title: "FAQ") }
            .buttonStyle(.plain)

            Button {
                isPresented = false
                UIApplication.shared.open(ApiConfig.Support.tradingPrinciples)
            } label: { menuRow(icon: "book", title: "Trading principles") }
            .buttonStyle(.plain)

            Button {
                isPresented = false
                UIApplication.shared.open(ApiConfig.Support.riskDisclosures)
            } label: { menuRow(icon: "shield", title: "Risk & disclosures") }
            .buttonStyle(.plain)

            Button {
                isPresented = false
                UIApplication.shared.open(ApiConfig.Support.contactSupport)
            } label: { menuRow(icon: "envelope", title: "Contact support") }
            .buttonStyle(.plain)
        }
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(ZenithColors.textSecondary)
                .frame(width: 26)
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Spacer()
        }
        .padding(.vertical, 6)
    }
}


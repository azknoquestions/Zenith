import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject private var session: SessionStore
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().background(ZenithColors.separator)
                accountsSection
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

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accounts")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)

            ForEach(session.accounts) { account in
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
                    Text(account.equity, format: .currency(code: account.currency))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(ZenithColors.textSecondary)
                }
                .padding(.vertical, 6)
            }

            Button {
                // Account switching and management will be wired once accounts come from Topstep.
            } label: {
                Text("Manage accounts")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ZenithColors.accent)
            }
            .padding(.top, 4)
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Support & Docs")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)

            Group {
                menuRow(icon: "questionmark.circle", title: "FAQ")
                menuRow(icon: "book", title: "Trading principles")
                menuRow(icon: "shield", title: "Risk & disclosures")
                menuRow(icon: "envelope", title: "Contact support")
            }
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


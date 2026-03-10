import SwiftUI

struct ManageScreen: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var riskSettings = RiskSettingsStore()
    @State private var apiKeyText: String = ""
    @State private var usernameText: String = ""
    @State private var showKeyField: Bool = false
    @State private var testConnectionMessage: String?
    @State private var testDebugStatus: Int?
    @State private var testDebugBody: String?
    @State private var isTestingConnection: Bool = false
    @State private var performanceStats: (filledCount: Int, winCount: Int, lossCount: Int)? = nil
    @State private var performanceLoading = false
    @Binding var selectedTab: ZenithTab

    private var connectionStatusText: String {
        switch session.topstepConnectionState {
        case .idle:
            return session.topstepApiKey != nil ? "Tap \"Test connection\" to verify." : "Enter your API key and save."
        case .checking:
            return "Checking connection…"
        case .connected(let count):
            return "Connected (\(count) account\(count == 1 ? "" : "s"))"
        case .failed(let message):
            return message
        }
    }

    private var connectionStatusColor: Color {
        switch session.topstepConnectionState {
        case .idle: return ZenithColors.textMuted
        case .checking: return ZenithColors.textSecondary
        case .connected: return ZenithColors.positive
        case .failed: return ZenithColors.negative
        }
    }

    var body: some View {
        ZStack {
            ZenithColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ZenithCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Connect Topstep")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)

                            Text("Paste your TopstepX API key from topstep.com (Settings → API). If you get HTTP 401, the key or username was rejected: double-check the key and try filling in the optional Username with your Topstep account username.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textSecondary)

                            if session.topstepApiKey != nil && !showKeyField {
                                HStack {
                                    Text("Key saved")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(ZenithColors.positive)
                                    Button("Change key") {
                                        showKeyField = true
                                        apiKeyText = ""
                                        session.clearTopstepKeyForReentry()
                                    }
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(ZenithColors.accent)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            } else {
                                ZenithTextField(title: "TopstepX API key", text: $apiKeyText, keyboardType: .asciiCapable)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                            }

                            Text("Username (optional)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(ZenithColors.textMuted)
                            TextField("e.g. trader", text: $usernameText)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                                .padding(10)
                                .background(ZenithColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .onChange(of: usernameText) { _, new in
                                    session.updateTopstepUsername(new)
                                }
                                .onAppear {
                                    usernameText = session.topstepUsername ?? ""
                                }

                            HStack(spacing: 12) {
                                Button {
                                    session.updateTopstepUsername(usernameText)
                                    session.updateTopstepApiKey(apiKeyText)
                                    showKeyField = false
                                } label: {
                                    Text("Save key")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(ZenithColors.background)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(ZenithColors.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .disabled(apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && session.topstepApiKey == nil)

                                Button {
                                    Task {
                                        isTestingConnection = true
                                        testConnectionMessage = nil
                                        testDebugStatus = nil
                                        testDebugBody = nil
                                        // Use current field values when testing so a new key/username is used without having to tap Save first
                                        let keyToTest = apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        let userToTest = usernameText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        TopstepService.shared.setApiKey(keyToTest.isEmpty ? session.topstepApiKey : keyToTest)
                                        TopstepService.shared.setUsername(userToTest.isEmpty ? session.topstepUsername : userToTest)
                                        let result = await TopstepService.shared.validateConnection()
                                        testConnectionMessage = result.message
                                        testDebugStatus = TopstepService.lastDebugStatus
                                        testDebugBody = TopstepService.lastDebugBody
                                        isTestingConnection = false
                                        if result.connected {
                                            await session.loadDemoOrRemoteAccounts()
                                        }
                                    }
                                } label: {
                                    if isTestingConnection {
                                        ProgressView().scaleEffect(0.8).tint(ZenithColors.background)
                                    } else {
                                        Text("Test connection")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(ZenithColors.background)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(ZenithColors.textMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .disabled(isTestingConnection || (session.topstepApiKey == nil && apiKeyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))

                                Spacer()
                            }

                            Text(connectionStatusText)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(connectionStatusColor)
                                .lineLimit(3)

                            if let testMsg = testConnectionMessage, !testMsg.isEmpty {
                                Text(testMsg)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(ZenithColors.textSecondary)
                                    .lineLimit(4)
                            }
                            if (testDebugStatus ?? TopstepService.lastDebugStatus) != nil || !(testDebugBody ?? TopstepService.lastDebugBody ?? "").isEmpty {
                                Text("Last API response (for debugging)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(ZenithColors.textMuted)
                                if let status = testDebugStatus ?? TopstepService.lastDebugStatus {
                                    Text("HTTP \(status)")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(ZenithColors.textMuted)
                                }
                                if let body = testDebugBody ?? TopstepService.lastDebugBody, !body.isEmpty {
                                    Text(body)
                                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                                        .foregroundColor(ZenithColors.textMuted)
                                        .lineLimit(20)
                                }
                            }
                        }
                    }

                    ZenithCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Accounts")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)

                            if session.accounts.isEmpty && (session.topstepApiKey?.isEmpty == false) {
                                Text("No accounts found. Check your API key or connect to Topstep.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(ZenithColors.textSecondary)
                            } else {
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
                    }

                    ZenithCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                            if performanceLoading {
                                ProgressView().scaleEffect(0.9).tint(ZenithColors.textMuted)
                            } else if let stats = performanceStats {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Filled")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(ZenithColors.textMuted)
                                        Text("\(stats.filledCount)")
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundColor(ZenithColors.textPrimary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Wins")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(ZenithColors.textMuted)
                                        Text("\(stats.winCount)")
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundColor(ZenithColors.positive)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Losses")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(ZenithColors.textMuted)
                                        Text("\(stats.lossCount)")
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundColor(ZenithColors.negative)
                                    }
                                }
                            } else {
                                Text("Connect your account and trade to see performance metrics. View orders on the Trade tab.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(ZenithColors.textSecondary)
                                Button("Go to Trade") { selectedTab = .trade }
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(ZenithColors.accent)
                            }
                        }
                    }
                    .task {
                        await loadPerformance()
                    }

                    ZenithCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Risk Settings")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                            Text("Configure daily loss limits and max position size. These guardrails help keep you aligned with your process.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textSecondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily loss limit (USD)")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(ZenithColors.textMuted)
                                TextField("0", value: $riskSettings.dailyLossLimit, format: .number)
                                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                                    .foregroundColor(ZenithColors.textPrimary)
                                    .keyboardType(.decimalPad)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(ZenithColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Max position size (contracts)")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(ZenithColors.textMuted)
                                Stepper(value: $riskSettings.maxPositionSize, in: 1...500) {
                                    Text("\(riskSettings.maxPositionSize)")
                                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                                        .foregroundColor(ZenithColors.textPrimary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
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
    }

    private func loadPerformance() async {
        guard let accountId = session.activeAccountId else { return }
        performanceLoading = true
        defer { performanceLoading = false }
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let orders = (try? await TopstepService.shared.fetchOrders(accountId: accountId, start: start, end: Date())) ?? []
        var wins = 0
        var losses = 0
        var filled = 0
        for o in orders where o.status == 2 && o.fillVolume > 0 {
            filled += 1
            if o.side == 0 { wins += 1 } else { losses += 1 }
        }
        performanceStats = (filled, wins, losses)
    }
}


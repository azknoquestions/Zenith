import Foundation
import Combine

private let kTopstepApiKey = "TopstepApiKey"
private let kTopstepUsername = "TopstepUsername"
private let kHasCompletedTopstepOnboarding = "HasCompletedTopstepOnboarding"
private let kActiveAccountId = "ActiveAccountId"

enum TopstepConnectionState: Equatable {
    case idle
    case checking
    case connected(accountCount: Int)
    case failed(message: String)
}

@MainActor
final class SessionStore: ObservableObject {
    @Published var accounts: [TradingAccount] = []
    @Published var activeAccountId: String?
    @Published var topstepApiKey: String?
    @Published var topstepUsername: String?
    @Published var hasCompletedOnboarding: Bool
    @Published var topstepConnectionState: TopstepConnectionState = .idle
    @Published var lastConnectionError: String?

    var activeAccountName: String? {
        guard let id = activeAccountId,
              let account = accounts.first(where: { $0.id == id }) else {
            return nil
        }
        return account.name
    }

    init() {
        let storedKey = UserDefaults.standard.string(forKey: kTopstepApiKey)
        self.topstepApiKey = storedKey
        self.topstepUsername = UserDefaults.standard.string(forKey: kTopstepUsername)
        let storedOnboarding = UserDefaults.standard.bool(forKey: kHasCompletedTopstepOnboarding)
        let hasKey = (storedKey?.isEmpty == false)
        self.hasCompletedOnboarding = storedOnboarding || hasKey
        if hasKey && !storedOnboarding {
            UserDefaults.standard.set(true, forKey: kHasCompletedTopstepOnboarding)
        }
        self.activeAccountId = UserDefaults.standard.string(forKey: kActiveAccountId)
        Task {
            await loadDemoOrRemoteAccounts()
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: kHasCompletedTopstepOnboarding)
    }

    func setActiveAccount(id: String) {
        activeAccountId = id
        UserDefaults.standard.set(id, forKey: kActiveAccountId)
    }

    func loadDemoOrRemoteAccounts() async {
        TopstepService.shared.setApiKey(topstepApiKey)
        TopstepService.shared.setUsername(topstepUsername)
        let hasKey = (topstepApiKey?.isEmpty == false)

        if hasKey {
            topstepConnectionState = .checking
            lastConnectionError = nil
            do {
                let fetched = try await TopstepService.shared.fetchAccounts()
                accounts = fetched
                topstepConnectionState = .connected(accountCount: fetched.count)
                lastConnectionError = nil
                if !fetched.isEmpty {
                    if activeAccountId == nil || !fetched.contains(where: { $0.id == activeAccountId }) {
                        activeAccountId = fetched.first?.id
                        if let id = activeAccountId {
                            UserDefaults.standard.set(id, forKey: kActiveAccountId)
                        }
                    }
                } else {
                    activeAccountId = nil
                }
                return
            } catch {
                accounts = []
                activeAccountId = nil
                let message = (error as NSError).localizedDescription
                topstepConnectionState = .failed(message: message)
                lastConnectionError = message
                return
            }
        }

        topstepConnectionState = .idle
        lastConnectionError = nil

        let sample = TradingAccount(
            id: "demo",
            name: "Topstep Evaluation",
            type: "Evaluation",
            currency: "USD",
            balance: 100_000,
            equity: 100_250,
            drawdownLimit: 2_000
        )
        self.accounts = [sample]
        if activeAccountId == nil {
            self.activeAccountId = sample.id
            UserDefaults.standard.set(sample.id, forKey: kActiveAccountId)
        }
    }

    func updateTopstepApiKey(_ rawKey: String) {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        topstepApiKey = trimmed.isEmpty ? nil : trimmed
        if let value = topstepApiKey {
            UserDefaults.standard.set(value, forKey: kTopstepApiKey)
        } else {
            UserDefaults.standard.removeObject(forKey: kTopstepApiKey)
        }

        Task {
            await loadDemoOrRemoteAccounts()
        }
    }

    func updateTopstepUsername(_ raw: String?) {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        topstepUsername = trimmed.isEmpty ? nil : trimmed
        if let value = topstepUsername {
            UserDefaults.standard.set(value, forKey: kTopstepUsername)
        } else {
            UserDefaults.standard.removeObject(forKey: kTopstepUsername)
        }
        TopstepService.shared.setUsername(topstepUsername)
    }

    func clearTopstepKeyForReentry() {
        topstepApiKey = nil
        UserDefaults.standard.removeObject(forKey: kTopstepApiKey)
        topstepConnectionState = .idle
        lastConnectionError = nil
        accounts = []
        activeAccountId = nil
    }

    /// Disconnect from Topstep (clear active account and connection state; API key is kept for re-login).
    func disconnect() {
        activeAccountId = nil
        UserDefaults.standard.removeObject(forKey: kActiveAccountId)
        topstepConnectionState = .idle
        lastConnectionError = nil
        accounts = []
    }
}


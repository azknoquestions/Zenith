import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published var accounts: [TradingAccount] = []
    @Published var activeAccountId: String?
    @Published var topstepApiKey: String?

    var activeAccountName: String? {
        guard let id = activeAccountId,
              let account = accounts.first(where: { $0.id == id }) else {
            return nil
        }
        return account.name
    }

    init() {
        self.topstepApiKey = UserDefaults.standard.string(forKey: "TopstepApiKey")
        Task {
            await loadDemoOrRemoteAccounts()
        }
    }

    func loadDemoOrRemoteAccounts() async {
        do {
            TopstepService.shared.setApiKey(topstepApiKey)
            let fetched = try await TopstepService.shared.fetchAccounts()
            if !fetched.isEmpty {
                accounts = fetched
                activeAccountId = fetched.first?.id
                return
            }
        } catch {
            // Fall back to demo below
        }

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
        self.activeAccountId = sample.id
    }

    func updateTopstepApiKey(_ rawKey: String) {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        topstepApiKey = trimmed.isEmpty ? nil : trimmed
        if let value = topstepApiKey {
            UserDefaults.standard.set(value, forKey: "TopstepApiKey")
        } else {
            UserDefaults.standard.removeObject(forKey: "TopstepApiKey")
        }

        Task {
            await loadDemoOrRemoteAccounts()
        }
    }
}


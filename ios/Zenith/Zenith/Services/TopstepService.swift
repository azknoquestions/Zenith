import Foundation

final class TopstepService {
    static let shared = TopstepService()

    private let baseURL = URL(string: "http://localhost:4000")! // Point to backend dev server
    private var apiKey: String?

    private init() {}

    func setApiKey(_ key: String?) {
        self.apiKey = key
    }

    func fetchAccounts() async throws -> [TradingAccount] {
        let url = baseURL.appendingPathComponent("topstep/accounts")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let key = apiKey {
            request.setValue(key, forHTTPHeaderField: "X-Topstep-Api-Key")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "TopstepService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Accounts fetch failed"])
        }

        struct AccountsEnvelope: Decodable {
            let accounts: [TradingAccount]
        }

        let decoded = try JSONDecoder().decode(AccountsEnvelope.self, from: data)
        return decoded.accounts
    }
}


import Foundation

final class TopstepService {
    static let shared = TopstepService()

    /// User-visible debug: last HTTP status and body snippet from validateConnection (for debugging Supabase connection).
    static var lastDebugStatus: Int?
    static var lastDebugBody: String?

    private var apiKey: String?
    private var username: String?

    private init() {}

    func setApiKey(_ key: String?) {
        self.apiKey = key
    }

    func setUsername(_ name: String?) {
        let t = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.username = t.isEmpty ? nil : t
    }

    private func authHeaders() -> [String: String] {
        var h = ApiConfig.supabaseHeaders()
        if let key = apiKey { h["X-Topstep-Api-Key"] = key }
        if let name = username, !name.isEmpty { h["X-Topstep-Username"] = name }
        return h
    }

    /// Result of testing the Topstep API connection.
    struct ConnectionResult {
        let connected: Bool
        let message: String
        let accountCount: Int
        let errorCode: String?
    }

    /// Validates the current API key with the backend and returns connection status.
    func validateConnection() async -> ConnectionResult {
        guard let url = ApiConfig.url(path: "topstep/connection") else {
            return ConnectionResult(connected: false, message: "Invalid app configuration.", accountCount: 0, errorCode: "invalid_url")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse
            let status = http?.statusCode ?? 0
            let bodySnippet = String(data: data, encoding: .utf8).map { String($0.prefix(800)) } ?? ""
            Self.lastDebugStatus = status
            Self.lastDebugBody = bodySnippet
            // #region agent log
            DebugLog.log(location: "TopstepService.swift:validateConnection", message: "Response from Supabase/backend", data: [
                "requestURL": request.url?.absoluteString ?? "",
                "statusCode": status,
                "bodySnippet": bodySnippet,
            ], hypothesisId: "H2,H3,H4")
            // #endregion

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let connected = (json["connected"] as? Bool) ?? false
                let message = (json["message"] as? String) ?? (json["error"] as? String) ?? ""
                let accountCount = (json["accountCount"] as? Int) ?? 0
                let errorCode = json["error"] as? String
                if !connected && message.isEmpty, let err = errorCode {
                    let fallback: String
                    switch err {
                    case "invalid_key": fallback = "Invalid API key or username. Check your key in the Topstep dashboard."
                    case "timeout": fallback = "Request timed out. Check your internet connection."
                    case "server_error": fallback = "Could not reach Topstep. Try again later."
                    default: fallback = "Connection failed."
                    }
                    return ConnectionResult(connected: false, message: fallback, accountCount: 0, errorCode: err)
                }
                return ConnectionResult(connected: connected, message: message, accountCount: accountCount, errorCode: errorCode)
            }

            if status == 401 {
                return ConnectionResult(connected: false, message: "Invalid API key or username.", accountCount: 0, errorCode: "invalid_key")
            }
            if status == 502 {
                return ConnectionResult(connected: false, message: "Topstep service unavailable. Try again later.", accountCount: 0, errorCode: "server_error")
            }
            if status >= 400 {
                return ConnectionResult(connected: false, message: "Connection failed (HTTP \(status)).", accountCount: 0, errorCode: nil)
            }
        } catch {
            let err = error as NSError
            Self.lastDebugStatus = nil
            Self.lastDebugBody = "Error: \(err.domain) \(err.code) \(err.localizedDescription)"
            // #region agent log
            DebugLog.log(location: "TopstepService.swift:validateConnection", message: "Request threw", data: [
                "requestURL": request.url?.absoluteString ?? "",
                "errorDomain": err.domain,
                "errorCode": err.code,
                "errorDesc": err.localizedDescription,
            ], hypothesisId: "H4")
            // #endregion
            let msg = err.localizedDescription
            return ConnectionResult(connected: false, message: msg.isEmpty ? "Network error. Check your connection." : msg, accountCount: 0, errorCode: "network")
        }
        return ConnectionResult(connected: false, message: "Unknown error.", accountCount: 0, errorCode: nil)
    }

    func fetchAccounts() async throws -> [TradingAccount] {
        guard let url = ApiConfig.url(path: "topstep/accounts") else { throw NSError(domain: "TopstepService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            Self.lastDebugStatus = nil
            Self.lastDebugBody = "Network: \(error.localizedDescription)"
            throw error
        }
        guard let http = response as? HTTPURLResponse else {
            Self.lastDebugStatus = nil
            Self.lastDebugBody = "No HTTP response"
            throw NSError(domain: "TopstepService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Accounts fetch failed"])
        }
        let bodySnippet = String(data: data, encoding: .utf8).map { String($0.prefix(300)) } ?? ""
        if !(200..<300).contains(http.statusCode) {
            Self.lastDebugStatus = http.statusCode
            Self.lastDebugBody = bodySnippet.isEmpty ? "Empty response" : bodySnippet
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? (http.statusCode == 401 ? "Invalid API key or username." : "Accounts fetch failed.")
            throw NSError(domain: "TopstepService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        struct AccountsEnvelope: Decodable {
            let accounts: [TradingAccount]
        }

        let decoded = try JSONDecoder().decode(AccountsEnvelope.self, from: data)
        return decoded.accounts
    }

    func fetchContracts() async throws -> [Contract] {
        guard let url = ApiConfig.url(path: "topstep/contracts") else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }
        struct Envelope: Decodable { let contracts: [Contract] }
        let decoded = try? JSONDecoder().decode(Envelope.self, from: data)
        return decoded?.contracts ?? []
    }

    func fetchQuotes(symbols: [String]) async throws -> [Quote] {
        guard !symbols.isEmpty else { return [] }
        let list = symbols.prefix(20).joined(separator: ",")
        guard let url = ApiConfig.url(path: "topstep/quotes", queryItems: [URLQueryItem(name: "symbols", value: list)]) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "TopstepService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Quotes fetch failed"])
        }

        struct QuotesEnvelope: Decodable { let quotes: [Quote] }
        let decoded = try JSONDecoder().decode(QuotesEnvelope.self, from: data)
        return decoded.quotes
    }

    func fetchQuotes(contractIds: [String]) async throws -> [Quote] {
        guard !contractIds.isEmpty else { return [] }
        let list = contractIds.prefix(20).joined(separator: ",")
        guard let url = ApiConfig.url(path: "topstep/quotes", queryItems: [URLQueryItem(name: "contractIds", value: list)]) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "TopstepService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Quotes fetch failed"])
        }
        struct QuotesEnvelope: Decodable { let quotes: [Quote] }
        let decoded = try JSONDecoder().decode(QuotesEnvelope.self, from: data)
        return decoded.quotes
    }

    func fetchPositions(accountId: String) async throws -> [Position] {
        guard let url = ApiConfig.url(path: "topstep/positions", queryItems: [URLQueryItem(name: "accountId", value: accountId)]) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }
        struct Envelope: Decodable { let positions: [Position] }
        let decoded = try? JSONDecoder().decode(Envelope.self, from: data)
        return decoded?.positions ?? []
    }

    func fetchOrders(accountId: String, start: Date, end: Date?) async throws -> [Order] {
        let iso8601: (Date) -> String = { ISO8601DateFormatter().string(from: $0) }
        var items = [
            URLQueryItem(name: "accountId", value: accountId),
            URLQueryItem(name: "startTimestamp", value: iso8601(start))
        ]
        if let end = end {
            items.append(URLQueryItem(name: "endTimestamp", value: iso8601(end)))
        }
        guard let url = ApiConfig.url(path: "topstep/orders", queryItems: items) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }
        struct Envelope: Decodable { let orders: [Order] }
        let decoded = try? JSONDecoder().decode(Envelope.self, from: data)
        return decoded?.orders ?? []
    }

    func fetchTrades(accountId: String, start: Date, end: Date?) async throws -> [Trade] {
        let iso8601: (Date) -> String = { ISO8601DateFormatter().string(from: $0) }
        var items = [
            URLQueryItem(name: "accountId", value: accountId),
            URLQueryItem(name: "startTimestamp", value: iso8601(start))
        ]
        if let end = end {
            items.append(URLQueryItem(name: "endTimestamp", value: iso8601(end)))
        }
        guard let url = ApiConfig.url(path: "topstep/trades", queryItems: items) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }
        struct Envelope: Decodable { let trades: [Trade] }
        let decoded = try? JSONDecoder().decode(Envelope.self, from: data)
        return decoded?.trades ?? []
    }

    struct Bar: Decodable {
        let t: String
        let o: Double
        let h: Double
        let l: Double
        let c: Double
        let v: Double
    }

    func fetchBars(contractId: String, from: Date, to: Date?, unit: Int, unitNumber: Int, limit: Int) async throws -> [Bar] {
        let iso8601: (Date) -> String = { ISO8601DateFormatter().string(from: $0) }
        let end = to ?? Date()
        let items = [
            URLQueryItem(name: "contractId", value: contractId),
            URLQueryItem(name: "from", value: iso8601(from)),
            URLQueryItem(name: "to", value: iso8601(end)),
            URLQueryItem(name: "unit", value: String(unit)),
            URLQueryItem(name: "unitNumber", value: String(unitNumber)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = ApiConfig.url(path: "topstep/bars", queryItems: items) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "TopstepService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Bars fetch failed"])
        }
        struct Envelope: Decodable { let bars: [Bar] }
        let decoded = try? JSONDecoder().decode(Envelope.self, from: data)
        return decoded?.bars ?? []
    }

    func placeOrder(accountId: String, symbol: String, side: OrderSide, type: OrderType, quantity: Int, limitPrice: Double?, stopPrice: Double?) async throws -> String {
        try await placeOrder(accountId: accountId, symbol: symbol, contractId: nil, side: side, type: type, quantity: quantity, limitPrice: limitPrice, stopPrice: stopPrice)
    }

    func placeOrder(accountId: String, symbol: String, contractId: String?, side: OrderSide, type: OrderType, quantity: Int, limitPrice: Double?, stopPrice: Double?) async throws -> String {
        guard let url = ApiConfig.url(path: "topstep/orders") else { throw NSError(domain: "TopstepService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        var body: [String: Any] = [
            "accountId": accountId,
            "side": side == .buy ? "buy" : "sell",
            "type": type == .market ? "market" : (type == .limit ? "limit" : "stop"),
            "quantity": quantity,
            "limitPrice": limitPrice as Any,
            "stopPrice": stopPrice as Any
        ]
        if let cid = contractId, !cid.isEmpty {
            body["contractId"] = cid
        } else {
            body["symbol"] = symbol
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "TopstepService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Order failed"])
        }
        if let err = try? JSONDecoder().decode([String: String].self, from: data), let msg = err["error"] {
            throw NSError(domain: "TopstepService", code: 4, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "TopstepService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Order rejected"])
        }
        struct OrderResponse: Decodable {
            let orderId: OrderIdValue?
            let status: String?
        }
        enum OrderIdValue: Decodable {
            case string(String)
            case int(Int)
            init(from decoder: Decoder) throws {
                let c = try decoder.singleValueContainer()
                if let s = try? c.decode(String.self) { self = .string(s); return }
                if let i = try? c.decode(Int.self) { self = .int(i); return }
                throw DecodingError.typeMismatch(OrderIdValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "orderId must be String or Int"))
            }
            var stringValue: String {
                switch self {
                case .string(let s): return s
                case .int(let i): return String(i)
                }
            }
        }
        let decoded = try? JSONDecoder().decode(OrderResponse.self, from: data)
        return decoded?.orderId?.stringValue ?? "unknown"
    }
}


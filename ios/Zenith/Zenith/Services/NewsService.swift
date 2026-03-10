import Foundation

final class NewsService {
    static let shared = NewsService()

    private init() {}

    func fetchHeadlines() async throws -> [NewsItem] {
        guard let url = ApiConfig.url(path: "news/headlines") else { throw NSError(domain: "NewsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        ApiConfig.supabaseHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "NewsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "News fetch failed"])
        }

        struct Envelope: Decodable {
            let news: [NewsItem]
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Envelope.self, from: data)
        return decoded.news
    }

    func fetchEvents(from: Date, to: Date) async throws -> [EconomicEvent] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let fromStr = formatter.string(from: from)
        let toStr = formatter.string(from: to)
        guard let url = ApiConfig.url(path: "news/events", queryItems: [
            URLQueryItem(name: "from", value: fromStr),
            URLQueryItem(name: "to", value: toStr)
        ]) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        ApiConfig.supabaseHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "NewsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Events fetch failed"])
        }

        struct Envelope: Decodable {
            let events: [EconomicEvent]
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Envelope.self, from: data)
        return decoded.events
    }
}


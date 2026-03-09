import Foundation

final class NewsService {
    static let shared = NewsService()
    private let baseURL = URL(string: "http://localhost:4000")!

    private init() {}

    func fetchHeadlines() async throws -> [NewsItem] {
        let url = baseURL.appendingPathComponent("news/headlines")
        let (data, response) = try await URLSession.shared.data(from: url)
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

    func fetchEvents() async throws -> [EconomicEvent] {
        let url = baseURL.appendingPathComponent("news/events")
        let (data, response) = try await URLSession.shared.data(from: url)
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


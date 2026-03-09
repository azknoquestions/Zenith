import Foundation

final class AIApiClient {
    private let baseURL = URL(string: "http://localhost:4000")!

    func send(messages: [AIMessage]) async throws -> String {
        let url = baseURL.appendingPathComponent("ai/chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct WireMessage: Codable {
            let role: String
            let content: String
        }

        let payloadMessages: [WireMessage] = messages.map { msg in
            WireMessage(role: msg.role.rawValue, content: msg.text)
        }

        struct Body: Codable {
            let messages: [WireMessage]
        }

        request.httpBody = try JSONEncoder().encode(Body(messages: payloadMessages))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "AIApiClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "AI request failed"])
        }

        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        struct Completion: Decodable {
            let choices: [Choice]
        }

        let decoded = try JSONDecoder().decode(Completion.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
}


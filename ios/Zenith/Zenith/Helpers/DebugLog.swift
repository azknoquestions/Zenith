import Foundation

/// Sends a single debug log to the session ingest (Cursor debug mode). Simulator can reach host at 127.0.0.1.
enum DebugLog {
    private static let ingestURL = URL(string: "http://127.0.0.1:7707/ingest/cf743728-3c3a-4ee3-8424-80e8f4efc712")!
    private static let sessionId = "ed0068"

    static func log(location: String, message: String, data: [String: Any], hypothesisId: String? = nil) {
        var payload: [String: Any] = [
            "sessionId": sessionId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        ]
        if let h = hypothesisId { payload["hypothesisId"] = h }
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var req = URLRequest(url: ingestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        req.httpBody = body
        URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
    }
}

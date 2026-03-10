import Foundation

/// Single source of truth for the Zenith backend URL. App talks to this URL for Topstep, news, and AI.
enum ApiConfig {
    /// If true, requests go through Supabase (public URL) then proxy to your backend. Use this for mobile testing so the device always hits a public endpoint.
    static let useSupabase = true

    /// Your Node backend URL. All API keys (Topstep/ProjectX, Finnhub, NewsData, NVIDIA) are read from this server’s .env.
    /// Examples: "https://zenith-backend.onrender.com" (Render), "https://your-app.fly.dev", or ngrok URL for local.
    static let baseURL = URL(string: "https://zenith-backend.onrender.com")!

    /// Supabase Edge Function URL. Used when useSupabase == true.
    static let supabaseFunctionsURL = URL(string: "https://ikoekzsnhyessmmdpjxp.supabase.co/functions/v1/zenith-api")!

    /// Supabase anon key — required when the Edge Function has JWT verification enabled. Get from Dashboard → Project Settings → API → anon public.
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlrb2VrenNuaHllc3NtbWRwanhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwOTQ2ODMsImV4cCI6MjA4ODY3MDY4M30.CGjDN1iO3E879fw-dcXBUAt0ORDvZ6z-4H1kK0i-66c"

    /// Headers to send when calling Supabase Edge Functions (so JWT verification succeeds if enabled).
    static func supabaseHeaders() -> [String: String] {
        guard useSupabase else { return [:] }
        return ["Authorization": "Bearer \(supabaseAnonKey)"]
    }

    /// Build request URL for a path (e.g. "topstep/contracts"). When useSupabase, path is sent as ?path=/topstep/contracts and extra queryItems are appended.
    static func url(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        // #region agent log
        let pathValue = path.hasPrefix("/") ? path : "/" + path
        if useSupabase {
            var comp = URLComponents(url: supabaseFunctionsURL, resolvingAgainstBaseURL: false)!
            var items = [URLQueryItem(name: "path", value: pathValue)]
            if let extra = queryItems { items.append(contentsOf: extra) }
            comp.queryItems = items
            let finalURL = comp.url
            DebugLog.log(location: "ApiConfig.swift:url", message: "Supabase URL built", data: [
                "useSupabase": true,
                "pathParam": path,
                "pathValue": pathValue,
                "finalURL": finalURL?.absoluteString ?? "nil",
                "queryItemCount": (queryItems?.count ?? 0) + 1,
            ], hypothesisId: "H1")
            return finalURL
        }
        var comp = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        comp.queryItems = queryItems
        let fallback = comp.url ?? baseURL.appendingPathComponent(path)
        DebugLog.log(location: "ApiConfig.swift:url", message: "Direct backend URL built", data: ["useSupabase": false, "path": path, "finalURL": fallback.absoluteString], hypothesisId: "H1")
        return fallback
        // #endregion
    }

    enum Support {
        static let faq = URL(string: "https://help.topstep.com")!
        static let tradingPrinciples = URL(string: "https://help.topstep.com/en/collections/3248944-trading-basics")!
        static let riskDisclosures = URL(string: "https://www.topstep.com/risk-disclosure/")!
        static let contactSupport = URL(string: "mailto:support@topstep.com")!
    }
}

import Foundation

struct TradingAccount: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: String
    let currency: String
    let balance: Double
    let equity: Double
    let drawdownLimit: Double?
}

struct Instrument: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let assetClass: String
}

struct Contract: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let symbolId: String
    let tickSize: Double
    let tickValue: Double
}

struct Position: Identifiable, Codable, Hashable {
    let id: String
    let accountId: String
    let contractId: String
    let contractName: String
    let symbol: String
    let type: Int
    let size: Int
    let averagePrice: Double
    let creationTimestamp: String?
}

struct Order: Identifiable, Codable, Hashable {
    let id: String
    let accountId: String
    let contractId: String
    let contractName: String
    let symbol: String
    let status: Int
    let type: Int
    let side: Int
    let size: Int
    let limitPrice: Double?
    let stopPrice: Double?
    let fillVolume: Int
    let filledPrice: Double?
    let creationTimestamp: String?
    let updateTimestamp: String?
}

struct Trade: Identifiable, Codable, Hashable {
    let id: String
    let accountId: String
    let contractId: String
    let contractName: String
    let symbol: String
    let orderId: String?
    let side: Int
    let size: Int
    let price: Double
    let profitLoss: Double?
    let fees: Double?
    let creationTimestamp: String?
}

struct Quote: Identifiable, Codable, Hashable {
    let id: String
    let instrument: Instrument
    let lastPrice: Double
    let netChange: Double
    let percentChange: Double
    let high: Double?
    let low: Double?
}

struct NewsItem: Identifiable, Codable, Hashable {
    let id: String
    let headline: String
    let source: String
    let publishedAt: Date
    let summary: String
    let symbols: [String]
}

struct EconomicEvent: Identifiable, Codable, Hashable {
    let id: String
    let time: Date
    let country: String
    let name: String
    let importance: String
    let previous: String?
    let forecast: String?
    let actual: String?
}

enum OrderSide: String, Codable {
    case buy
    case sell
}

enum OrderType: String, Codable {
    case market
    case limit
    case stop
}

struct OrderTicket: Codable {
    var instrument: Instrument
    var accountId: String
    var side: OrderSide
    var type: OrderType
    var quantity: Double
    var limitPrice: Double?
    var stopPrice: Double?
}

struct AIMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    let text: String
    let createdAt: Date
}


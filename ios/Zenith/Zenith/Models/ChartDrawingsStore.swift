//
//  ChartDrawingsStore.swift
//  Zenith
//
//  Persists chart drawings per symbol (horizontal lines, trendlines, etc.).
//

import Combine
import Foundation
import SwiftUI

enum ChartDrawingType: String, Codable, CaseIterable {
    case horizontalLine = "Horizontal line"
    case trendline = "Trendline"
    case verticalLine = "Vertical line"
}

struct ChartDrawing: Identifiable, Codable, Hashable {
    var id: UUID
    var type: ChartDrawingType
    var price: Double?
    var price1: Double?
    var price2: Double?
    var index1: Int?
    var index2: Int?
    var timestamp: String?
    var label: String?

    static func horizontalLine(price: Double) -> ChartDrawing {
        ChartDrawing(id: UUID(), type: .horizontalLine, price: price, price1: nil, price2: nil, index1: nil, index2: nil, timestamp: nil, label: nil)
    }

    static func trendline(price1: Double, price2: Double, index1: Int, index2: Int) -> ChartDrawing {
        ChartDrawing(id: UUID(), type: .trendline, price: nil, price1: price1, price2: price2, index1: index1, index2: index2, timestamp: nil, label: nil)
    }

    static func verticalLine(timestamp: String) -> ChartDrawing {
        ChartDrawing(id: UUID(), type: .verticalLine, price: nil, price1: nil, price2: nil, index1: nil, index2: nil, timestamp: timestamp, label: nil)
    }
}

private let kChartDrawingsPrefix = "ChartDrawings_"

final class ChartDrawingsStore: ObservableObject {
    @Published private(set) var drawings: [ChartDrawing] = []
    private var symbol: String = ""

    func load(symbol: String) {
        self.symbol = symbol
        let key = kChartDrawingsPrefix + symbol
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ChartDrawing].self, from: data) else {
            drawings = []
            return
        }
        drawings = decoded
    }

    func add(_ drawing: ChartDrawing) {
        drawings.append(drawing)
        save()
    }

    func remove(id: UUID) {
        drawings.removeAll { $0.id == id }
        save()
    }

    func duplicate(_ drawing: ChartDrawing) {
        var copy = drawing
        copy.id = UUID()
        drawings.append(copy)
        save()
    }

    func clearAll() {
        drawings = []
        save()
    }

    private func save() {
        let key = kChartDrawingsPrefix + symbol
        if let data = try? JSONEncoder().encode(drawings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

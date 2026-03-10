import Foundation
import Combine
import SwiftUI

private let kWatchlistSymbols = "WatchlistSymbols"

/// User's watchlist of symbols (e.g. ES, NQ, CL). Persisted; used by Quotes and Trade.
final class WatchlistStore: ObservableObject {
    @Published var symbols: [String]

    init() {
        self.symbols = (UserDefaults.standard.array(forKey: kWatchlistSymbols) as? [String]) ?? ["ES", "NQ", "CL"]
    }

    func add(_ symbol: String) {
        let s = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !s.isEmpty, !symbols.contains(s) else { return }
        symbols.append(s)
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        symbols.remove(atOffsets: offsets)
        save()
    }

    func remove(symbol: String) {
        symbols.removeAll { $0.uppercased() == symbol.uppercased() }
        save()
    }

    private func save() {
        UserDefaults.standard.set(symbols, forKey: kWatchlistSymbols)
    }
}

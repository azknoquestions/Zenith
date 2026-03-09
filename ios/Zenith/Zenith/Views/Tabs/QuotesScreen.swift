import SwiftUI

struct QuotesScreen: View {
    @State private var quotes: [Quote] = DemoData.sampleQuotes

    var body: some View {
        NavigationStack {
            ZStack {
                ZenithColors.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(quotes) { quote in
                            ZenithCard {
                                QuoteRowView(quote: quote)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct QuoteRowView: View {
    let quote: Quote

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(quote.instrument.symbol)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(ZenithColors.textPrimary)
                Text(quote.instrument.name)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(ZenithColors.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(quote.lastPrice, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(ZenithColors.textPrimary)

                HStack(spacing: 6) {
                    let changeColor = quote.netChange >= 0 ? ZenithColors.positive : ZenithColors.negative
                    Text(quote.netChange, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(changeColor)
                    Text(quote.percentChange / 100, format: .percent.precision(.fractionLength(2)))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(changeColor)
                }
            }
        }
    }
}

private enum DemoData {
    static let es = Instrument(id: "ES", symbol: "ES", name: "E‑mini S&P 500", assetClass: "Index Futures")
    static let nq = Instrument(id: "NQ", symbol: "NQ", name: "E‑mini Nasdaq 100", assetClass: "Index Futures")
    static let cl = Instrument(id: "CL", symbol: "CL", name: "Crude Oil WTI", assetClass: "Energy Futures")

    static let sampleQuotes: [Quote] = [
        Quote(id: "ES", instrument: es, lastPrice: 5350.25, netChange: 12.5, percentChange: 0.23, high: 5370.0, low: 5295.5),
        Quote(id: "NQ", instrument: nq, lastPrice: 19050.75, netChange: -45.25, percentChange: -0.18, high: 19180.0, low: 18890.25),
        Quote(id: "CL", instrument: cl, lastPrice: 82.34, netChange: 0.82, percentChange: 1.01, high: 83.1, low: 80.9)
    ]
}


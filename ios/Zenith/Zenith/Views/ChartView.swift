import SwiftUI
import Charts

struct ChartStrategySignal {
    let index: Int
    let isBuy: Bool
}

enum ChartDisplayType: String, CaseIterable {
    case candlestick = "Candlestick"
    case line = "Line"
    case bar = "Bar"
}

enum ChartContentTab: String, CaseIterable {
    case chart = "Chart"
    case news = "News"
    case options = "Options"
    case spreads = "Spreads"
}

// Unit: 1=Second, 2=Minute, 3=Hour, 4=Day, 5=Week, 6=Month (ProjectX)
enum ChartAggregation: String, CaseIterable {
    case m1 = "1m"
    case m5 = "5m"
    case m15 = "15m"
    case m30 = "30m"
    case h1 = "1H"
    case h4 = "4H"
    case d1 = "1D"
    var unit: Int {
        switch self {
        case .m1, .m5, .m15, .m30: return 2
        case .h1, .h4: return 3
        case .d1: return 4
        }
    }
    var unitNumber: Int {
        switch self {
        case .m1: return 1
        case .m5: return 5
        case .m15: return 15
        case .m30: return 30
        case .h1: return 1
        case .h4: return 4
        case .d1: return 1
        }
    }
}

enum ChartRange: String, CaseIterable {
    case d1 = "1D"
    case d5 = "5D"
    case m1 = "1M"
    case m3 = "3M"
    case m6 = "6M"
    case y1 = "1Y"
    case ytd = "YTD"
    case max = "Max"
    var days: Int? {
        switch self {
        case .d1: return 1
        case .d5: return 5
        case .m1: return 30
        case .m3: return 90
        case .m6: return 180
        case .y1: return 365
        case .ytd: return nil
        case .max: return 360
        }
    }
}

struct ChartView: View {
    let contractId: String
    let contractName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var drawingsStore = ChartDrawingsStore()
    @State private var bars: [TopstepService.Bar] = []
    @State private var quote: Quote?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSMA = true
    @State private var showRSI = true
    @State private var showVolume = true
    @State private var showBollinger = false
    @State private var showMACD = false
    @State private var showVWAP = false
    @State private var showATR = false
    @State private var showMACrossoverStrategy = false
    @State private var showRSIStrategy = false
    @State private var newHorizontalLinePrice: String = ""
    @State private var selectedAggregation: ChartAggregation = .d1
    @State private var selectedRange: ChartRange = .m1
    @State private var chartDisplayType: ChartDisplayType = .candlestick
    @State private var chartContentTab: ChartContentTab = .chart
    @State private var newsItems: [NewsItem] = []
    @State private var showTimeFrameSheet = false
    @State private var showStudiesSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                ZenithColors.background.ignoresSafeArea()
                if isLoading && bars.isEmpty {
                    ProgressView().tint(ZenithColors.accent)
                } else if let err = errorMessage {
                    VStack(spacing: 12) {
                        Text(err)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await loadBars() } }
                            .foregroundColor(ZenithColors.accent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        Picker("Content", selection: $chartContentTab) {
                            ForEach(ChartContentTab.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .onChange(of: chartContentTab) { _, new in
                            if new == .news { Task { await loadChartNews() } }
                        }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if chartContentTab == .chart {
                            chartHeaderView
                            Button {
                                showTimeFrameSheet = true
                            } label: {
                                HStack {
                                    Text("Time Frame")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(ZenithColors.textPrimary)
                                    Text("\(selectedAggregation.rawValue) · \(selectedRange.rawValue)")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(ZenithColors.accent)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(ZenithColors.textMuted)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(ZenithColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showTimeFrameSheet) {
                                chartTimeFrameSheet
                            }

                            Picker("Chart type", selection: $chartDisplayType) {
                                ForEach(ChartDisplayType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.segmented)

                            if !bars.isEmpty {
                                priceChartSection
                                if showVolume { volumeSection }
                                if showRSI { rsiSection }
                                if showMACD { macdSection }
                                if showATR { atrSection }
                                if showMACrossoverStrategy || showRSIStrategy {
                                    strategyBacktestCard
                                }
                            }

                            Button {
                                showStudiesSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "chart.xyaxis.line")
                                    Text("Studies")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(ZenithColors.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(ZenithColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showStudiesSheet) {
                                chartStudiesSheet
                            }

                            Toggle("Show SMA (20)", isOn: $showSMA)
                                .tint(ZenithColors.accent)
                                .foregroundColor(ZenithColors.textPrimary)
                            Toggle("Show Volume", isOn: $showVolume)
                                .tint(ZenithColors.accent)
                                .foregroundColor(ZenithColors.textPrimary)
                            Toggle("Show RSI", isOn: $showRSI)
                                .tint(ZenithColors.accent)
                                .foregroundColor(ZenithColors.textPrimary)

                            drawingsSection
                            } else if chartContentTab == .news {
                                chartNewsContent
                            } else {
                                chartPlaceholderContent(tab: chartContentTab)
                            }
                        }
                        .padding(20)
                    }
                    }
                }
            }
            .navigationTitle(contractName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ZenithColors.accent)
                }
            }
            .task {
                drawingsStore.load(symbol: contractId)
                await loadQuote()
                await loadBars()
            }
        }
    }

    private var chartHeaderView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if let q = quote {
                    Text(q.lastPrice, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ZenithColors.textPrimary)
                    Text("Bid —  Ask —")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(ZenithColors.textMuted)
                    Text("\(q.netChange >= 0 ? "+" : "")\(q.netChange, format: .number.precision(.fractionLength(2))) (\(q.percentChange, format: .percent.precision(.fractionLength(2))))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(q.netChange >= 0 ? ZenithColors.positive : ZenithColors.negative)
                } else {
                    Text("—")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                    Text("Bid —  Ask —")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var chartStudiesSheet: some View {
        NavigationStack {
            List {
                Section("Overlays on price") {
                    studyToggleRow("SMA (20)", isOn: $showSMA)
                    studyToggleRow("Bollinger Bands", isOn: $showBollinger)
                    studyToggleRow("VWAP", isOn: $showVWAP)
                }
                Section("Lower panes") {
                    studyToggleRow("Volume", isOn: $showVolume)
                    studyToggleRow("RSI (14)", isOn: $showRSI)
                    studyToggleRow("MACD", isOn: $showMACD)
                    studyToggleRow("ATR (14)", isOn: $showATR)
                }
                Section("Strategies") {
                    studyToggleRow("MA Crossover", isOn: $showMACrossoverStrategy)
                    studyToggleRow("RSI (30/70)", isOn: $showRSIStrategy)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ZenithColors.background)
            .navigationTitle("Studies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showStudiesSheet = false }
                        .foregroundColor(ZenithColors.accent)
                }
            }
        }
    }

    private func studyToggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .tint(ZenithColors.accent)
            .foregroundColor(ZenithColors.textPrimary)
    }

    private var chartNewsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market news")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            if newsItems.isEmpty {
                ProgressView().tint(ZenithColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(newsItems.prefix(15)) { item in
                    ZenithCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.headline)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                            Text(item.source)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textMuted)
                        }
                    }
                }
            }
        }
    }

    private func chartPlaceholderContent(tab: ChartContentTab) -> some View {
        VStack(spacing: 12) {
            Text("Not available")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)
            Text("\(tab.rawValue) data is not available in this app.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func loadChartNews() async {
        do {
            newsItems = try await NewsService.shared.fetchHeadlines()
        } catch {
            newsItems = []
        }
    }

    private var chartTimeFrameSheet: some View {
        NavigationStack {
            List {
                Section("Aggregation") {
                    ForEach(ChartAggregation.allCases, id: \.self) { agg in
                        Button {
                            selectedAggregation = agg
                            showTimeFrameSheet = false
                            Task { await loadBars() }
                        } label: {
                            HStack {
                                Text(agg.rawValue)
                                    .foregroundColor(ZenithColors.textPrimary)
                                if selectedAggregation == agg {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ZenithColors.accent)
                                }
                            }
                        }
                    }
                }
                Section("Range") {
                    ForEach(ChartRange.allCases, id: \.self) { r in
                        Button {
                            selectedRange = r
                            showTimeFrameSheet = false
                            Task { await loadBars() }
                        } label: {
                            HStack {
                                Text(r.rawValue)
                                    .foregroundColor(ZenithColors.textPrimary)
                                if selectedRange == r {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ZenithColors.accent)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ZenithColors.background)
            .navigationTitle("Time Frame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showTimeFrameSheet = false }
                        .foregroundColor(ZenithColors.accent)
                }
            }
        }
    }

    private var volumeSection: some View {
        let dates = bars.compactMap { ISO8601DateFormatter().date(from: $0.t) }
        let volMax = bars.map(\.v).max() ?? 1
        return VStack(alignment: .leading, spacing: 8) {
            Text("Volume")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Chart {
                ForEach(Array(bars.enumerated()), id: \.offset) { i, b in
                    let date = dates.count > i ? dates[i] : Date()
                    BarMark(
                        x: .value("Time", date),
                        y: .value("Vol", b.v)
                    )
                    .foregroundStyle(b.c >= b.o ? ZenithColors.positive : ZenithColors.negative)
                }
            }
            .chartYScale(domain: 0 ... (volMax * 1.1))
            .frame(height: 80)
        }
    }

    private var priceChartSection: some View {
        let sma20 = computeSMA(bars.map(\.c), period: 20)
        let bollinger = showBollinger ? computeBollinger(bars.map(\.c), length: 20, mult: 2) : nil
        let vwapValues = showVWAP ? computeVWAP(bars) : nil
        let dates = bars.compactMap { ISO8601DateFormatter().date(from: $0.t) }
        let maSignals = (showMACrossoverStrategy ? computeMACrossoverSignals(bars.map(\.c), fast: 9, slow: 21) : [])
        let rsiSignals = (showRSIStrategy ? computeRSISignals(bars.map(\.c), period: 14, oversold: 30, overbought: 70) : [])
        let yMin = ((bars.map(\.l).min() ?? 0) - 5)
        let yMax = ((bars.map(\.h).max() ?? 0) + 5)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Price")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Chart {
                if chartDisplayType == .line {
                    ForEach(Array(bars.enumerated()), id: \.offset) { i, b in
                        if i < dates.count {
                            LineMark(
                                x: .value("Time", dates[i]),
                                y: .value("Close", b.c)
                            )
                            .foregroundStyle(ZenithColors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                } else {
                    ForEach(Array(bars.enumerated()), id: \.offset) { i, b in
                        let date = dates.count > i ? dates[i] : Date()
                        BarMark(
                            x: .value("Time", date),
                            yStart: .value("Low", b.l),
                            yEnd: .value("High", b.h),
                            width: .ratio(chartDisplayType == .bar ? 0.3 : 0.6)
                        )
                        .foregroundStyle(b.c >= b.o ? ZenithColors.positive : ZenithColors.negative)
                    }
                }
                if showSMA, sma20.count == bars.count {
                    ForEach(Array(sma20.enumerated()), id: \.offset) { element in
                        let i = element.offset
                        let value = element.element
                        if i < dates.count {
                            LineMark(
                                x: .value("Time", dates[i]),
                                y: .value("SMA", value)
                            )
                            .foregroundStyle(ZenithColors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                }
                if let bb = bollinger, bb.upper.count == bars.count {
                    ForEach(Array(bb.upper.enumerated()), id: \.offset) { ei in
                        if ei.offset < dates.count {
                            LineMark(x: .value("Time", dates[ei.offset]), y: .value("Upper", ei.element))
                                .foregroundStyle(ZenithColors.textSecondary)
                                .lineStyle(StrokeStyle(lineWidth: 1))
                        }
                    }
                    ForEach(Array(bb.lower.enumerated()), id: \.offset) { ei in
                        if ei.offset < dates.count {
                            LineMark(x: .value("Time", dates[ei.offset]), y: .value("Lower", ei.element))
                                .foregroundStyle(ZenithColors.textSecondary)
                                .lineStyle(StrokeStyle(lineWidth: 1))
                        }
                    }
                    ForEach(Array(bb.middle.enumerated()), id: \.offset) { ei in
                        if ei.offset < dates.count {
                            LineMark(x: .value("Time", dates[ei.offset]), y: .value("Middle", ei.element))
                                .foregroundStyle(ZenithColors.accent.opacity(0.8))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                    }
                }
                if let vw = vwapValues, vw.count == bars.count {
                    ForEach(Array(vw.enumerated()), id: \.offset) { ei in
                        if ei.offset < dates.count {
                            LineMark(x: .value("Time", dates[ei.offset]), y: .value("VWAP", ei.element))
                                .foregroundStyle(ZenithColors.positive)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                }
                ForEach(drawingsStore.drawings) { d in
                    if d.type == .horizontalLine, let p = d.price {
                        RuleMark(y: .value("Line", p))
                            .foregroundStyle(ZenithColors.accent.opacity(0.8))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    if d.type == .trendline, let p1 = d.price1, let p2 = d.price2, let i1 = d.index1, let i2 = d.index2, i1 < dates.count, i2 < dates.count {
                        let seg = [(dates[i1], p1), (dates[i2], p2)]
                        ForEach(Array(seg.indices), id: \.self) { idx in
                            LineMark(
                                x: .value("Tx", seg[idx].0),
                                y: .value("Px", seg[idx].1)
                            )
                            .foregroundStyle(ZenithColors.positive.opacity(0.9))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    if d.type == .verticalLine, let ts = d.timestamp, let date = ISO8601DateFormatter().date(from: ts) {
                        RuleMark(x: .value("V", date))
                            .foregroundStyle(ZenithColors.textMuted.opacity(0.8))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
                ForEach(Array((maSignals + rsiSignals).enumerated()), id: \.offset) { _, sig in
                    if sig.index < dates.count && sig.index < bars.count {
                        let yVal = sig.isBuy ? bars[sig.index].l - (yMax - yMin) * 0.02 : bars[sig.index].h + (yMax - yMin) * 0.02
                        PointMark(
                            x: .value("Time", dates[sig.index]),
                            y: .value("Price", yVal)
                        )
                        .symbol(sig.isBuy ? .circle : .square)
                        .foregroundStyle(sig.isBuy ? ZenithColors.positive : ZenithColors.negative)
                        .symbolSize(50)
                    }
                }
            }
            .chartYScale(domain: yMin ... yMax)
            .frame(height: 220)
        }
    }

    private var drawingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Drawings")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)

            HStack(spacing: 8) {
                TextField("Price", text: $newHorizontalLinePrice)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Button("Add H-line") {
                    if let p = Double(newHorizontalLinePrice.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        drawingsStore.add(.horizontalLine(price: p))
                        newHorizontalLinePrice = ""
                    }
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ZenithColors.accent)
                Button("Add trendline") {
                    guard bars.count >= 2 else { return }
                    let c1 = bars[0].c
                    let c2 = bars[bars.count - 1].c
                    drawingsStore.add(.trendline(price1: c1, price2: c2, index1: 0, index2: bars.count - 1))
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ZenithColors.accent)
            }

            if !drawingsStore.drawings.isEmpty {
                ForEach(drawingsStore.drawings) { d in
                    HStack {
                        Text(drawingLabel(d))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textSecondary)
                        Spacer()
                        Button("Copy") {
                            drawingsStore.duplicate(d)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ZenithColors.accent)
                        Button("Remove") {
                            drawingsStore.remove(id: d.id)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ZenithColors.negative)
                    }
                }
                Button("Clear all drawings") {
                    drawingsStore.clearAll()
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ZenithColors.negative)
            }
        }
    }

    private func drawingLabel(_ d: ChartDrawing) -> String {
        switch d.type {
        case .horizontalLine:
            return "H-line \(d.price.map { String(format: "%.2f", $0) } ?? "—")"
        case .trendline:
            return "Trendline"
        case .verticalLine:
            return "V-line"
        }
    }

    private var macdSection: some View {
        let (macdLine, signalLine, histogram) = computeMACD(bars.map(\.c), fast: 12, slow: 26, signal: 9)
        let dates = bars.compactMap { ISO8601DateFormatter().date(from: $0.t) }
        let allValues = histogram + macdLine + signalLine
        let (lo, hi) = (allValues.min() ?? 0, allValues.max() ?? 1)
        let padding = max((hi - lo) * 0.1, 0.5)
        return VStack(alignment: .leading, spacing: 8) {
            Text("MACD (12, 26, 9)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Chart {
                ForEach(Array(histogram.enumerated()), id: \.offset) { i, v in
                    if i < dates.count {
                        BarMark(x: .value("Time", dates[i]), y: .value("Hist", v))
                            .foregroundStyle(v >= 0 ? ZenithColors.positive : ZenithColors.negative)
                    }
                }
                ForEach(Array(macdLine.enumerated()), id: \.offset) { i, v in
                    if i < dates.count {
                        LineMark(x: .value("Time", dates[i]), y: .value("MACD", v))
                            .foregroundStyle(ZenithColors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                ForEach(Array(signalLine.enumerated()), id: \.offset) { i, v in
                    if i < dates.count {
                        LineMark(x: .value("Time", dates[i]), y: .value("Signal", v))
                            .foregroundStyle(ZenithColors.textSecondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
            }
            .chartYScale(domain: (lo - padding) ... (hi + padding))
            .frame(height: 120)
        }
    }

    private var atrSection: some View {
        let atrValues = computeATR(bars, period: 14)
        let dates = bars.compactMap { ISO8601DateFormatter().date(from: $0.t) }
        let yMax = (atrValues.max() ?? 1) * 1.2
        return VStack(alignment: .leading, spacing: 8) {
            Text("ATR (14)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Chart {
                ForEach(Array(atrValues.enumerated()), id: \.offset) { i, v in
                    if i < dates.count {
                        LineMark(x: .value("Time", dates[i]), y: .value("ATR", v))
                            .foregroundStyle(ZenithColors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
            }
            .chartYScale(domain: 0 ... yMax)
            .frame(height: 100)
        }
    }

    private var rsiSection: some View {
        let rsiValues = computeRSI(bars.map(\.c), period: 14)
        let dates = bars.compactMap { ISO8601DateFormatter().date(from: $0.t) }
        return VStack(alignment: .leading, spacing: 8) {
            Text("RSI (14)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Chart {
                ForEach(Array(rsiValues.enumerated()), id: \.offset) { element in
                    let i = element.offset
                    let value = element.element
                    if i < dates.count {
                        LineMark(
                            x: .value("Time", dates[i]),
                            y: .value("RSI", value)
                        )
                        .foregroundStyle(ZenithColors.accent)
                    }
                }
                RuleMark(y: .value("Overbought", 70))
                    .foregroundStyle(ZenithColors.textMuted.opacity(0.5))
                RuleMark(y: .value("Oversold", 30))
                    .foregroundStyle(ZenithColors.textMuted.opacity(0.5))
            }
            .chartYScale(domain: 0 ... 100)
            .frame(height: 120)
        }
    }

    private func loadQuote() async {
        do {
            let list = try await TopstepService.shared.fetchQuotes(contractIds: [contractId])
            quote = list.first
        } catch {
            quote = nil
        }
    }

    private func loadBars() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let end = Date()
        let calendar = Calendar.current
        let start: Date
        if let days = selectedRange.days {
            start = calendar.date(byAdding: .day, value: -days, to: end) ?? end
        } else if selectedRange == .ytd {
            start = calendar.date(from: calendar.dateComponents([.year], from: end)) ?? end
        } else {
            start = calendar.date(byAdding: .day, value: -360, to: end) ?? end
        }
        let (unit, unitNumber) = (selectedAggregation.unit, selectedAggregation.unitNumber)
        let limit = 2000
        do {
            bars = try await TopstepService.shared.fetchBars(contractId: contractId, from: start, to: end, unit: unit, unitNumber: unitNumber, limit: limit)
        } catch {
            errorMessage = error.localizedDescription
            bars = []
        }
    }

    private func computeSMA(_ values: [Double], period: Int) -> [Double] {
        guard period > 0 else { return values }
        var result: [Double] = []
        for i in 0..<values.count {
            if i < period - 1 {
                result.append(values[i])
            } else {
                let slice = values[(i - period + 1)...i]
                result.append(slice.reduce(0, +) / Double(period))
            }
        }
        return result
    }

    private func computeRSI(_ values: [Double], period: Int) -> [Double] {
        guard values.count > period else { return Array(repeating: 50, count: values.count) }
        var result: [Double] = Array(repeating: 50, count: period)
        for i in period..<values.count {
            let gains = (1...period).map { values[i - $0 + 1] - values[i - $0] }.map { max(0, $0) }
            let losses = (1...period).map { values[i - $0 + 1] - values[i - $0] }.map { max(0, -$0) }
            let avgGain = gains.reduce(0, +) / Double(period)
            let avgLoss = losses.reduce(0, +) / Double(period)
            if avgLoss == 0 {
                result.append(100)
            } else {
                let rs = avgGain / avgLoss
                result.append(100 - (100 / (1 + rs)))
            }
        }
        return result
    }

    private func computeEMA(_ values: [Double], period: Int) -> [Double] {
        guard period > 0, !values.isEmpty else { return values }
        let k = 2.0 / Double(period + 1)
        var result: [Double] = []
        var ema: Double = 0
        for i in 0..<values.count {
            if i < period - 1 {
                result.append(values[i])
            } else if i == period - 1 {
                ema = values.prefix(period).reduce(0, +) / Double(period)
                result.append(ema)
            } else {
                ema = values[i] * k + ema * (1 - k)
                result.append(ema)
            }
        }
        return result
    }

    private func computeBollinger(_ closes: [Double], length: Int, mult: Double) -> (upper: [Double], middle: [Double], lower: [Double]) {
        let middle = computeSMA(closes, period: length)
        var upper: [Double] = []
        var lower: [Double] = []
        for i in 0..<closes.count {
            if i < length - 1 {
                upper.append(closes[i])
                lower.append(closes[i])
            } else {
                let slice = Array(closes[(i - length + 1)...i])
                let avg = slice.reduce(0, +) / Double(length)
                let variance = slice.map { ($0 - avg) * ($0 - avg) }.reduce(0, +) / Double(length)
                let std = variance.squareRoot()
                upper.append(middle[i] + mult * std)
                lower.append(middle[i] - mult * std)
            }
        }
        return (upper, middle, lower)
    }

    private func computeVWAP(_ bars: [TopstepService.Bar]) -> [Double] {
        var result: [Double] = []
        var sumPV: Double = 0
        var sumV: Double = 0
        for b in bars {
            let tp = (b.h + b.l + b.c) / 3.0
            sumPV += tp * b.v
            sumV += b.v
            result.append(sumV > 0 ? sumPV / sumV : tp)
        }
        return result
    }

    private func computeMACD(_ closes: [Double], fast: Int, slow: Int, signal: Int) -> (macd: [Double], signal: [Double], hist: [Double]) {
        let fastEMA = computeEMA(closes, period: fast)
        let slowEMA = computeEMA(closes, period: slow)
        var macd: [Double] = []
        for i in 0..<closes.count {
            macd.append(fastEMA[i] - slowEMA[i])
        }
        let signalLine = computeEMA(macd, period: signal)
        let hist = zip(macd, signalLine).map { $0 - $1 }
        return (macd, signalLine, hist)
    }

    private func computeATR(_ bars: [TopstepService.Bar], period: Int) -> [Double] {
        guard bars.count >= 2, period > 0 else { return bars.map { _ in 0.0 } }
        var tr: [Double] = [bars[0].h - bars[0].l]
        for i in 1..<bars.count {
            let prevC = bars[i - 1].c
            let h = bars[i].h
            let l = bars[i].l
            tr.append(max(h - l, abs(h - prevC), abs(l - prevC)))
        }
        var result: [Double] = []
        for i in 0..<tr.count {
            if i < period - 1 {
                result.append(tr.prefix(i + 1).reduce(0, +) / Double(i + 1))
            } else {
                let slice = Array(tr[(i - period + 1)...i])
                result.append(slice.reduce(0, +) / Double(period))
            }
        }
        return result
    }

    private func computeMACrossoverSignals(_ closes: [Double], fast: Int, slow: Int) -> [ChartStrategySignal] {
        guard closes.count > slow else { return [] }
        let fastMA = computeEMA(closes, period: fast)
        let slowMA = computeEMA(closes, period: slow)
        var signals: [ChartStrategySignal] = []
        for i in 1..<closes.count {
            if fastMA[i - 1] <= slowMA[i - 1] && fastMA[i] > slowMA[i] {
                signals.append(ChartStrategySignal(index: i, isBuy: true))
            } else if fastMA[i - 1] >= slowMA[i - 1] && fastMA[i] < slowMA[i] {
                signals.append(ChartStrategySignal(index: i, isBuy: false))
            }
        }
        return signals
    }

    private func computeRSISignals(_ closes: [Double], period: Int, oversold: Double, overbought: Double) -> [ChartStrategySignal] {
        let rsi = computeRSI(closes, period: period)
        var signals: [ChartStrategySignal] = []
        for i in 1..<rsi.count {
            if rsi[i - 1] <= oversold && rsi[i] > oversold {
                signals.append(ChartStrategySignal(index: i, isBuy: true))
            } else if rsi[i - 1] >= overbought && rsi[i] < overbought {
                signals.append(ChartStrategySignal(index: i, isBuy: false))
            }
        }
        return signals
    }

    private func runBacktest(signals: [ChartStrategySignal], bars: [TopstepService.Bar]) -> (trades: Int, pnl: Double, wins: Int) {
        guard signals.count >= 2, bars.count > 0 else { return (0, 0, 0) }
        var position: Bool? = nil
        var entryPrice: Double = 0
        var totalPnl: Double = 0
        var wins = 0
        let sorted = signals.sorted { $0.index < $1.index }
        for sig in sorted {
            guard sig.index < bars.count else { continue }
            let price = bars[sig.index].c
            if sig.isBuy {
                if position == false {
                    totalPnl += price - entryPrice
                    wins += (price > entryPrice) ? 1 : 0
                }
                position = true
                entryPrice = price
            } else {
                if position == true {
                    totalPnl += price - entryPrice
                    wins += (price > entryPrice) ? 1 : 0
                }
                position = false
                entryPrice = price
            }
        }
        let tradeCount = sorted.count
        return (tradeCount, totalPnl, wins)
    }

    private var strategyBacktestCard: some View {
        let maSignals = showMACrossoverStrategy ? computeMACrossoverSignals(bars.map(\.c), fast: 9, slow: 21) : []
        let rsiSignals = showRSIStrategy ? computeRSISignals(bars.map(\.c), period: 14, oversold: 30, overbought: 70) : []
        let allSignals = maSignals + rsiSignals
        let (trades, pnl, wins) = runBacktest(signals: allSignals, bars: bars)
        return ZenithCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy backtest (hypothetical)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ZenithColors.textPrimary)
                HStack(spacing: 16) {
                    Text("Signals: \(allSignals.count)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(ZenithColors.textSecondary)
                    Text("P&L: \(pnl >= 0 ? "+" : "")\(pnl, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(pnl >= 0 ? ZenithColors.positive : ZenithColors.negative)
                    if trades > 0 {
                        Text("Wins: \(wins)/\(trades)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(ZenithColors.textSecondary)
                    }
                }
            }
        }
    }
}

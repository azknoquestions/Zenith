import SwiftUI

struct TradeScreen: View {
    @EnvironmentObject private var session: SessionStore
    @ObservedObject var watchlist: WatchlistStore
    @ObservedObject var contractsStore: ContractsStore
    @Binding var instrumentToTrade: Instrument?
    @State private var positions: [Position] = []
    @State private var orders: [Order] = []
    @State private var trades: [Trade] = []
    @State private var isLoadingPositionsOrders = false
    @State private var isLoadingTrades = false
    @State private var showChart = false
    @State private var tradeSegment: Int = 0

    var body: some View {
        ZStack {
            ZenithColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if session.activeAccountId != nil {
                        Picker("Section", selection: $tradeSegment) {
                            Text("Positions & Orders").tag(0)
                            Text("Trades").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 4)
                        .onChange(of: tradeSegment) { _, new in
                            if new == 1 { Task { await loadTrades() } }
                        }
                    }

                    if let inst = instrumentToTrade, let accountId = session.activeAccountId {
                        HStack {
                            LiveQuoteBar(symbol: inst.symbol, contractId: inst.id.hasPrefix("CON.") ? inst.id : nil)
                            if inst.id.hasPrefix("CON.") {
                                Button {
                                    showChart = true
                                } label: {
                                    Image(systemName: "chart.xyaxis.line")
                                        .font(.system(size: 20))
                                        .foregroundColor(ZenithColors.accent)
                                }
                            }
                        }
                        ZenithCard {
                            OrderTicketView(
                                instrument: inst,
                                accountId: accountId,
                                contractId: inst.id.hasPrefix("CON.") ? inst.id : nil,
                                onOrderPlaced: {
                                    instrumentToTrade = nil
                                    Task { await loadPositionsAndOrders(accountId: accountId) }
                                },
                                onClearInstrument: { instrumentToTrade = nil }
                            )
                        }
                    } else {
                        instrumentPicker
                        ZenithCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select an instrument")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(ZenithColors.textPrimary)
                                Text("Choose a contract below or tap a quote on the Quotes tab to open the order ticket.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(ZenithColors.textSecondary)
                            }
                        }
                    }

                    if tradeSegment == 0 {
                        positionsOrdersSection(accountId: session.activeAccountId)
                    } else {
                        tradesSection(accountId: session.activeAccountId)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if let accountId = session.activeAccountId {
                    await loadPositionsAndOrders(accountId: accountId)
                    if tradeSegment == 1 { await loadTrades() }
                }
                await contractsStore.refresh()
            }
            .task {
                contractsStore.loadIfNeeded()
                if let accountId = session.activeAccountId {
                    await loadPositionsAndOrders(accountId: accountId)
                    if tradeSegment == 1 { await loadTrades() }
                }
            }
            .sheet(isPresented: $showChart) {
                if let inst = instrumentToTrade {
                    ChartView(contractId: inst.id, contractName: inst.symbol)
                }
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .foregroundColor(ZenithColors.accent)
                        .fontWeight(.medium)
                    }
                }
            }
        }
    }

    private func loadPositionsAndOrders(accountId: String) async {
        isLoadingPositionsOrders = true
        defer { isLoadingPositionsOrders = false }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfDay) ?? Date()
        positions = (try? await TopstepService.shared.fetchPositions(accountId: accountId)) ?? []
        orders = (try? await TopstepService.shared.fetchOrders(accountId: accountId, start: startOfDay, end: endOfWeek)) ?? []
    }

    @ViewBuilder
    private func positionsOrdersSection(accountId: String?) -> some View {
        if accountId != nil {
            ZenithCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Open Positions")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ZenithColors.textPrimary)
                    if isLoadingPositionsOrders && positions.isEmpty {
                        ProgressView().scaleEffect(0.9).tint(ZenithColors.textMuted)
                    } else if positions.isEmpty {
                        Text("No open positions")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textSecondary)
                    } else {
                        ForEach(positions) { pos in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pos.contractName)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(ZenithColors.textPrimary)
                                    Text("\(pos.size) @ \(pos.averagePrice, format: .number.precision(.fractionLength(2)))")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(ZenithColors.textMuted)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            ZenithCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Working Orders")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ZenithColors.textPrimary)
                    if isLoadingPositionsOrders && orders.isEmpty {
                        ProgressView().scaleEffect(0.9).tint(ZenithColors.textMuted)
                    } else if orders.isEmpty {
                        Text("No working orders")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textSecondary)
                    } else {
                        ForEach(orders.prefix(20)) { order in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(order.contractName)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(ZenithColors.textPrimary)
                                    Text("\(order.size) · \(orderStatusText(order.status))")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(ZenithColors.textMuted)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        } else {
            ZenithCard {
                Text("Select an account in the menu to see positions and orders.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(ZenithColors.textSecondary)
            }
        }
    }

    private func orderStatusText(_ status: Int) -> String {
        switch status {
        case 0: return "Pending"
        case 1: return "Working"
        case 2: return "Filled"
        case 3: return "Cancelled"
        default: return "—"
        }
    }

    @ViewBuilder
    private func tradesSection(accountId: String?) -> some View {
        if accountId == nil {
            ZenithCard {
                Text("Select an account in the menu to see trades.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(ZenithColors.textSecondary)
            }
        } else {
            ZenithCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Trade History")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ZenithColors.textPrimary)
                if isLoadingTrades && trades.isEmpty {
                    ProgressView().scaleEffect(0.9).tint(ZenithColors.textMuted)
                } else if trades.isEmpty {
                    Text("No trades in this period")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textSecondary)
                } else {
                    ForEach(trades.prefix(50)) { trade in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trade.contractName)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(ZenithColors.textPrimary)
                                if let ts = trade.creationTimestamp, let date = ISO8601DateFormatter().date(from: ts) {
                                    Text(date, style: .date)
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(ZenithColors.textMuted)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(trade.side == 0 ? "Buy" : "Sell")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(trade.side == 0 ? ZenithColors.positive : ZenithColors.negative)
                                Text("\(trade.size) @ \(trade.price, format: .number.precision(.fractionLength(2)))")
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundColor(ZenithColors.textSecondary)
                                if let pl = trade.profitLoss {
                                    Text(pl >= 0 ? "+\(pl, format: .number.precision(.fractionLength(2)))" : "\(pl, format: .number.precision(.fractionLength(2)))")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(pl >= 0 ? ZenithColors.positive : ZenithColors.negative)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    }

    private func loadTrades() async {
        guard let accountId = session.activeAccountId else { return }
        isLoadingTrades = true
        defer { isLoadingTrades = false }
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        trades = (try? await TopstepService.shared.fetchTrades(accountId: accountId, start: start, end: Date())) ?? []
    }

    private var instrumentPicker: some View {
        ZenithCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(contractsStore.contracts.isEmpty ? "Watchlist" : "Contracts")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ZenithColors.textPrimary)
                FlowLayout(spacing: 8) {
                    if !contractsStore.contracts.isEmpty {
                        ForEach(contractsStore.contracts.prefix(30)) { contract in
                            let inst = Instrument(id: contract.id, symbol: contract.name, name: contract.description, assetClass: "Futures")
                            Button {
                                instrumentToTrade = inst
                            } label: {
                                Text(contract.name)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(ZenithColors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(ZenithColors.surfaceElevated)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ForEach(watchlist.symbols, id: \.self) { symbol in
                            let inst = Instrument(id: symbol, symbol: symbol, name: symbol, assetClass: "Futures")
                            Button {
                                instrumentToTrade = inst
                            } label: {
                                Text(symbol)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(ZenithColors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(ZenithColors.surfaceElevated)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

/// Live quote strip for the symbol/contract being traded. Uses contractId when available for ProjectX live data.
struct LiveQuoteBar: View {
    let symbol: String
    var contractId: String? = nil
    @State private var quote: Quote?
    @State private var isLoading = false

    var body: some View {
        ZenithCard {
            HStack {
                Text(symbol)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(ZenithColors.textPrimary)
                Spacer()
                if isLoading {
                    ProgressView().scaleEffect(0.9).tint(ZenithColors.textMuted)
                } else if let q = quote {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(q.lastPrice, format: .number.precision(.fractionLength(2)))
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(ZenithColors.textPrimary)
                        HStack(spacing: 6) {
                            Text(q.netChange, format: .number.precision(.fractionLength(2)))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(q.netChange >= 0 ? ZenithColors.positive : ZenithColors.negative)
                            Text(q.percentChange / 100, format: .percent.precision(.fractionLength(2)))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(q.netChange >= 0 ? ZenithColors.positive : ZenithColors.negative)
                        }
                    }
                } else {
                    Text("—")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(ZenithColors.textMuted)
                }
            }
        }
        .task { await loadQuote() }
    }

    private func loadQuote() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let cid = contractId, !cid.isEmpty {
                let list = try await TopstepService.shared.fetchQuotes(contractIds: [cid])
                quote = list.first
            } else {
                let list = try await TopstepService.shared.fetchQuotes(symbols: [symbol])
                quote = list.first
            }
        } catch {
            quote = nil
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, p) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

struct OrderTicketView: View {
    let instrument: Instrument
    let accountId: String
    var contractId: String? = nil
    var onOrderPlaced: () -> Void
    var onClearInstrument: () -> Void

    @State private var quantity: Double = 1
    @State private var side: OrderSide = .buy
    @State private var type: OrderType = .market
    @State private var limitPrice: String = ""
    @State private var stopPrice: String = ""
    @State private var isSubmitting = false
    @State private var orderResult: String?
    @State private var orderError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(instrument.symbol)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(ZenithColors.textPrimary)
                Spacer()
                Button { onClearInstrument() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ZenithColors.textMuted)
                }
            }

            HStack(spacing: 8) {
                sidePicker
                typePicker
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantity")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                    Stepper(value: $quantity, in: 1...100, step: 1) {
                        Text("\(Int(quantity))")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(ZenithColors.textPrimary)
                    }
                }
                Spacer()
            }

            if type == .limit || type == .stop {
                HStack(spacing: 10) {
                    if type == .limit {
                        ZenithTextField(title: "Limit Price", text: $limitPrice, keyboardType: .decimalPad)
                    }
                    if type == .stop {
                        ZenithTextField(title: "Stop Price", text: $stopPrice, keyboardType: .decimalPad)
                    }
                }
            }

            if let orderResult {
                Text(orderResult)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ZenithColors.positive)
            }
            if let orderError {
                Text(orderError)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ZenithColors.negative)
            }

            Button {
                submitOrder()
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView().progressViewStyle(.circular).tint(ZenithColors.background)
                    } else {
                        Text("Place Order")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .foregroundColor(ZenithColors.background)
                .background(side == .buy ? ZenithColors.positive : ZenithColors.negative)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
    }

    private func submitOrder() {
        orderResult = nil
        orderError = nil
        isSubmitting = true

        let limit = type == .limit ? Double(limitPrice.replacingOccurrences(of: ",", with: "")) : nil
        let stop = type == .stop ? Double(stopPrice.replacingOccurrences(of: ",", with: "")) : nil

        Task {
            do {
                let orderId = try await TopstepService.shared.placeOrder(
                    accountId: accountId,
                    symbol: instrument.symbol,
                    contractId: contractId,
                    side: side,
                    type: type,
                    quantity: Int(quantity),
                    limitPrice: limit,
                    stopPrice: stop
                )
                await MainActor.run {
                    orderResult = "Order placed. ID: \(orderId)"
                    isSubmitting = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onOrderPlaced() }
                }
            } catch {
                await MainActor.run {
                    orderError = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }

    private var sidePicker: some View {
        HStack(spacing: 0) {
            sideToggle(side: .buy, label: "Buy")
            sideToggle(side: .sell, label: "Sell")
        }
        .clipShape(Capsule())
        .overlay(Capsule().stroke(ZenithColors.separator, lineWidth: 1))
    }

    private func sideToggle(side option: OrderSide, label: String) -> some View {
        Button {
            side = option
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(side == option ? (option == .buy ? ZenithColors.positive : ZenithColors.negative) : Color.clear)
                .foregroundColor(side == option ? ZenithColors.background : ZenithColors.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private var typePicker: some View {
        Picker("Type", selection: $type) {
            Text("MKT").tag(OrderType.market)
            Text("LMT").tag(OrderType.limit)
            Text("STP").tag(OrderType.stop)
        }
        .pickerStyle(.segmented)
    }
}

struct ZenithTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textMuted)

            TextField("", text: $text)
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(ZenithColors.textPrimary)
                .keyboardType(keyboardType)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ZenithColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

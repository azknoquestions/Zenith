import SwiftUI

struct QuotesScreen: View {
    @EnvironmentObject private var session: SessionStore
    @ObservedObject var watchlist: WatchlistStore
    @ObservedObject var contractsStore: ContractsStore
    @Binding var instrumentToTrade: Instrument?
    @Binding var selectedTab: ZenithTab
    @State private var quotes: [Quote] = []
    @State private var isLoading = false
    @State private var showAddTicker = false
    @State private var showBrowseContracts = false
    @State private var newSymbol = ""
    @State private var quoteForChart: Quote?

    var body: some View {
        NavigationStack {
            ZStack {
                ZenithColors.background.ignoresSafeArea()

                if watchlist.symbols.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationBarHidden(true)
            .task { await loadQuotes() }
            .refreshable { await loadQuotes() }
            .sheet(isPresented: $showAddTicker) {
                addTickerSheet
            }
            .sheet(item: $quoteForChart) { q in
                ChartView(contractId: q.instrument.id, contractName: q.instrument.symbol)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No symbols in watchlist")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)
            Button { showAddTicker = true } label: {
                Label("Add ticker", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(ZenithColors.accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { showAddTicker = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(ZenithColors.accent)
                }
                .padding(.trailing, 20)
                .padding(.top, 8)
            }

            if isLoading && quotes.isEmpty {
                ProgressView().tint(ZenithColors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(quotes) { quote in
                        Button {
                            instrumentToTrade = quote.instrument
                            selectedTab = .trade
                        } label: {
                            ZenithCard {
                                QuoteRowView(quote: quote)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowBackground(ZenithColors.background)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let toRemove = watchlist.symbols.first(where: { quote.instrument.symbol.uppercased().hasPrefix($0.uppercased()) }) ?? quote.instrument.symbol
                                watchlist.remove(symbol: toRemove)
                            } label: { Label("Remove", systemImage: "trash") }
                        }
                        .contextMenu {
                            if quote.instrument.id.hasPrefix("CON.") {
                                Button { quoteForChart = quote } label: { Label("View Chart", systemImage: "chart.xyaxis.line") }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .onChange(of: watchlist.symbols) { _, _ in Task { await loadQuotes() } }
    }

    private var addTickerSheet: some View {
        NavigationStack {
            ZStack {
                ZenithColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Button {
                            dismissKeyboard()
                            TopstepService.shared.setApiKey(session.topstepApiKey)
                            TopstepService.shared.setUsername(session.topstepUsername)
                            contractsStore.loadIfNeeded()
                            showBrowseContracts.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                Text("Browse Topstep contracts")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                Spacer()
                                Image(systemName: showBrowseContracts ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ZenithColors.textMuted)
                            }
                            .foregroundColor(ZenithColors.textPrimary)
                            .padding(14)
                            .background(ZenithColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        if showBrowseContracts {
                            contractsDropdownContent
                        }

                        Text("Or enter symbol")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Symbol (e.g. ES, NQ, CL)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textMuted)
                            TextField("ES", text: $newSymbol)
                                .font(.system(size: 15, weight: .regular, design: .monospaced))
                                .foregroundColor(ZenithColors.textPrimary)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .keyboardType(.asciiCapable)
                                .submitLabel(.done)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(ZenithColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .padding(.horizontal, 24)

                        Button {
                            dismissKeyboard()
                            watchlist.add(newSymbol)
                            newSymbol = ""
                            showAddTicker = false
                        } label: {
                            Text("Add")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(ZenithColors.background)
                                .background(ZenithColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(newSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 24)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Add ticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismissKeyboard()
                        showAddTicker = false
                    }
                    .foregroundColor(ZenithColors.accent)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { dismissKeyboard() }
                            .foregroundColor(ZenithColors.accent)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    private var contractsDropdownContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if contractsStore.isLoading && contractsStore.contracts.isEmpty {
                HStack {
                    ProgressView().tint(ZenithColors.accent)
                    Text("Loading…")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else if contractsStore.contracts.isEmpty {
                Text("No contracts found. Connect to Topstep in Manage and try again.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(ZenithColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(contractsStore.contracts) { contract in
                            Button {
                                watchlist.add(contract.name)
                                showBrowseContracts = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contract.name)
                                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                            .foregroundColor(ZenithColors.textPrimary)
                                        if !contract.description.isEmpty {
                                            Text(contract.description)
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                .foregroundColor(ZenithColors.textMuted)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(ZenithColors.accent)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(ZenithColors.surface)
                            Divider().background(ZenithColors.surfaceElevated).padding(.leading, 14)
                        }
                    }
                }
                .frame(maxHeight: 280)
                .background(ZenithColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 24)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func loadQuotes() async {
        guard !watchlist.symbols.isEmpty else { quotes = []; return }
        isLoading = true
        defer { isLoading = false }
        do {
            quotes = try await TopstepService.shared.fetchQuotes(symbols: watchlist.symbols)
        } catch {
            quotes = []
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
                Group {
                    if quote.lastPrice == 0 {
                        Text("—")
                    } else {
                        Text(quote.lastPrice, format: .number.precision(.fractionLength(2)))
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(quote.lastPrice == 0 ? ZenithColors.textMuted : ZenithColors.textPrimary)

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

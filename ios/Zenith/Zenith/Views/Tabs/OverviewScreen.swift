//
//  OverviewScreen.swift
//  Zenith
//
//  Overview: orders summary, watchlists, calendar, portfolio digest (Symbol/Industry).
//

import SwiftUI

enum OverviewDigestTab: String, CaseIterable {
    case symbol = "Symbol"
    case industry = "Industry"
}

struct OverviewScreen: View {
    @EnvironmentObject private var session: SessionStore
    @ObservedObject var watchlist: WatchlistStore
    @Binding var selectedTab: ZenithTab

    @State private var orders: [Order] = []
    @State private var positions: [Position] = []
    @State private var events: [EconomicEvent] = []
    @State private var isLoadingOrders = false
    @State private var isLoadingPositions = false
    @State private var isLoadingEvents = false
    @State private var eventsRange: EventsRange = .today
    @State private var digestTab: OverviewDigestTab = .symbol

    private var workingCount: Int { orders.filter { $0.status == 1 }.count }
    private var filledCount: Int { orders.filter { $0.status == 2 }.count }
    private var canceledCount: Int { orders.filter { $0.status == 3 }.count }

    var body: some View {
        ZStack {
            ZenithColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ordersSection
                    watchlistsSection
                    calendarSection
                    portfolioDigestSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .task {
            await loadAll()
        }
        .refreshable {
            await loadAll()
        }
    }

    private var ordersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Orders")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)

            ZenithCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(orders.count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(ZenithColors.textPrimary)
                        Text("total")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textSecondary)
                        Spacer()
                    }
                    HStack(spacing: 12) {
                        orderPill(label: "Working", count: workingCount, color: ZenithColors.accent)
                        orderPill(label: "Filled", count: filledCount, color: ZenithColors.positive)
                        orderPill(label: "Canceled", count: canceledCount, color: ZenithColors.negative)
                    }
                }
            }
            .opacity(isLoadingOrders ? 0.7 : 1)
            .overlay {
                if isLoadingOrders && orders.isEmpty {
                    ProgressView().tint(ZenithColors.accent)
                }
            }
        }
    }

    private func orderPill(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var watchlistsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Watchlists")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)

            ZenithCard {
                Button {
                    selectedTab = .quotes
                } label: {
                    HStack {
                        Image(systemName: "list.star")
                            .font(.system(size: 18))
                            .foregroundColor(ZenithColors.accent)
                        Text("Default")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(ZenithColors.textPrimary)
                        Text("\(watchlist.symbols.count) symbols")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textMuted)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ZenithColors.textMuted)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calendar")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)

            Picker("Range", selection: $eventsRange) {
                ForEach(EventsRange.allCases, id: \.self) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: eventsRange) { _, _ in Task { await loadEvents() } }

            if isLoadingEvents && events.isEmpty {
                ZenithCard {
                    ProgressView().tint(ZenithColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            } else if events.isEmpty {
                ZenithCard {
                    Text("No economic events in this range")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(events.prefix(8)) { event in
                        ZenithCard {
                            EventRowView(event: event)
                        }
                    }
                }
            }
        }
    }

    private var portfolioDigestSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Portfolio Digest")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)

            Picker("Digest", selection: $digestTab) {
                ForEach(OverviewDigestTab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)

            ZenithCard {
                if digestTab == .symbol {
                    if isLoadingPositions && positions.isEmpty {
                        ProgressView().tint(ZenithColors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else if positions.isEmpty {
                        Text("No open positions")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(ZenithColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(positions) { pos in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pos.contractName)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(ZenithColors.textPrimary)
                                        Text("\(pos.size) @ \(pos.averagePrice, format: .number.precision(.fractionLength(2)))")
                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                            .foregroundColor(ZenithColors.textMuted)
                                    }
                                    Spacer()
                                    Text(pos.size > 0 ? "Long" : "Short")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(pos.size > 0 ? ZenithColors.positive : ZenithColors.negative)
                                }
                                .padding(.vertical, 4)
                                if pos.id != positions.last?.id {
                                    Divider().background(ZenithColors.separator)
                                }
                            }
                        }
                    }
                } else {
                    Text("N/A")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
        }
    }

    private func loadAll() async {
        async let o: () = loadOrders()
        async let p: () = loadPositions()
        async let e: () = loadEvents()
        _ = await (o, p, e)
    }

    private func loadOrders() async {
        guard let accountId = session.activeAccountId else { return }
        isLoadingOrders = true
        defer { isLoadingOrders = false }
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        do {
            orders = try await TopstepService.shared.fetchOrders(accountId: accountId, start: start, end: end)
        } catch {
            orders = []
        }
    }

    private func loadPositions() async {
        guard let accountId = session.activeAccountId else { return }
        isLoadingPositions = true
        defer { isLoadingPositions = false }
        do {
            positions = try await TopstepService.shared.fetchPositions(accountId: accountId)
        } catch {
            positions = []
        }
    }

    private func loadEvents() async {
        isLoadingEvents = true
        defer { isLoadingEvents = false }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end: Date
        switch eventsRange {
        case .today:
            end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        case .week:
            end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        }
        do {
            events = try await NewsService.shared.fetchEvents(from: start, to: end)
        } catch {
            events = []
        }
    }
}

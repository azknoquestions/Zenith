import SwiftUI

enum NewsEventsSubTab: String, CaseIterable {
    case news = "News"
    case events = "Events"
}

struct NewsEventsScreen: View {
    @State private var subTab: NewsEventsSubTab = .news

    var body: some View {
        NavigationStack {
            ZStack {
                ZenithColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("", selection: $subTab) {
                        ForEach(NewsEventsSubTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    switch subTab {
                    case .news:
                        NewsContent()
                    case .events:
                        EventsContent()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - News content (extracted from NewsScreen)
private struct NewsContent: View {
    @State private var items: [NewsItem] = []
    @State private var selectedFilter: NewsFilter = .all
    @State private var isLoading: Bool = false
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            if loadError != nil {
                HStack {
                    Text("Couldn't load latest.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(ZenithColors.textSecondary)
                    Button("Retry") { Task { await loadNews() } }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ZenithColors.accent)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(ZenithColors.surface.opacity(0.8))
            }
            filterChips

            if isLoading && items.isEmpty {
                ProgressView()
                    .tint(ZenithColors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                Text("No news available")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(ZenithColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            ZenithCard {
                                NewsRowView(item: item)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .task { await loadNews() }
        .refreshable { await loadNews() }
    }

    private var filteredItems: [NewsItem] {
        switch selectedFilter {
        case .all: return items
        case .macro: return items.filter { $0.headline.localizedCaseInsensitiveContains("CPI") || $0.headline.localizedCaseInsensitiveContains("FOMC") }
        case .fx: return items.filter { $0.symbols.contains(where: { $0.contains("USD") || $0.contains("EUR") }) }
        case .equities: return items.filter { $0.symbols.contains(where: { $0.contains("ES") || $0.contains("NQ") }) }
        case .rates: return items.filter { $0.headline.localizedCaseInsensitiveContains("yield") || $0.headline.localizedCaseInsensitiveContains("Treasury") }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(NewsFilter.allCases, id: \.self) { filter in
                    let isSelected = filter == selectedFilter
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(isSelected ? ZenithColors.background : ZenithColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? ZenithColors.accent : ZenithColors.surface)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
        .background(ZenithColors.background)
    }

    private func loadNews() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let fetched = try await NewsService.shared.fetchHeadlines()
            items = fetched
        } catch {
            loadError = error.localizedDescription
            items = NewsEventsDemoNews.sample
        }
    }
}

// MARK: - Events content (extracted from EventsScreen)
private struct EventsContent: View {
    @State private var events: [EconomicEvent] = []
    @State private var isLoading: Bool = false
    @State private var range: EventsRange = .today

    var body: some View {
        VStack(spacing: 0) {
            Picker("Range", selection: $range) {
                ForEach(EventsRange.allCases, id: \.self) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .onChange(of: range) { _, _ in Task { await loadEvents() } }

            Group {
                if isLoading && events.isEmpty {
                    ProgressView()
                        .tint(ZenithColors.accent)
                } else if events.isEmpty && !isLoading {
                    Text("No economic events in this range")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(ZenithColors.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(events) { event in
                                ZenithCard {
                                    EventRowView(event: event)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .task { await loadEvents() }
        .refreshable { await loadEvents() }
    }

    private func loadEvents() async {
        isLoading = true
        defer { isLoading = false }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end: Date
        switch range {
        case .today:
            end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        case .week:
            end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        }
        do {
            events = try await NewsService.shared.fetchEvents(from: start, to: end)
        } catch {
            events = NewsEventsDemoEvents.sample
        }
    }
}

// MARK: - Shared types (from NewsScreen / EventsScreen)
private enum NewsFilter: CaseIterable {
    case all, macro, fx, equities, rates
    var title: String {
        switch self {
        case .all: return "All"
        case .macro: return "Macro"
        case .fx: return "FX"
        case .equities: return "Equities"
        case .rates: return "Rates"
        }
    }
}

private struct NewsRowView: View {
    let item: NewsItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.headline)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
            Text(item.summary)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textSecondary)
                .lineLimit(3)
            HStack {
                Text(item.source.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(ZenithColors.textMuted)
                Circle().fill(ZenithColors.separator).frame(width: 4, height: 4)
                Text(item.publishedAt, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(ZenithColors.textMuted)
                Spacer()
                if !item.symbols.isEmpty {
                    Text(item.symbols.joined(separator: ", "))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(ZenithColors.textMuted)
                }
            }
        }
    }
}

private enum NewsEventsDemoNews {
    static let sample: [NewsItem] = [
        NewsItem(id: "1", headline: "FOMC holds rates steady, signals data‑dependent path", source: "Finnhub", publishedAt: Date().addingTimeInterval(-60 * 40), summary: "The Federal Reserve kept its benchmark rate unchanged while emphasizing incoming inflation and labor data as key drivers for future decisions.", symbols: ["ES", "NQ", "ZN"]),
        NewsItem(id: "2", headline: "US CPI edges higher, core remains contained", source: "Trading Economics", publishedAt: Date().addingTimeInterval(-60 * 90), summary: "Headline CPI came in slightly above consensus, but core inflation stayed broadly in line, easing concerns over a sharp re‑acceleration.", symbols: ["DX-Y.NYB", "GC"])
    ]
}

private enum NewsEventsDemoEvents {
    static let sample: [EconomicEvent] = [
        EconomicEvent(id: "cpi", time: Date().addingTimeInterval(60 * 30), country: "US", name: "Consumer Price Index (YoY)", importance: "High", previous: "3.1%", forecast: "3.0%", actual: nil),
        EconomicEvent(id: "jobless", time: Date().addingTimeInterval(60 * 120), country: "US", name: "Initial Jobless Claims", importance: "Medium", previous: "215K", forecast: "220K", actual: nil)
    ]
}

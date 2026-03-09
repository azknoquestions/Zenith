import SwiftUI

struct EventsScreen: View {
    @State private var events: [EconomicEvent] = []
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                ZenithColors.background.ignoresSafeArea()

                content
            }
            .navigationBarHidden(true)
            .task {
                await loadEvents()
            }
        }
    }

    private var content: some View {
        Group {
            if isLoading && events.isEmpty {
                ProgressView()
                    .tint(ZenithColors.accent)
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

    private func loadEvents() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await NewsService.shared.fetchEvents()
            events = fetched
        } catch {
            events = DemoEvents.sample
        }
    }
}

struct EventRowView: View {
    let event: EconomicEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.time, style: .time)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(ZenithColors.textPrimary)

                Text(event.country)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(ZenithColors.textMuted)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(event.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(ZenithColors.textPrimary)

                HStack(spacing: 8) {
                    importanceBadge

                    if let previous = event.previous {
                        MetricPill(label: "Prev", value: previous)
                    }
                    if let forecast = event.forecast {
                        MetricPill(label: "Fcst", value: forecast)
                    }
                    if let actual = event.actual {
                        MetricPill(label: "Act", value: actual)
                    }
                }
            }

            Spacer()
        }
    }

    private var importanceBadge: some View {
        let color: Color
        switch event.importance.lowercased() {
        case "high": color = ZenithColors.negative
        case "medium": color = ZenithColors.accent
        default: color = ZenithColors.textMuted
        }

        return Text(event.importance.capitalized)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(ZenithColors.background)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

private enum DemoEvents {
    static let sample: [EconomicEvent] = [
        EconomicEvent(
            id: "cpi",
            time: Date().addingTimeInterval(60 * 30),
            country: "US",
            name: "Consumer Price Index (YoY)",
            importance: "High",
            previous: "3.1%",
            forecast: "3.0%",
            actual: nil
        ),
        EconomicEvent(
            id: "jobless",
            time: Date().addingTimeInterval(60 * 120),
            country: "US",
            name: "Initial Jobless Claims",
            importance: "Medium",
            previous: "215K",
            forecast: "220K",
            actual: nil
        )
    ]
}


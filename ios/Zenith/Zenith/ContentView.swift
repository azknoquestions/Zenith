//
//  ContentView.swift
//  Zenith
//
//  Created by Zakary Claiborne on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var watchlist = WatchlistStore()
    @StateObject private var contractsStore = ContractsStore()
    @State private var selectedTab: ZenithTab = .overview
    @State private var instrumentToTrade: Instrument?
    @State private var isMenuPresented: Bool = false
    @State private var isAIPresented: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZenithTopBar(
                    title: selectedTab.title,
                    subtitle: session.activeAccountName,
                    onMenuTap: { withAnimation(.easeOut) { isMenuPresented = true } },
                    onAccountTap: { withAnimation(.easeOut) { isMenuPresented = true } }
                )

                TabView(selection: $selectedTab) {
                    OverviewScreen(watchlist: watchlist, selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "square.grid.2x2")
                            Text("Overview")
                        }
                        .tag(ZenithTab.overview)

                    QuotesScreen(watchlist: watchlist, contractsStore: contractsStore, instrumentToTrade: $instrumentToTrade, selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Quotes")
                        }
                        .tag(ZenithTab.quotes)

                    TradeScreen(watchlist: watchlist, contractsStore: contractsStore, instrumentToTrade: $instrumentToTrade)
                        .tabItem {
                            Image(systemName: "arrow.up.arrow.down.square")
                            Text("Trade")
                        }
                        .tag(ZenithTab.trade)

                    NewsEventsScreen()
                        .tabItem {
                            Image(systemName: "newspaper")
                            Text("News")
                        }
                        .tag(ZenithTab.newsEvents)

                    ManageScreen(selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Manage")
                        }
                        .tag(ZenithTab.manage)
                }
                .tint(ZenithColors.accent)
                .background(ZenithColors.background.ignoresSafeArea())
            }

            if isMenuPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeIn) { isMenuPresented = false }
                    }

                SideMenuView(isPresented: $isMenuPresented) { tab in
                    selectedTab = tab
                    isMenuPresented = false
                }
                .transition(.move(edge: .leading))
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZenithAIButton {
                        withAnimation(.spring()) {
                            isAIPresented.toggle()
                        }
                    }
                    .padding(.trailing, 20)
                    // lift the AI button above the tab bar so it doesn't cover labels
                    .padding(.bottom, 80)
                }
            }
        }
        .sheet(isPresented: $isAIPresented) {
            AIAssistantSheet(isPresented: $isAIPresented)
                .environmentObject(session)
        }
        .onAppear {
            TopstepService.shared.setApiKey(session.topstepApiKey)
            TopstepService.shared.setUsername(session.topstepUsername)
            contractsStore.loadIfNeeded()
        }
        .onChange(of: session.topstepConnectionState) { _, new in
            if case .connected = new { contractsStore.loadIfNeeded() }
        }
        .preferredColorScheme(.dark)
    }
}

enum ZenithTab: Hashable {
    case overview, quotes, trade, newsEvents, manage

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .quotes: return "Quotes"
        case .trade: return "Trade"
        case .newsEvents: return "News"
        case .manage: return "Manage"
        }
    }
}

//
//  ContentView.swift
//  Zenith
//
//  Created by Zakary Claiborne on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var selectedTab: ZenithTab = .quotes
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
                    QuotesScreen()
                        .tabItem {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Quotes")
                        }
                        .tag(ZenithTab.quotes)

                    NewsScreen()
                        .tabItem {
                            Image(systemName: "newspaper")
                            Text("News")
                        }
                        .tag(ZenithTab.news)

                    EventsScreen()
                        .tabItem {
                            Image(systemName: "calendar")
                            Text("Events")
                        }
                        .tag(ZenithTab.events)

                    TradeScreen()
                        .tabItem {
                            Image(systemName: "arrow.up.arrow.down.square")
                            Text("Trade")
                        }
                        .tag(ZenithTab.trade)

                    ManageScreen()
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

                SideMenuView(isPresented: $isMenuPresented)
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
        .preferredColorScheme(.dark)
    }
}

enum ZenithTab: Hashable {
    case quotes, news, events, trade, manage

    var title: String {
        switch self {
        case .quotes: return "Quotes"
        case .news: return "News"
        case .events: return "Events"
        case .trade: return "Trade"
        case .manage: return "Manage"
        }
    }
}

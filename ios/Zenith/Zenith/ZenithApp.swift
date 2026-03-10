//
//  ZenithApp.swift
//  Zenith
//
//  Created by Zakary Claiborne on 3/8/26.
//

import SwiftUI

@main
struct ZenithApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
        }
    }
}

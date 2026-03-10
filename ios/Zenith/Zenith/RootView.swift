//
//  RootView.swift
//  Zenith
//
//  Shows onboarding on first launch, main app once Topstep key has been added.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        if session.hasCompletedOnboarding {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}

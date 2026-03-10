//
//  ContractsStore.swift
//  Zenith
//
//  App-wide store for Topstep contracts (tickers). Used by Quotes (browse/add) and Trade (instrument picker).
//

import Foundation
import Combine

private let cacheTTL: TimeInterval = 5 * 60 // 5 minutes

/// Holds the list of contracts available from Topstep. Load when user has connected Topstep.
final class ContractsStore: ObservableObject {
    @Published var contracts: [Contract] = []
    @Published var isLoading = false

    private var lastLoadTime: Date?
    private var loadTask: Task<Void, Never>?

    /// Fetches contracts from Topstep if not recently loaded. Call when entering Quotes/Trade or after connecting Topstep.
    func loadIfNeeded() {
        if let last = lastLoadTime, Date().timeIntervalSince(last) < cacheTTL, !contracts.isEmpty {
            return
        }
        loadTask?.cancel()
        loadTask = Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            do {
                let list = try await TopstepService.shared.fetchContracts()
                if !Task.isCancelled {
                    self.contracts = list
                    self.lastLoadTime = Date()
                }
            } catch {
                if !Task.isCancelled {
                    self.contracts = []
                }
            }
        }
    }

    /// Force refresh (e.g. on pull-to-refresh). Call and await from the view.
    func refresh() async {
        lastLoadTime = nil
        loadTask?.cancel()
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        do {
            let list = try await TopstepService.shared.fetchContracts()
            await MainActor.run {
                self.contracts = list
                self.lastLoadTime = Date()
            }
        } catch {
            await MainActor.run { self.contracts = [] }
        }
    }
}

import Foundation
import SwiftUI
import Combine

private let kDailyLossLimit = "RiskSettingsDailyLossLimit"
private let kMaxPositionSize = "RiskSettingsMaxPositionSize"

final class RiskSettingsStore: ObservableObject {
    @Published var dailyLossLimit: Double {
        didSet {
            UserDefaults.standard.set(dailyLossLimit, forKey: kDailyLossLimit)
        }
    }

    @Published var maxPositionSize: Int {
        didSet {
            UserDefaults.standard.set(maxPositionSize, forKey: kMaxPositionSize)
        }
    }

    init() {
        self.dailyLossLimit = UserDefaults.standard.object(forKey: kDailyLossLimit) as? Double ?? 0
        self.maxPositionSize = UserDefaults.standard.integer(forKey: kMaxPositionSize)
        if maxPositionSize <= 0 {
            self.maxPositionSize = 10
            UserDefaults.standard.set(10, forKey: kMaxPositionSize)
        }
    }
}

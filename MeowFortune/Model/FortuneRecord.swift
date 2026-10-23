import Foundation
import SwiftData

/// 存進 SwiftData 的抽籤紀錄
@Model
final class FortuneRecord {
    var date: Date
    var fortuneID: Int
    var levelRaw: String
    var isDaily: Bool

    init(date: Date, fortune: Fortune, isDaily: Bool) {
        self.date = date
        self.fortuneID = fortune.id
        self.levelRaw = fortune.level.rawValue
        self.isDaily = isDaily
    }

    var level: FortuneLevel { FortuneLevel(rawValue: levelRaw) ?? .fair }
    var fortune: Fortune? { Fortune.byID(fortuneID) }
}

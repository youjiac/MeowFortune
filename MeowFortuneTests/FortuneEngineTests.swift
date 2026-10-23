import Foundation
import Testing
import SwiftData
@testable import MeowFortune

struct FortuneEngineTests {
    var engine: FortuneEngine {
        var e = FortuneEngine()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
        e.calendar = cal
        return e
    }

    let day = Date(timeIntervalSince1970: 1_792_684_800)   // 2026-10-22 16:00 UTC = 10/23 00:00 台北

    @Test func fnv1aMatchesReferenceVectors() {
        // FNV-1a 64-bit 官方測試向量
        #expect(FortuneEngine.fnv1a("") == 0xcbf2_9ce4_8422_2325)
        #expect(FortuneEngine.fnv1a("a") == 0xaf63_dc4c_8601_ec8c)
        #expect(FortuneEngine.fnv1a("foobar") == 0x8594_4171_f739_67e8)
    }

    @Test func dailyFortuneIsStableWithinADay() {
        let morning = engine.dailyFortune(for: "Zach", on: day.addingTimeInterval(8 * 3600))
        let night = engine.dailyFortune(for: "Zach", on: day.addingTimeInterval(23 * 3600))
        #expect(morning == night)
    }

    @Test func dailyFortuneIgnoresNameCase() {
        #expect(engine.dailyFortune(for: "zach", on: day) == engine.dailyFortune(for: "ZACH", on: day))
    }

    @Test func dailyFortuneVariesAcrossDays() {
        let results = Set((0..<30).map { engine.dailyFortune(for: "Zach", on: day.addingTimeInterval(Double($0) * 86_400)).id })
        #expect(results.count > 5)
    }

    @Test func dayKeyUsesCalendarTimeZone() {
        #expect(engine.dayKey(for: day) == "2026-10-23")
        #expect(engine.dayKey(for: day.addingTimeInterval(-1)) == "2026-10-22")
    }

    @Test func weightedDrawRoughlyMatchesWeights() {
        var rng = SplitMix64(seed: 42)
        let n = 20_000
        var counts: [FortuneLevel: Int] = [:]
        for _ in 0..<n { counts[engine.draw(using: &rng).level, default: 0] += 1 }
        for level in FortuneLevel.allCases {
            let share = Double(counts[level, default: 0]) / Double(n) * 100
            #expect(abs(share - Double(level.weight)) < 1.5, "\(level.rawValue): \(share)%")
        }
    }

    @Test func weightsSumTo100AndEveryLevelHasFortunes() {
        #expect(FortuneLevel.allCases.reduce(0) { $0 + $1.weight } == 100)
        for level in FortuneLevel.allCases {
            #expect(Fortune.all.contains { $0.level == level })
        }
        #expect(Set(Fortune.all.map(\.id)).count == Fortune.all.count)
    }
}

struct StreakTests {
    var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Taipei")!
        return c
    }
    let now = Date(timeIntervalSince1970: 1_792_717_200)   // 2026-10-23 01:00 UTC = 09:00 台北

    func daysAgo(_ n: Int) -> Date { now.addingTimeInterval(Double(-n) * 86_400) }

    @Test func emptyIsZero() {
        #expect(Streak.current(dates: [], now: now, calendar: cal) == 0)
    }

    @Test func countsConsecutiveDaysIncludingToday() {
        #expect(Streak.current(dates: [daysAgo(0), daysAgo(1), daysAgo(2), daysAgo(4)], now: now, calendar: cal) == 3)
    }

    @Test func notDrawingTodayKeepsYesterdaysStreak() {
        #expect(Streak.current(dates: [daysAgo(1), daysAgo(2)], now: now, calendar: cal) == 2)
    }

    @Test func gapOfTwoDaysResets() {
        #expect(Streak.current(dates: [daysAgo(2), daysAgo(3)], now: now, calendar: cal) == 0)
    }

    @Test func multipleDrawsSameDayCountOnce() {
        let dates = [now, now.addingTimeInterval(-60), now.addingTimeInterval(-3600), daysAgo(1)]
        #expect(Streak.current(dates: dates, now: now, calendar: cal) == 2)
    }
}

@MainActor
struct FortuneRecordTests {
    @Test func persistsInSwiftData() throws {
        let container = try ModelContainer(for: FortuneRecord.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let fortune = Fortune.all[3]
        context.insert(FortuneRecord(date: .now, fortune: fortune, isDaily: true))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<FortuneRecord>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.fortune == fortune)
        #expect(fetched.first?.level == fortune.level)
    }
}

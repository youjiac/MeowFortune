import Foundation

/// 抽籤引擎：
/// - 「今日籤」：用 FNV-1a 雜湊（名字 + 日期）當種子，同一天同一個人永遠抽到同一支
/// - 「再抽一次」：一般亂數
/// 兩者都依 FortuneLevel.weight 加權。
struct FortuneEngine {
    var fortunes: [Fortune] = Fortune.all
    var calendar: Calendar = .current

    /// FNV-1a 64-bit：簡單、穩定、跨裝置結果一致（不像 Hasher 每次啟動都不同）
    static func fnv1a(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    func dayKey(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func dailyFortune(for name: String, on date: Date) -> Fortune {
        var rng = SplitMix64(seed: Self.fnv1a("\(name.lowercased())|\(dayKey(for: date))"))
        return draw(using: &rng)
    }

    func randomFortune() -> Fortune {
        var rng = SystemRandomNumberGenerator()
        return draw(using: &rng)
    }

    /// 加權抽籤：先依權重選等級，再從該等級的籤裡選一支
    func draw<G: RandomNumberGenerator>(using rng: inout G) -> Fortune {
        let total = FortuneLevel.allCases.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total, using: &rng)
        var level = FortuneLevel.fair
        for candidate in FortuneLevel.allCases {
            if roll < candidate.weight { level = candidate; break }
            roll -= candidate.weight
        }
        let pool = fortunes.filter { $0.level == level }
        return pool.randomElement(using: &rng) ?? fortunes[0]
    }
}

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// 連續抽籤天數：今天（或昨天）往回數，每天至少抽一次就算連續
enum Streak {
    static func current(dates: [Date], now: Date, calendar: Calendar = .current) -> Int {
        let days = Set(dates.map { calendar.startOfDay(for: $0) })
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) {
            // 今天還沒抽不會中斷連續紀錄，從昨天開始算
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day), days.contains(yesterday) else { return 0 }
            day = yesterday
        }
        var count = 0
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}

import Foundation

/// 籤的等級。rawValue 存進資料庫；weight 決定隨機抽中的機率。
enum FortuneLevel: String, CaseIterable, Codable, Identifiable {
    case great = "大吉"
    case good = "中吉"
    case small = "小吉"
    case fair = "吉"
    case late = "末吉"
    case bad = "凶"

    var id: String { rawValue }

    /// 抽中權重（總和 100）
    var weight: Int {
        switch self {
        case .great: 12
        case .good: 22
        case .small: 24
        case .fair: 20
        case .late: 14
        case .bad: 8
        }
    }

    var imageName: String {
        switch self {
        case .great: "cat_lucky"
        case .good, .small, .fair: "cat_happy"
        case .late, .bad: "cat_sleepy"
        }
    }

    /// 0（凶）... 5（大吉），用來畫圖表與比較
    var score: Int { FortuneLevel.allCases.count - 1 - FortuneLevel.allCases.firstIndex(of: self)! }
}

/// 一支籤
struct Fortune: Identifiable, Equatable {
    let id: Int
    let level: FortuneLevel
    let message: String
    let advice: String
    let luckyItem: String

    static let all: [Fortune] = [
        Fortune(id: 0, level: .great, message: "今天的你像剛曬完太陽的貓，閃閃發亮。", advice: "大膽去做一直想做的事！", luckyItem: "毛線球"),
        Fortune(id: 1, level: .great, message: "連貓咪都主動來蹭你，好運擋不住。", advice: "今天適合告白或面試。", luckyItem: "小魚乾"),
        Fortune(id: 2, level: .good, message: "好事會在轉角等你，記得抬頭看看。", advice: "跟朋友分享一個小點心。", luckyItem: "便利商店集點卡"),
        Fortune(id: 3, level: .good, message: "努力了很久的事，今天會有回音。", advice: "記得回覆那封還沒回的訊息。", luckyItem: "藍色原子筆"),
        Fortune(id: 4, level: .small, message: "慢慢來也沒關係，貓咪也是走一步停三步。", advice: "把今天的待辦清單砍一半。", luckyItem: "耳機"),
        Fortune(id: 5, level: .small, message: "小小的驚喜藏在日常裡。", advice: "走一條沒走過的路回家。", luckyItem: "雨傘"),
        Fortune(id: 6, level: .fair, message: "平凡的一天，也有平凡的幸福。", advice: "喝杯溫熱的飲料吧。", luckyItem: "保溫瓶"),
        Fortune(id: 7, level: .fair, message: "今天適合整理，桌面乾淨了心也會。", advice: "清一下手機相簿。", luckyItem: "便利貼"),
        Fortune(id: 8, level: .late, message: "有點累了嗎？貓咪說：先睡再說。", advice: "今晚早點睡，明天會更好。", luckyItem: "眼罩"),
        Fortune(id: 9, level: .late, message: "運氣在充電中，再等一下下。", advice: "今天不要做重大決定。", luckyItem: "行動電源"),
        Fortune(id: 10, level: .bad, message: "小心踩到貓咪的尾巴……還有作業的截止日。", advice: "先把最急的作業交了！", luckyItem: "行事曆"),
        Fortune(id: 11, level: .bad, message: "貓咪把你的杯子推下桌了，但也只是個杯子。", advice: "壞事來了也會走，深呼吸。", luckyItem: "抱枕"),
    ]

    static func byID(_ id: Int) -> Fortune? { all.first { $0.id == id } }
}

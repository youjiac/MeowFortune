import SwiftUI
import SwiftData
import Charts

/// 紀錄頁：SwiftData 讀出所有抽籤紀錄，Swift Charts 顯示各等級次數與連續天數
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FortuneRecord.date, order: .reverse) private var records: [FortuneRecord]

    struct LevelCount: Identifiable {
        let level: FortuneLevel
        let count: Int
        var id: FortuneLevel { level }
    }

    private var counts: [LevelCount] {
        FortuneLevel.allCases.map { level in LevelCount(level: level, count: records.filter { $0.level == level }.count) }
    }

    private var streak: Int { Streak.current(dates: records.map(\.date), now: .now) }

    private var luckiest: FortuneLevel? {
        counts.filter { $0.count > 0 }.max { $0.count < $1.count }?.level
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView("還沒有紀錄", systemImage: "pawprint",
                                           description: Text("去「抽籤」分頁抽第一支籤吧！"))
                } else {
                    List {
                        Section {
                            HStack(spacing: 12) {
                                SummaryTile(title: "連續天數", value: "\(streak)", symbol: "flame.fill", tint: .orange)
                                SummaryTile(title: "總共抽了", value: "\(records.count)", symbol: "number", tint: .accentColor)
                                SummaryTile(title: "最常抽到", value: luckiest?.rawValue ?? "—", symbol: "star.fill", tint: .yellow)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }

                        Section("各等級次數") {
                            Chart(counts) { item in
                                BarMark(x: .value("等級", item.level.rawValue), y: .value("次數", item.count))
                                    .foregroundStyle(Color.accentColor.gradient)
                                    .cornerRadius(6)
                                    .annotation(position: .top) {
                                        if item.count > 0 {
                                            Text("\(item.count)").font(.caption2).foregroundStyle(.secondary)
                                        }
                                    }
                            }
                            .chartYAxis(.hidden)
                            .frame(height: 180)
                            .accessibilityLabel(counts.map { "\($0.level.rawValue) \($0.count) 次" }.joined(separator: "，"))
                        }

                        Section("最近") {
                            ForEach(records) { record in
                                HistoryRow(record: record)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
            }
            .navigationTitle("紀錄")
            .toolbar {
                if !records.isEmpty { EditButton() }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(records[index]) }
    }
}

struct SummaryTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(value).font(.huninn(24))
            Text(title).font(.huninn(12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct HistoryRow: View {
    let record: FortuneRecord

    var body: some View {
        HStack(spacing: 12) {
            Text(record.level.rawValue)
                .font(.huninn(20))
                .frame(width: 52)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.fortune?.message ?? "").font(.huninn(15)).lineLimit(1)
                HStack(spacing: 6) {
                    Text(record.date, format: .dateTime.month().day().hour().minute())
                    if record.isDaily {
                        Text("今日籤")
                            .padding(.horizontal, 6)
                            .background(Color.accentColor.opacity(0.15), in: .capsule)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = try! ModelContainer(for: FortuneRecord.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    for i in 0..<12 {
        container.mainContext.insert(FortuneRecord(date: .now.addingTimeInterval(Double(-i) * 86_400),
                                                   fortune: Fortune.all[i % Fortune.all.count], isDaily: i % 2 == 0))
    }
    return HistoryView().modelContainer(container)
}

import SwiftUI

/// 籤卡：畫面顯示與分享圖片共用同一個 view
struct FortuneCardView: View {
    let fortune: Fortune
    let name: String
    let date: Date

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(date, format: .dateTime.year().month().day())
                Spacer()
                Text(name.isEmpty ? "喵喵籤" : "\(name) 的籤")
            }
            .font(.huninn(14))
            .foregroundStyle(.secondary)

            Text(fortune.level.rawValue)
                .font(.huninn(72))
                .foregroundStyle(Color.accentColor)

            Image(fortune.level.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 180)
                .accessibilityHidden(true)

            Text(fortune.message)
                .font(.huninn(20))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ink)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label(fortune.advice, systemImage: "pawprint.fill")
                Label("幸運小物：\(fortune.luckyItem)", systemImage: "gift.fill")
            }
            .font(.huninn(16))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(.background, in: .rect(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(Color.accentColor.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        }
        .shadow(color: .orange.opacity(0.18), radius: 14, y: 8)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    FortuneCardView(fortune: Fortune.all[0], name: "Zach", date: .now).padding()
}

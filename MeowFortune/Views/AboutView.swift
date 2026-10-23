import SwiftUI

/// 關於這個 App
struct AboutView: View {
    @AppStorage("userName") private var userName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image("cat_lucky")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading) {
                            Text("喵喵心情籤").font(.huninn(22))
                            Text("版本 2.0").font(.huninn(14)).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("使用者") {
                    LabeledContent("名字", value: userName.isEmpty ? "未設定" : userName)
                    Button("更換名字", role: .destructive) { userName = "" }
                }
                Section("技術") {
                    Label("今日籤：FNV-1a 雜湊 + SplitMix64 亂數", systemImage: "number")
                    Label("SwiftData 儲存紀錄、Swift Charts 統計", systemImage: "cylinder.split.1x2")
                    Label("ImageRenderer 產生分享圖片", systemImage: "square.and.arrow.up")
                    Label("搖一搖抽籤、AVAudioPlayer 音效", systemImage: "iphone.radiowaves.left.and.right")
                }
                Section("籤筒裡有") {
                    ForEach(FortuneLevel.allCases) { level in
                        LabeledContent(level.rawValue, value: "機率 \(level.weight)%")
                    }
                }
                Section("素材") {
                    Label("字型：jf open 粉圓 (OFL)", systemImage: "textformat")
                    Label("網路照片：cataas.com", systemImage: "photo")
                    Label("插圖與音效：本專案原創", systemImage: "paintbrush")
                }
            }
            .navigationTitle("關於")
        }
    }
}

#Preview {
    AboutView()
}

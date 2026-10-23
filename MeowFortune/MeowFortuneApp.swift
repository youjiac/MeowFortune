import SwiftUI
import SwiftData

@main
struct MeowFortuneApp: App {
    init() {
        // 在 App 啟動時註冊專案裡的 jf open 粉圓字型
        FontLoader.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: FortuneRecord.self)
    }
}

/// App 的四個主要頁面（iOS 18 Tab API）
struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("抽籤", systemImage: "sparkles") { DrawView() }
            Tab("紀錄", systemImage: "chart.bar.xaxis") { HistoryView() }
            Tab("貓咪圖庫", systemImage: "photo.on.rectangle") { GalleryView() }
            Tab("關於", systemImage: "info.circle") { AboutView() }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: FortuneRecord.self, inMemory: true)
}

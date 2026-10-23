import SwiftUI
import SwiftData

/// 抽籤頁：每天一支「今日籤」（同一天固定），可以再抽、搖手機抽、分享成圖片
struct DrawView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \FortuneRecord.date, order: .reverse) private var records: [FortuneRecord]
    @AppStorage("userName") private var userName = ""

    @State private var current: Fortune?
    @State private var isDrawing = false
    @State private var shakeTrigger = 0
    @State private var revealTrigger = 0
    @State private var shareImage: Image?
    @State private var nameDraft = ""

    private let engine = FortuneEngine()

    private var todaysDaily: FortuneRecord? {
        records.first { $0.isDaily && Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if userName.isEmpty {
                        NamePrompt(draft: $nameDraft) { userName = $0 }
                    }

                    if let current, !isDrawing {
                        FortuneCardView(fortune: current, name: userName, date: .now)
                            .transition(.asymmetric(insertion: .scale(scale: 0.6).combined(with: .opacity),
                                                    removal: .opacity))
                            .id(revealTrigger)
                    } else {
                        FortuneTube(isDrawing: isDrawing, trigger: shakeTrigger, reduceMotion: reduceMotion)
                    }

                    VStack(spacing: 12) {
                        Button(action: drawDaily) {
                            Label(todaysDaily == nil ? "抽今日籤" : "看今日籤", systemImage: "sun.max.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PawButtonStyle(prominent: true))

                        HStack(spacing: 12) {
                            Button(action: drawAgain) {
                                Label("再抽一次", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PawButtonStyle(prominent: false))

                            if let shareImage {
                                ShareLink(item: shareImage,
                                          preview: SharePreview("我的喵喵籤", image: shareImage)) {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PawButtonStyle(prominent: false))
                            }
                        }
                    }
                    .disabled(isDrawing || userName.isEmpty)

                    Label("也可以搖一搖手機抽籤", systemImage: "iphone.radiowaves.left.and.right")
                        .font(.huninn(14))
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .background(Color.creamBG)
            .navigationTitle("喵喵心情籤")
            .onShake { if !isDrawing && !userName.isEmpty { drawAgain() } }
            .onAppear {
                if current == nil, let daily = todaysDaily?.fortune { current = daily }
            }
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: shakeTrigger)
        .sensoryFeedback(.success, trigger: revealTrigger)
    }

    // MARK: - Actions

    private func drawDaily() {
        if let daily = todaysDaily?.fortune {
            reveal(daily, record: false, daily: true)
        } else {
            reveal(engine.dailyFortune(for: userName, on: .now), record: true, daily: true)
        }
    }

    private func drawAgain() {
        reveal(engine.randomFortune(), record: true, daily: false)
    }

    /// 先搖籤筒 0.9 秒，再翻出結果（用 Task 等待，不用 DispatchQueue）
    private func reveal(_ fortune: Fortune, record: Bool, daily: Bool) {
        Task {
            withAnimation(.snappy) { isDrawing = true }
            shakeTrigger += 1
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 900))
            if record {
                context.insert(FortuneRecord(date: .now, fortune: fortune, isDaily: daily))
            }
            SoundPlayer.shared.playChime()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                current = fortune
                isDrawing = false
                revealTrigger += 1
            }
            shareImage = renderShareImage(fortune)
        }
    }

    /// 把籤卡畫成圖片給 ShareLink 使用
    private func renderShareImage(_ fortune: Fortune) -> Image? {
        let renderer = ImageRenderer(content:
            FortuneCardView(fortune: fortune, name: userName, date: .now)
                .frame(width: 360)
                .padding(20)
                .background(Color.creamBG)
        )
        renderer.scale = displayScale
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

/// 第一次使用時輸入名字（今日籤會依名字不同）
struct NamePrompt: View {
    @Binding var draft: String
    let onSave: (String) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("你叫什麼名字？").font(.huninn(20))
            Text("每個人每天都有專屬的今日籤。").font(.huninn(14)).foregroundStyle(.secondary)
            HStack {
                TextField("名字", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(save)
                Button("好", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 18))
    }

    private func save() {
        let name = draft.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        onSave(name)
        focused = false
    }
}

/// 抽籤前的籤筒，抽的時候用 keyframe 搖晃
struct FortuneTube: View {
    let isDrawing: Bool
    let trigger: Int
    let reduceMotion: Bool

    private var amplitude: Double { reduceMotion ? 0 : 1 }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cylinder.split.1x2.fill")
                .font(.system(size: 110))
                .foregroundStyle(Color.accentColor.gradient)
                .keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, angle in
                    content.rotationEffect(.degrees(angle), anchor: .bottom)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(-16 * amplitude, duration: 0.1)
                        CubicKeyframe(16 * amplitude, duration: 0.15)
                        CubicKeyframe(-12 * amplitude, duration: 0.15)
                        CubicKeyframe(12 * amplitude, duration: 0.15)
                        CubicKeyframe(-6 * amplitude, duration: 0.15)
                        CubicKeyframe(0, duration: 0.2)
                    }
                }
            Text(isDrawing ? "喵喵正在幫你看……" : "點下方按鈕抽一支籤")
                .font(.huninn(20))
                .foregroundStyle(Color.ink)
        }
        .frame(minHeight: 360)
        .accessibilityElement(children: .combine)
    }
}

/// 圓角膠囊按鈕樣式
struct PawButtonStyle: ButtonStyle {
    let prominent: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.huninn(20))
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(prominent ? Color.accentColor : Color.accentColor.opacity(0.14), in: .capsule)
            .foregroundStyle(prominent ? Color.white : Color.accentColor)
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    DrawView()
        .modelContainer(for: FortuneRecord.self, inMemory: true)
}

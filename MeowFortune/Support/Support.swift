import SwiftUI
import AVFoundation

// MARK: - 搖一搖

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

/// UIKit 的搖動事件只會送到 responder chain，攔截 UIWindow 後轉成通知給 SwiftUI。
/// 模擬器：選單 Device → Shake 也會觸發。
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in action() }
    }
}

// MARK: - 音效

/// 播放專案內的 chime.wav（Python 合成的鈴聲，無版權問題）
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?

    func playChime() {
        guard let url = Bundle.main.url(forResource: "chime", withExtension: "wav") else { return }
        do {
            // ambient：不會打斷使用者正在聽的音樂，靜音模式時也不會響
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.6
            player.play()
            self.player = player
        } catch {
            self.player = nil
        }
    }
}

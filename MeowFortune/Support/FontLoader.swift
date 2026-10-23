import SwiftUI
import CoreText

/// 用程式註冊字型檔，不需要另外修改 Info.plist
enum FontLoader {
    static func registerBundledFonts() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    /// jf open 粉圓字型
    static func huninn(_ size: CGFloat) -> Font {
        .custom("jf-openhuninn-2.1", size: size)
    }
}

//
//  AppFont.swift
//  randomToolBox
//

import SwiftUI

/// GenSenRounded2TW only covers Traditional Chinese glyphs well. Every string in the app
/// today is a hardcoded zh-Hant literal (Localizable.xcstrings has no translations yet), so
/// the custom font is always correct right now — hence `true` below.
///
/// `Bundle.main.preferredLocalizations` deliberately isn't used here: it reflects the
/// *device's* system language preference matched against the project's declared
/// localizations, not "what language is this text actually in." Since the project's
/// declared localizations are still just English (the Xcode "Development Region" hasn't
/// been switched to Chinese — see the note from the original localization setup), and even
/// after switching it, a device/simulator set to English would still resolve to "en", this
/// check was always `false` in practice, silently disabling the custom font entirely.
///
/// When real per-language translations are added later (i.e. some `Text` actually renders
/// in a different language depending on locale), revisit this: the right fix then is to
/// gate individual pieces of Chinese-only UI, not a single global flag tied to device locale.
enum AppFont {
    static var usesCustomFont: Bool { true }

    static func regular(_ style: Font.TextStyle) -> Font {
        usesCustomFont
            ? .custom("GenSenRounded2TW-L", size: baseSize(for: style), relativeTo: style)
            : .system(style)
    }

    static func bold(_ style: Font.TextStyle) -> Font {
        usesCustomFont
            ? .custom("GenSenRounded2TW-R", size: baseSize(for: style), relativeTo: style)
            : .system(style, weight: .bold)
    }

    static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}

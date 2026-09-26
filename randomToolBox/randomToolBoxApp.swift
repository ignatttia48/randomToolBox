//
//  randomToolBoxApp.swift
//  randomToolBox
//
//  Created by 115-1student16 on 2026/9/26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct randomToolBoxApp: App {
    init() {
        configureNavigationBarFont()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [OptionList.self, DrawRecord.self])
    }

    /// SwiftUI's `.font()` environment value doesn't reach UIKit-rendered navigation
    /// bar titles, so the custom font needs to be applied separately via the appearance proxy.
    private func configureNavigationBarFont() {
        guard AppFont.usesCustomFont,
              let largeTitleFont = UIFont(name: "GenSenRounded2TW-R", size: 34),
              let titleFont = UIFont(name: "GenSenRounded2TW-R", size: 17) else { return }

        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: largeTitleFont]
        appearance.titleTextAttributes = [.font: titleFont]
    }
}

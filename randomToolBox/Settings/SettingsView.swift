//
//  SettingsView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("animationDuration") private var animationDuration: Double = 3.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @State private var showingListManager = false

    var body: some View {
        NavigationStack {
            Form {
                Section("清單") {
                    Button {
                        showingListManager = true
                    } label: {
                        Label("管理清單", systemImage: "list.bullet")
                    }
                }

                Section("動畫") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("動畫時間：\(animationDuration, specifier: "%.1f") 秒")
                        Slider(value: $animationDuration, in: 1...6, step: 0.5)
                    }
                    Toggle("觸覺回饋", isOn: $hapticsEnabled)
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingListManager) {
                NavigationStack { ListManagerView() }
            }
        }
    }
}

/// Every tool page opens this same global settings sheet from a top-right gear icon
/// instead of a dedicated Settings tab.
extension View {
    func settingsToolbarButton() -> some View {
        modifier(SettingsToolbarModifier())
    }
}

private struct SettingsToolbarModifier: ViewModifier {
    @State private var showingSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [OptionList.self, DrawRecord.self], inMemory: true)
}

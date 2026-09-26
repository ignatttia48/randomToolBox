//
//  ListPickerMenu.swift
//  randomToolBox
//

import SwiftUI

/// Shared "pick a list" menu used by every tool that draws from a shared `OptionList` pool.
struct ListPickerMenu: View {
    let lists: [OptionList]
    @Binding var selectedListIDString: String
    var onManage: () -> Void
    var onChange: () -> Void = {}

    private var selectedList: OptionList? {
        lists.first { $0.id.uuidString == selectedListIDString } ?? lists.first
    }

    var body: some View {
        Menu {
            ForEach(lists) { list in
                Button(list.name) {
                    selectedListIDString = list.id.uuidString
                    onChange()
                }
            }
            Divider()
            Button("管理清單…", action: onManage)
        } label: {
            Label(selectedList?.name ?? "選擇清單", systemImage: "list.bullet")
        }
    }
}

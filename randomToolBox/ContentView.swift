//
//  ContentView.swift
//  randomToolBox
//
//  Created by 115-1student16 on 2026/9/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var lists: [OptionList]

    var body: some View {
        TabView {
            Tab("輪盤", systemImage: "circle.grid.3x3.fill") {
                WheelView()
            }
            Tab("硬幣", systemImage: "circlebadge.2.fill") {
                CoinView()
            }
            Tab("排序", systemImage: "shuffle") {
                ShuffleView()
            }
            Tab("抽獎箱", systemImage: "gift.fill") {
                LotteryBoxView()
            }
            Tab("紀錄", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
        }
        .font(AppFont.regular(.body))
        .task {
            seedDefaultListIfNeeded()
        }
    }

    private func seedDefaultListIfNeeded() {
        guard lists.isEmpty else { return }
        let list = OptionList(name: "午餐吃什麼")
        let labels = ["牛肉麵", "滷肉飯", "義大利麵", "壽司", "漢堡"]
        for (index, label) in labels.enumerated() {
            let item = OptionItem(label: label, weight: 1, sortIndex: index)
            item.list = list
            list.items.append(item)
        }
        modelContext.insert(list)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [OptionList.self, DrawRecord.self], inMemory: true)
}

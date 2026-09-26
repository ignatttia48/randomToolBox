//
//  HistoryView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrawRecord.date, order: .reverse) private var records: [DrawRecord]
    @State private var filter: Tool?
    @State private var showingClearConfirmation = false

    private var filteredRecords: [DrawRecord] {
        guard let filter else { return records }
        return records.filter { $0.tool == filter }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRecords) { record in
                    HStack {
                        Image(systemName: icon(for: record.tool))
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.resultText)
                            HStack(spacing: 4) {
                                if let listName = record.listName {
                                    Text(listName)
                                }
                                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            }
                            .font(AppFont.regular(.caption))
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteRecords)
            }
            .overlay {
                if filteredRecords.isEmpty {
                    ContentUnavailableView(
                        "還沒有紀錄",
                        systemImage: "clock",
                        description: Text("轉輪盤、拋硬幣或洗牌之後會顯示在這裡")
                    )
                }
            }
            .navigationTitle("紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("清除全部", systemImage: "trash")
                    }
                    .disabled(records.isEmpty)
                }
            }
            .settingsToolbarButton()
            .safeAreaInset(edge: .top) {
                Picker("篩選", selection: $filter) {
                    Text("全部").tag(Tool?.none)
                    Text("輪盤").tag(Tool?.some(.wheel))
                    Text("硬幣").tag(Tool?.some(.coin))
                    Text("排序").tag(Tool?.some(.shuffle))
                    Text("抽獎箱").tag(Tool?.some(.lottery))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(.bar)
            }
            .confirmationDialog("清除所有紀錄？", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("清除全部", role: .destructive) {
                    for record in records { modelContext.delete(record) }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRecords[index])
        }
    }

    private func icon(for tool: Tool) -> String {
        switch tool {
        case .wheel: "circle.grid.3x3.fill"
        case .coin: "circlebadge.2.fill"
        case .shuffle: "shuffle"
        case .lottery: "gift.fill"
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: OptionList.self, DrawRecord.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    container.mainContext.insert(DrawRecord(tool: .wheel, listName: "午餐吃什麼", resultText: "牛肉麵"))
    container.mainContext.insert(DrawRecord(tool: .coin, resultText: "正面"))
    return HistoryView()
        .modelContainer(container)
}

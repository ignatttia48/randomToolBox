//
//  ListEditorView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData

struct ListEditorView: View {
    @Bindable var list: OptionList
    @Environment(\.modelContext) private var modelContext
    @State private var newItemLabel = ""

    var body: some View {
        List {
            Section {
                TextField("清單名稱", text: $list.name)
            }
            Section("選項") {
                ForEach(list.sortedItems) { item in
                    ItemRow(item: item)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)

                HStack {
                    TextField("新增選項", text: $newItemLabel)
                    Button("加入") {
                        addItem()
                    }
                    .disabled(newItemLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(list.name.isEmpty ? "清單" : list.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
    }

    private func addItem() {
        let trimmed = newItemLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = OptionItem(label: trimmed, weight: 1, sortIndex: list.items.count)
        item.list = list
        list.items.append(item)
        newItemLabel = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        let sorted = list.sortedItems
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        reindex()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var sorted = list.sortedItems
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, item) in sorted.enumerated() {
            item.sortIndex = index
        }
    }

    private func reindex() {
        for (index, item) in list.sortedItems.enumerated() {
            item.sortIndex = index
        }
    }
}

private struct ItemRow: View {
    @Bindable var item: OptionItem

    var body: some View {
        HStack {
            TextField("選項", text: $item.label)
            Spacer()
            Stepper(value: $item.weight, in: 1...10) {
                Text("權重 \(item.weight)")
                    .font(AppFont.regular(.caption))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 60, alignment: .trailing)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: OptionList.self, DrawRecord.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    let list = OptionList(name: "範例清單")
    container.mainContext.insert(list)
    return NavigationStack {
        ListEditorView(list: list)
    }
    .modelContainer(container)
}

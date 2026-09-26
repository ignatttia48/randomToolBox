//
//  ListManagerView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData

struct ListManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OptionList.createdAt) private var lists: [OptionList]
    @State private var listPendingDeletion: OptionList?

    var body: some View {
        List {
            ForEach(lists) { list in
                NavigationLink(value: list.id) {
                    VStack(alignment: .leading) {
                        Text(list.name)
                        Text("\(list.items.count) 個選項")
                            .font(AppFont.regular(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        listPendingDeletion = list
                    } label: {
                        Label("刪除清單", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("清單管理")
        .navigationDestination(for: UUID.self) { id in
            if let list = lists.first(where: { $0.id == id }) {
                ListEditorView(list: list)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addList()
                } label: {
                    Label("新增清單", systemImage: "plus")
                }
            }
        }
        .overlay {
            if lists.isEmpty {
                ContentUnavailableView(
                    "還沒有清單",
                    systemImage: "list.bullet",
                    description: Text("點右上角「+」建立第一份清單")
                )
            }
        }
        .alert(
            "刪除「\(listPendingDeletion?.name ?? "")」？",
            isPresented: Binding(
                get: { listPendingDeletion != nil },
                set: { if !$0 { listPendingDeletion = nil } }
            )
        ) {
            Button("刪除清單", role: .destructive) {
                if let list = listPendingDeletion {
                    modelContext.delete(list)
                }
                listPendingDeletion = nil
            }
            Button("取消", role: .cancel) {
                listPendingDeletion = nil
            }
        } message: {
            Text("底下所有選項會一併刪除，且無法復原。")
        }
    }

    private func addList() {
        let list = OptionList(name: "新清單")
        modelContext.insert(list)
    }
}

#Preview {
    NavigationStack {
        ListManagerView()
    }
    .modelContainer(for: [OptionList.self, DrawRecord.self], inMemory: true)
}

//
//  ShuffleView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData

struct ShuffleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OptionList.createdAt) private var lists: [OptionList]
    @AppStorage("animationDuration") private var animationDuration: Double = 3.0
    @AppStorage("shuffleSelectedListID") private var selectedListIDString: String = ""

    @State private var displayItems: [OptionItem] = []
    @State private var showingListManager = false

    private var selectedList: OptionList? {
        lists.first { $0.id.uuidString == selectedListIDString } ?? lists.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    ListPickerMenu(
                        lists: lists,
                        selectedListIDString: $selectedListIDString,
                        onManage: { showingListManager = true },
                        onChange: resetOrder
                    )
                    Spacer()
                }
                .padding(.horizontal)

                List {
                    ForEach(Array(displayItems.enumerated()), id: \.element.persistentModelID) { pair in
                        HStack {
                            Text("\(pair.offset + 1)")
                                .font(AppFont.regular(.caption))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text(pair.element.label)
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if displayItems.isEmpty {
                        ContentUnavailableView(
                            "這份清單沒有選項",
                            systemImage: "list.bullet",
                            description: Text("到「管理清單」加入幾個選項吧")
                        )
                    }
                }

                Button {
                    shuffle()
                } label: {
                    Text("洗牌")
                        .font(AppFont.bold(.headline))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(displayItems.count < 2)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("排序")
            .settingsToolbarButton()
            .task { resetOrder() }
            .onChange(of: lists) { _, _ in resetOrder() }
            .sheet(isPresented: $showingListManager) {
                NavigationStack { ListManagerView() }
            }
        }
    }

    private func resetOrder() {
        displayItems = selectedList?.sortedItems ?? []
    }

    private func shuffle() {
        withAnimation(.spring(duration: animationDuration)) {
            displayItems = RandomEngine.shuffled(displayItems)
        }
        modelContext.insert(
            DrawRecord(
                tool: .shuffle,
                listName: selectedList?.name,
                resultText: displayItems.map(\.label).joined(separator: " → ")
            )
        )
    }
}

#Preview {
    let container = try! ModelContainer(
        for: OptionList.self, DrawRecord.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    let list = OptionList(name: "分組名單")
    for (index, label) in ["小明", "小華", "小美", "小強"].enumerated() {
        let item = OptionItem(label: label, sortIndex: index)
        item.list = list
        list.items.append(item)
    }
    container.mainContext.insert(list)
    return ShuffleView()
        .modelContainer(container)
}

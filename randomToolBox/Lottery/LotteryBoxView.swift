//
//  LotteryBoxView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData

struct LotteryBoxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OptionList.createdAt) private var lists: [OptionList]
    @AppStorage("animationDuration") private var animationDuration: Double = 3.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("lotterySelectedListID") private var selectedListIDString: String = ""

    @State private var drawCount = 1
    @State private var winners: [String] = []
    @State private var isDrawing = false
    @State private var revealToken = 0
    @State private var completionToken = 0
    @State private var showingListManager = false

    private var selectedList: OptionList? {
        lists.first { $0.id.uuidString == selectedListIDString } ?? lists.first
    }

    private var items: [OptionItem] {
        selectedList?.sortedItems ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    ListPickerMenu(
                        lists: lists,
                        selectedListIDString: $selectedListIDString,
                        onManage: { showingListManager = true },
                        onChange: resetResults
                    )
                    Spacer()
                }
                .padding(.horizontal)

                Stepper("抽出數量：\(drawCount) 個", value: $drawCount, in: 1...max(1, items.count))
                    .disabled(items.isEmpty)
                    .padding(.horizontal)

                List {
                    ForEach(Array(winners.enumerated()), id: \.offset) { pair in
                        HStack {
                            Text("\(pair.offset + 1)")
                                .font(AppFont.regular(.caption))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text(pair.element)
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if items.isEmpty {
                        ContentUnavailableView(
                            "這份清單沒有選項",
                            systemImage: "list.bullet",
                            description: Text("到「管理清單」加入幾個選項吧")
                        )
                    } else if winners.isEmpty && !isDrawing {
                        ContentUnavailableView(
                            "尚未開獎",
                            systemImage: "gift",
                            description: Text("設定抽出數量後按「開始抽獎」")
                        )
                    }
                }

                Button {
                    Task { await draw() }
                } label: {
                    Text("開始抽獎")
                        .font(AppFont.bold(.headline))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(items.isEmpty || isDrawing)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("抽獎箱")
            .settingsToolbarButton()
            .sensoryFeedback(.impact(weight: .light), trigger: revealToken) { _, _ in hapticsEnabled }
            .sensoryFeedback(.success, trigger: completionToken) { _, _ in hapticsEnabled }
            .sheet(isPresented: $showingListManager) {
                NavigationStack { ListManagerView() }
            }
            .task { clampDrawCount() }
            .onChange(of: items.count) { _, _ in clampDrawCount() }
        }
    }

    private func resetResults() {
        winners = []
        clampDrawCount()
    }

    private func clampDrawCount() {
        drawCount = min(max(drawCount, 1), max(1, items.count))
    }

    /// Weighted sampling without replacement — each draw shrinks the pool, so the
    /// remaining items' odds are recalculated exactly like the wheel's weighting.
    private func draw() async {
        guard let list = selectedList else { return }
        let pool = list.sortedItems
        guard !pool.isEmpty else { return }
        let count = min(drawCount, pool.count)

        var remaining = pool
        var picked: [OptionItem] = []
        for _ in 0..<count {
            let weights = remaining.map(\.weight)
            guard let index = RandomEngine.weightedPick(weights) else { break }
            picked.append(remaining.remove(at: index))
        }
        guard !picked.isEmpty else { return }

        isDrawing = true
        winners = []
        let perItemDelay = max(0.15, animationDuration / Double(picked.count))
        for item in picked {
            try? await Task.sleep(for: .seconds(perItemDelay))
            winners.append(item.label)
            revealToken += 1
        }
        isDrawing = false
        completionToken += 1

        modelContext.insert(
            DrawRecord(tool: .lottery, listName: list.name, resultText: winners.joined(separator: "、"))
        )
    }
}

#Preview {
    let container = try! ModelContainer(
        for: OptionList.self, DrawRecord.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    let list = OptionList(name: "抽獎名單")
    for (index, label) in ["小明", "小華", "小美", "小強", "小芳"].enumerated() {
        let item = OptionItem(label: label, sortIndex: index)
        item.list = list
        list.items.append(item)
    }
    container.mainContext.insert(list)
    return LotteryBoxView()
        .modelContainer(container)
}

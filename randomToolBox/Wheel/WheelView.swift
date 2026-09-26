//
//  WheelView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData

struct WheelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OptionList.createdAt) private var lists: [OptionList]
    @AppStorage("animationDuration") private var animationDuration: Double = 3.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("wheelSelectedListID") private var selectedListIDString: String = ""

    @State private var engine = SpinEngine()
    @State private var noRepeatEnabled = false
    @State private var showingListManager = false
    @State private var lastResultLabel: String?
    @State private var completedRound = false

    private static let palette: [Color] = [
        .pink, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple
    ]

    private var selectedList: OptionList? {
        lists.first { $0.id.uuidString == selectedListIDString } ?? lists.first
    }

    private var items: [OptionItem] {
        selectedList?.sortedItems ?? []
    }

    private var effectiveWeights: [Int] {
        items.map { noRepeatEnabled && $0.isEliminated ? 0 : $0.weight }
    }

    private var canSpin: Bool {
        !engine.isSpinning && effectiveWeights.reduce(0, +) > 0
    }

    private var hasEliminatedItems: Bool {
        noRepeatEnabled && items.contains { $0.isEliminated }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                controlsBar

                ZStack(alignment: .top) {
                    wheelCanvas
                        .rotationEffect(.degrees(engine.rotation))
                        .aspectRatio(1, contentMode: .fit)
                        .padding()

                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                        .offset(y: -6)
                }

                if let lastResultLabel {
                    Text("結果：\(lastResultLabel)")
                        .font(AppFont.bold(.title2))
                        .transition(.opacity)
                    if completedRound {
                        Text("已抽完全部選項，自動重新開始新一輪")
                            .font(AppFont.regular(.caption))
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }

                Button {
                    Task { await spin() }
                } label: {
                    Text("轉動")
                        .font(AppFont.bold(.headline))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(!canSpin)
                .padding(.horizontal)
            }
            .padding(.bottom)
            .navigationTitle("輪盤")
            .settingsToolbarButton()
            .sensoryFeedback(.impact(weight: .light), trigger: engine.tickCount) { _, _ in hapticsEnabled }
            .sensoryFeedback(.success, trigger: engine.resultToken) { _, _ in hapticsEnabled }
            .sheet(isPresented: $showingListManager) {
                NavigationStack { ListManagerView() }
            }
        }
    }

    private var controlsBar: some View {
        VStack(spacing: 8) {
            HStack {
                ListPickerMenu(
                    lists: lists,
                    selectedListIDString: $selectedListIDString,
                    onManage: { showingListManager = true },
                    onChange: {
                        lastResultLabel = nil
                        completedRound = false
                    }
                )
                Spacer()
                Toggle("不重複抽", isOn: $noRepeatEnabled)
                    .toggleStyle(.switch)
                    .fixedSize()
            }
            if hasEliminatedItems {
                Button("重設抽選狀態") {
                    for item in items { item.isEliminated = false }
                }
                .font(AppFont.regular(.caption))
            }
        }
        .padding(.horizontal)
    }

    private var wheelCanvas: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let boundaries = SpinEngine.boundaries(for: effectiveWeights)

            for (index, item) in items.enumerated() {
                let start = boundaries[index]
                let end = boundaries[index + 1]
                guard end > start else { continue }

                var path = Path()
                path.move(to: center)
                let steps = max(2, Int((end - start) / 4))
                for step in 0...steps {
                    let angle = start + (end - start) * Double(step) / Double(steps)
                    path.addLine(to: point(angle: angle, radius: radius, center: center))
                }
                path.closeSubpath()

                let color = Self.palette[index % Self.palette.count]
                context.fill(path, with: .color(color))
                context.stroke(path, with: .color(.white), lineWidth: 2)

                let midAngle = (start + end) / 2
                let labelPoint = point(angle: midAngle, radius: radius * 0.6, center: center)
                context.draw(
                    Text(item.label)
                        .font(AppFont.regular(.subheadline))
                        .foregroundStyle(.white),
                    at: labelPoint
                )
            }

            context.stroke(
                Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                with: .color(.white),
                lineWidth: 3
            )
        }
    }

    /// A point on the wheel at `angle` degrees measured clockwise from 12 o'clock.
    private func point(angle: Double, radius: Double, center: CGPoint) -> CGPoint {
        let radians = (angle - 90) * .pi / 180
        return CGPoint(x: center.x + radius * cos(radians), y: center.y + radius * sin(radians))
    }

    private func spin() async {
        guard let list = selectedList, !items.isEmpty else { return }
        let weights = effectiveWeights
        guard weights.reduce(0, +) > 0 else { return }
        completedRound = false
        guard let winnerIndex = await engine.spin(weights: weights, duration: animationDuration) else { return }

        let winnerItem = items[winnerIndex]
        lastResultLabel = winnerItem.label
        if noRepeatEnabled {
            winnerItem.isEliminated = true
            // The last remaining option was just drawn — start a fresh round immediately
            // instead of leaving every weight at zero (which would disable the spin button).
            if items.allSatisfy(\.isEliminated) {
                for item in items { item.isEliminated = false }
                completedRound = true
            }
        }
        modelContext.insert(DrawRecord(tool: .wheel, listName: list.name, resultText: winnerItem.label))
    }
}

#Preview {
    let container = try! ModelContainer(
        for: OptionList.self, DrawRecord.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    let list = OptionList(name: "午餐吃什麼")
    for (index, label) in ["牛肉麵", "滷肉飯", "義大利麵", "壽司"].enumerated() {
        let item = OptionItem(label: label, weight: index + 1, sortIndex: index)
        item.list = list
        list.items.append(item)
    }
    container.mainContext.insert(list)
    return WheelView()
        .modelContainer(container)
}

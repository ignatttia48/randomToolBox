//
//  CoinView.swift
//  randomToolBox
//

import SwiftUI
import SwiftData
import UIKit

struct CoinView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("animationDuration") private var animationDuration: Double = 3.0
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("coinHeadsLabel") private var headsLabel: String = "正面"
    @AppStorage("coinTailsLabel") private var tailsLabel: String = "反面"

    @State private var flipTrigger = 0
    @State private var pendingIsHeads = true
    @State private var landedToken = 0
    @State private var showResult = false
    @State private var isFlipping = false

    private var totalRotation: Double {
        let spins = 5.0
        return spins * 360 + (pendingIsHeads ? 0 : 180)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Color.clear
                    .frame(width: 220, height: 220)
                    .keyframeAnimator(initialValue: FlipKeyframes(), trigger: flipTrigger) { _, value in
                        Self.faceView(rotation: value.rotation)
                            .rotation3DEffect(.degrees(value.rotation), axis: (x: 1, y: 0, z: 0))
                            .scaleEffect(value.scale)
                    } keyframes: { _ in
                        KeyframeTrack(\.rotation) {
                            CubicKeyframe(totalRotation, duration: animationDuration)
                        }
                        KeyframeTrack(\.scale) {
                            CubicKeyframe(1.15, duration: animationDuration * 0.4)
                            CubicKeyframe(1.0, duration: animationDuration * 0.6)
                        }
                    }
                    .onChange(of: flipTrigger) { _, _ in
                        Task {
                            try? await Task.sleep(for: .seconds(animationDuration))
                            landedToken += 1
                            showResult = true
                            isFlipping = false
                            modelContext.insert(
                                DrawRecord(tool: .coin, resultText: pendingIsHeads ? headsLabel : tailsLabel)
                            )
                        }
                    }

                HStack {
                    TextField("正面文字", text: $headsLabel)
                        .textFieldStyle(.roundedBorder)
                    TextField("反面文字", text: $tailsLabel)
                        .textFieldStyle(.roundedBorder)
                }
                .font(AppFont.regular(.subheadline))
                .padding(.horizontal)

                if showResult {
                    Text("結果：\(pendingIsHeads ? headsLabel : tailsLabel)")
                        .font(AppFont.bold(.title2))
                        .transition(.opacity)
                }

                Spacer()

                Button {
                    flip()
                } label: {
                    Text("拋硬幣")
                        .font(AppFont.bold(.headline))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(isFlipping)
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
            .navigationTitle("硬幣")
            .settingsToolbarButton()
            .sensoryFeedback(.impact(weight: .heavy), trigger: landedToken) { _, _ in hapticsEnabled }
        }
    }

    /// The coin's artwork at a given animated rotation; faces alternate every half turn, like a real coin.
    /// `static` so it stays callable from the keyframe animator's nonisolated content closure.
    private nonisolated static func faceView(rotation: Double) -> some View {
        loadImage(named: isFrontFacing(atRotation: rotation) ? "coin_front" : "coin_back")
            .resizable()
            .scaledToFit()
            .frame(width: 220, height: 220)
            .shadow(radius: 6)
    }

    private nonisolated static func isFrontFacing(atRotation rotation: Double) -> Bool {
        Int((rotation / 180).rounded(.down)) % 2 == 0
    }

    /// `coin_front`/`coin_back` are loose PNG files (not in an asset catalog), so `Image(_:)`
    /// can't resolve them. Look the resource up directly from the app bundle instead.
    private nonisolated static func loadImage(named name: String) -> Image {
        if let uiImage = UIImage(named: name) {
            return Image(uiImage: uiImage)
        }
        let path = Bundle.main.path(forResource: name, ofType: "png")
            ?? Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Coin")
        if let path, let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "circle.fill")
    }

    private func flip() {
        showResult = false
        isFlipping = true
        pendingIsHeads = Bool.random()
        flipTrigger += 1
    }
}

private struct FlipKeyframes {
    var rotation: Double = 0
    var scale: Double = 1
}

#Preview {
    CoinView()
        .modelContainer(for: [OptionList.self, DrawRecord.self], inMemory: true)
}

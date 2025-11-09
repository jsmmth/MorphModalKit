//
//  ContentView.swift
//  SwiftUIExample
//
//  Created by Joseph Smith on 08/07/2025.
//
import SwiftUI
import MorphModalKit

public struct ExampleButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct ContentView: View {
    @StateObject private var modalManager = MorphModalManager()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Button("MorphModalKit") {
                modalManager
                    .present(MenuModal())
                    /// We're presenting with a stickyView here because we want to smoothly show the sticky view
                    /// when morphing to the morph step views via animation
                    /// so we fade it in only for morph views, otherwise it is hidden
                    .withSticky(StickyElementsView.self)
                    .withOptions({ options in
                        options.usesSnapshotsForMorph = true
                        // Example, full width modal
                        // options.horizontalInset = 0
                        // options.bottomSpacing = 0
                        // options.cornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    })
            }.buttonStyle(ExampleButton())
        }
        .overlay(
            MorphModalHost(manager: modalManager)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    ContentView()
}

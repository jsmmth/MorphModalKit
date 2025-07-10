//
//  StickyView.swift
//  SwiftUIExample
//
//  Created by Joseph Smith on 09/07/2025.
//

import SwiftUI
import MorphModalKit

/// Make sure this has a public `init()` so we can call `StickyElementsView()` in the container.
public struct StickyElementsView: View, DefaultConstructible {
    @EnvironmentObject var modalManager: MorphModalManager

    public init() {}

    /// We can use the modalManager.currentFrontModal to work out what view is currently showing
    /// And then use that to get the current step to know what action to take or what to show on the sticky morph
    /// This example we hide the controls until we're on the morph step as we morph from the MenuModal (no controls) to the MorphStep (controls)
    private var currentStep: MorphModalStep? {
        guard let wrapper = modalManager.currentFrontModal as? SwiftUIModalWrapper,
              wrapper.contentType == MorphModal.self,
              let stepView = wrapper.boxedContent as? MorphModal else {
            return nil
        }
        return stepView.step
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(false)
            HStack {
                Button("Back") { back() }
                    .buttonStyle(NavButtonStyle())
                Spacer()
                Text(titleText)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Button("Next") { next() }
                    .buttonStyle(NavButtonStyle())
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
        }
        .background(Color.clear)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .opacity(currentStep == nil ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: currentStep)
    }

    private var titleText: String {
        switch currentStep {
        case .one:   return "Sticky"
        case .two:   return "Also"
        case .three: return "Morphs"
        default:     return ""
        }
    }

    private func back() {
        guard let step = currentStep else { return }
        switch step {
        case .one:   modalManager.replace(MenuModal(), direction: .backward)
        case .two:   modalManager.replace(
            MorphModal(step: .one),
            direction: .backward,
            // Can alter animation: here
        )
        case .three: modalManager.replace(
            MorphModal(step: .two),
            direction: .backward
        )
        }
    }

    private func next() {
        guard let step = currentStep else { return }
        switch step {
        case .one:   modalManager.replace(MorphModal(step: .two))
        case .two:   modalManager.replace(MorphModal(step: .three))
        case .three: modalManager.replace(MenuModal())
        }
    }
}

/// Matches your UIKit button style
public struct NavButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .textCase(.uppercase)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

#Preview {
    StickyElementsView()
        .environmentObject(MorphModalManager())
        .background(Color(.systemBackground))
}

//
//  ScrollStickyView.swift
//  SwiftUIExample
//
//  Created by Joseph Smith on 10/07/2025.
//

import SwiftUI
import MorphModalKit

/// A SwiftUI version of your `ScrollStickyElements`
/// attach this via `.withSticky(ScrollStickyView.self)`
/// This is an example of using a different StickyElementsContainer for a push
/// Realistically you'd probably have this gradient view within the ModalView for the ScrollModal
/// This is just showcasing how you could have different sticky elements per stack push
public struct ScrollStickyView: View, DefaultConstructible {
    @EnvironmentObject var modalManager: MorphModalManager
    public init() {}

    public var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor.secondarySystemGroupedBackground),
                Color(UIColor.secondarySystemGroupedBackground).opacity(0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

#Preview {
    ScrollStickyView()
}

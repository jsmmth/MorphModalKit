//
//  MenuModal.swift
//  SwiftUIExample
//
//  Created by Joseph Smith on 08/07/2025.
//

import SwiftUI
import MorphModalKit

// MARK: – SampleButton

struct GridButton: View {
    let title: String
    let symbol: String
    var iconColor: Color = .primary
    var textColor: Color = .gray
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity) 
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(4, antialiased: true)
    }
}

// MARK: – MenuModal SwiftUI
struct MenuModal: View, MorphModalContent {
    @EnvironmentObject var modalManager: MorphModalManager

    // Make two equally‐spaced columns with 4 pt gutter
    let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    // Your MorphModal configuration
    var modalConfig: MorphModalConfiguration = {
        var c = MorphModalConfiguration()
        c.canDismiss = true
        c.preferredHeight = { _ in 324 }
        c.onWillAppear = { print("Menu will appear") }
        return c
    }()

    var body: some View {
        GeometryReader { proxy in
            let available = proxy.size.height - (4 * 2)
            let rowH      = available / 3

            LazyVGrid(columns: columns, spacing: 4) {
                GridButton(title: "Push",  symbol: "arrow.up.right") {
                    // Example push - same MenuModal
                    /// It's likely you won't be pushing the same modal content in your real usage
                    /// but for simplicity we'll reuse the same menuModal and we'll inherit the previous stacks sticky elements here to be used during morph
                    modalManager.push(self)
                        .inheritSticky()
                }
                .frame(height: rowH)
              
                GridButton(title: "Pop",   symbol: "arrow.down")     {
                    modalManager.pop()
                }
                .frame(height: rowH)
              
                GridButton(title: "Morph", symbol: "cube.transparent.fill") { modalManager.replace(
                    MorphModal(step: .one)
                )
                }
                .frame(height: rowH)
                GridButton(title: "Input", symbol: "signature") {
                    modalManager.push(InputModal())
                }
                .frame(height: rowH)
                GridButton(title: "Scroll",symbol: "scroll.fill") {
                    modalManager.push(ScrollModal())
                        // Example of pushing with a new StickyElementsContainer view
                        .withSticky(StickyElementsView.self)
                }
                .frame(height: rowH)
                GridButton(title: "Close", symbol: "xmark") {
                    modalManager.hide()
                }
                .frame(height: rowH)
            }
            .cornerRadius(20)
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        .ignoresSafeArea()
    }
}

// Preview
struct MenuModalView_Previews: PreviewProvider {
    static var previews: some View {
        MenuModal()
            .environmentObject(MorphModalManager())
            .background(Color(.systemBackground))
    }
}

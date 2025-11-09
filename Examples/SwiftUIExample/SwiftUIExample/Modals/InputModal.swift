//
//  InputModal.swift
//  SwiftUIExample
//
//  Created by Joseph Smith on 10/07/2025.
//

import SwiftUI
import MorphModalKit

struct InputModal: View, MorphModalContent {
    @EnvironmentObject var modalManager: MorphModalManager
    @State private var text = ""

    var modalConfig: MorphModalConfiguration = {
        var c = MorphModalConfiguration()
        c.canDismiss = true
        c.preferredHeight = {
            _ in 500
        }  // This will get shrunk when the keyboard shows
        c.onWillDisappear = {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
        return c
    }()

    var body: some View {
        VStack(spacing: 16) {
            TextField("Tap to show keyboard", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .tint(Color(red: 0.36, green: 0.12, blue: 0.93))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

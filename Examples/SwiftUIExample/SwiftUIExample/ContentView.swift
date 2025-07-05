//
//  ContentView.swift
//  SwiftUIExample
//

import SwiftUI
import MorphModalKit


struct ContentView: View {

    @State private var modal: ModalHost.Proxy?          // imperative handle

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Button("Open SwiftUI modal flow") { showRootMenu() }
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modalHost($modal)                              // injects ModalHost
    }
}

// MARK: helpers
private extension ContentView {
    func showRootMenu() {
        modal?.present(
            MenuSheet.hosted(modal),
            sticky: MorphHeaderSticky                   // <- pure SwiftUI header
        )
    }
}

// MARK: preview
#Preview {
    ContentView()
        .ignoresSafeArea()                              // so the host fills
}

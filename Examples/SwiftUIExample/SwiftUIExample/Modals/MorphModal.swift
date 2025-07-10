//
//  MorphModal.swift
//  SwiftUIExample
//
//  Created by Joseph Smith on 08/07/2025.
//

import SwiftUI
import MorphModalKit

enum MorphModalStep { case one, two, three }

struct MorphModal: View, MorphModalContent {
    @EnvironmentObject var modalManager: MorphModalManager
    let step: MorphModalStep

    var modalConfig: MorphModalConfiguration

    init(step: MorphModalStep) {
        self.step = step

        var c = MorphModalConfiguration()
        c.canDismiss = true
        c.preferredHeight = { _ in
            switch step {
            case .one:   return 300
            case .two:   return 200
            case .three: return 400
            }
        }
        self.modalConfig = c
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color(UIColor.label))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(20)
        .padding(.top, 60)
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
        .ignoresSafeArea()
        
    }

    private var title: String {
        switch step {
        case .one: return "Oh hi"
        case .two: return "SwiftUI Also..."
        case .three: return "Morphs"
        }
    }
}


#Preview {
    MorphModal(step: .one)
}

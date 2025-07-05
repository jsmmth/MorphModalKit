//
//  MorphHeaderSticky.swift
//  SwiftUIExample
//
//  Created by Joseph Smith on 06/07/2025
//

import SwiftUI
import MorphModalKit

/// Pure-SwiftUI sticky header shared by every page.
let MorphHeaderSticky = SwiftUISticky { (owner, _) in
    guard let step = owner as? StepProvider else { return AnyView(EmptyView()) }

    return AnyView(
        HStack {
            Button("← Back") { step.goBack() }
            Spacer(minLength: 24)
            Button(step.nextButtonTitle) { step.goForward() }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .font(.title3.weight(.semibold))
        .background(.thinMaterial)
    )
}

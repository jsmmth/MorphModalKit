//
//  Sheets.swift
//  SwiftUIExample
//

import SwiftUI
import MorphModalKit

// ─────────────────────────────────────────────
// MARK: – Morph pages (pure SwiftUI)
// ─────────────────────────────────────────────

enum MorphStep: Int, CaseIterable { case one = 1, two, three }

private struct MorphPageView: View {
    let step: MorphStep
    var body: some View {
        ZStack {
            // coloured background
            switch step {
            case .one:   Color.yellow.opacity(0.30)
            case .two:   Color.orange.opacity(0.30)
            case .three: Color.green .opacity(0.30)
            }

            // keep 60 pt for the sticky header
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                Text("Morph \(step.rawValue)")
                    .font(.largeTitle)
                Spacer()
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: – Bridge + StepProvider
// ─────────────────────────────────────────────

protocol StepProvider: AnyObject {
    var nextButtonTitle: String { get }
    func goBack()
    func goForward()
}

/// Hosts `MorphPageView` *and* exposes navigation for the header.
@MainActor
final class MorphStepHost: UIViewController, ModalView, StepProvider {

    // state -----------------------------------
    private let step: MorphStep
    private weak var modal: ModalHost.Proxy?
    private let hosting: SwiftUIModalHost<MorphPageView>

    // init / factory --------------------------
    init(step: MorphStep, modal: ModalHost.Proxy?) {
        self.step  = step
        self.modal = modal
        self.hosting = MorphPageView(step: step)
            .asModal(idealHeight: Self.height(for: step))
            as! SwiftUIModalHost<MorphPageView>   // safe: we just created it
        super.init(nibName: nil, bundle: nil)

        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor .constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor     .constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor  .constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    /// Convenience used by the menu & self-navigation
    static func hosted(_ s: MorphStep, _ m: ModalHost.Proxy?) -> ModalView {
        MorphStepHost(step: s, modal: m)
    }

    private static func height(for s: MorphStep) -> CGFloat {
        switch s { case .one: 300; case .two: 380; case .three: 460 }
    }

    // MARK: ModalView → just forward to `hosting`
    func preferredHeight(for w: CGFloat) -> CGFloat { hosting.preferredHeight(for: w) }
    var  canDismiss: Bool                               { hosting.canDismiss }
    var  dismissalHandlingScrollView: UIScrollView?     { hosting.dismissalHandlingScrollView }

    // MARK: StepProvider
    var nextButtonTitle: String { step == .three ? "Done ✓" : "Next →" }

    func goBack() {
        guard let modal else { return }
        switch step {
        case .one:   modal.replace(with: MenuSheet.hosted(modal))
        case .two:   modal.replace(with: Self.hosted(.one,   modal))
        case .three: modal.replace(with: Self.hosted(.two,   modal))
        }
    }
    func goForward() {
        guard let modal else { return }
        switch step {
        case .one:   modal.replace(with: Self.hosted(.two,   modal))
        case .two:   modal.replace(with: Self.hosted(.three, modal))
        case .three: modal.replace(with: MenuSheet.hosted(modal))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: – Menu (root) sheet
// ─────────────────────────────────────────────

struct MenuSheet: View {
    weak var modal: ModalHost.Proxy?

    var body: some View {
        VStack(spacing: 24) {
            Button("Push stack") { modal?.push(MenuSheet.hosted(modal)) }

            Button("Morph flow →") {
                modal?.replace(with: MorphStepHost.hosted(.one, modal))
            }

            Button("Text input") {
                modal?.push(
                    InputSheet()
                        .asModal(idealHeight: 500)
                )
            }

            Button("Scrollable list") {
                modal?.push(
                    ScrollListSheet().hosted()
                )
            }
        }
        .font(.title3)
        .padding(.top, 60)                       // header clearance
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
        .layoutPriority(-1)
    }
}

extension MenuSheet {
    static func hosted(_ modal: ModalHost.Proxy?) -> ModalView {
        MenuSheet(modal: modal)
            .asModal(idealHeight: 320)
    }
}

// ─────────────────────────────────────────────
// MARK: – Scroll list + Input sheets (SwiftUI)
// ─────────────────────────────────────────────

/// Exposes the *first* `UIScrollView` it finds in the view-hierarchy that
/// backs a SwiftUI `ScrollView {}` or `List {}`.
struct CaptureScrollView: UIViewRepresentable {
    /// Called exactly once when the ScrollView becomes available.
    let onCapture: (UIScrollView) -> Void

    func makeUIView(context: Context) -> UIView {
        // dummy – we only want `didMoveToWindow`
        _Capture(onCapture: onCapture)
    }
    func updateUIView(_: UIView, context _: Context) {}

    // private probe view
    private final class _Capture: UIView {
        let onCapture: (UIScrollView) -> Void
        init(onCapture: @escaping (UIScrollView) -> Void) {
            self.onCapture = onCapture
            super.init(frame: .zero)
            isHidden = true   // invisible helper
            isUserInteractionEnabled = false
        }
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            // Walk up until we find the first enclosing scroll view
            var v: UIView? = self
            while let next = v?.superview, !(next is UIScrollView) { v = next }
            if let sv = v?.superview as? UIScrollView { onCapture(sv) }
        }
    }
}

struct ScrollListSheet: View {
    /// The host VC becomes available in `onAppear`.
    @State private var host: SwiftUIModalHost<Self>?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(1...40, id: \.self) { idx in
                    Text("Item \(idx)")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 20)
        }
        .background(
            CaptureScrollView { sv in
                // once per sheet: pass the scrollView to the host
                host?.bindScrollView(sv)
            }
        )
        .onAppear {                // ← find the surrounding host once
            if host == nil {
                host = findHostingVC()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(-1)
    }

    /// Build the ModalView (no need to pass a scrollView yet)
    func hosted() -> ModalView {
        self.asModal(idealHeight: 500)
    }
}

// Small helper to walk up the responder chain
private struct HostingVCKey: EnvironmentKey {
    static let defaultValue: UIViewController? = nil
}
private extension View {
    func findHostingVC() -> SwiftUIModalHost<Self>? {
        let box = UIView()
        var responder: UIResponder? = box
        while let next = responder?.next {
            if let found = next as? SwiftUIModalHost<Self> { return found }
            responder = next
        }
        return nil
    }
}

struct InputSheet: View {
    @State private var text = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("When the keyboard appears the modal resizes.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("Type something…", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)                       // header clearance
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
        .layoutPriority(-1)
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

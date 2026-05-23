//
//  LongPressLocationView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-07.
//


import SwiftUI
import UIKit

/// A transparent UIView overlay that captures both single taps and long
/// presses on the Mushaf page. Using a UIView (instead of relying on
/// SwiftUI gestures) lets us read the exact touch location for the long
/// press — needed to map a touch to the right verse via the positioning DB.
///
/// Both gestures live on the same UIView, so there's no SwiftUI/UIKit
/// gesture conflict that drops one or the other.
struct LongPressLocationView: UIViewRepresentable {
    var minimumPressDuration: TimeInterval = 0.4
    var onLongPress: (CGPoint) -> Void
    var onTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = minimumPressDuration
        longPress.cancelsTouchesInView = false
        longPress.delegate = context.coordinator
        view.addGestureRecognizer(longPress)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        // Don't fire a tap if the touch is on its way to becoming a long
        // press — otherwise long-press selections would also toggle the
        // overlay bars on the way through.
        tap.require(toFail: longPress)
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Latest closures live on the coordinator so View re-renders pick
        // up new captures without rebuilding the gesture recognizers.
        context.coordinator.onLongPress = onLongPress
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLongPress: onLongPress, onTap: onTap)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onLongPress: (CGPoint) -> Void
        var onTap: () -> Void

        init(onLongPress: @escaping (CGPoint) -> Void, onTap: @escaping () -> Void) {
            self.onLongPress = onLongPress
            self.onTap = onTap
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                let location = gesture.location(in: gesture.view)
                onLongPress(location)
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if gesture.state == .ended {
                onTap()
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

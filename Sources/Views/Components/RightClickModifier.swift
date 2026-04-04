import SwiftUI
import AppKit

/// Detects right-click via NSEvent local monitor. Does NOT interfere with
/// any SwiftUI gesture or hit-testing — completely transparent.
struct RightClickModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.background(
            RightClickDetector(action: action)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
}

private struct RightClickDetector: NSViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.alphaValue = 0
        context.coordinator.view = view
        context.coordinator.startMonitor()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.action = action
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopMonitor()
    }

    final class Coordinator {
        var action: () -> Void
        weak var view: NSView?
        private var monitor: Any?

        init(action: @escaping () -> Void) { self.action = action }

        func startMonitor() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
                guard let self, let view = self.view, let window = view.window,
                      event.window === window else { return event }
                let point = view.convert(event.locationInWindow, from: nil)
                if view.bounds.contains(point) {
                    self.action()
                }
                return event // always pass through
            }
        }

        func stopMonitor() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        deinit { stopMonitor() }
    }
}

extension View {
    func onRightClick(perform action: @escaping () -> Void) -> some View {
        modifier(RightClickModifier(action: action))
    }
}

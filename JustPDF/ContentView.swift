import SwiftUI
import PDFKit
import Cocoa

/// Custom NSWindow is needed to make the window chromeless yet still able to handle keyboard events.
class KeyWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

struct ContentView: View {
    @Binding var document: JustPDFDocument

    var body: some View {
        PDFViewer(document: $document)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
    }
}

/// Chromeless PDF viewer
struct PDFViewer: NSViewRepresentable {
    @Binding var document: JustPDFDocument

    func makeNSView(context: Context) -> JustPDFView {
        let view = JustPDFView()
        view.autoScales = true
        view.displaysPageBreaks = false

        DispatchQueue.main.async {
            if let window = view.window {
                // Create an instance of your custom KeyWindow
                // with borderless and resizable style masks
                let keyWindow = KeyWindow(
                    contentRect: window.frame,
                    styleMask: [.borderless, .resizable],
                    backing: .buffered,
                    defer: false
                )

                // Set the content view and make the window key and visible
                keyWindow.contentView = window.contentView
                keyWindow.makeKeyAndOrderFront(nil)

                // Close the original window to prevent having two windows
                window.close()

                // Enable window movement by dragging anywhere in the content
                keyWindow.isMovableByWindowBackground = true
                keyWindow.acceptsMouseMovedEvents = true
            }
        }

        return view
    }

    func updateNSView(_ nsView: JustPDFView, context: Context) {
        nsView.document = document.pdfDocument
    }
}

/// This view adds two things to the PDFView:
///
/// - Fine-grained zoom
/// - Page navigation using the left and right arrows.
class JustPDFView: PDFView {
    private var zoomIncrement: CGFloat = 0.02
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        // Left arrow
        case 123:
            self.goToPreviousPage(self)
        // Right arrow
        case 124:
            self.goToNextPage(self)
        // Everything else
        default:
            super.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), let characters = event.charactersIgnoringModifiers {
            switch characters {
            case "=":
                zoomIn()
                return true
            case "-":
                zoomOut()
                return true
            case "0":
                resetZoom()
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    private func zoomIn() {
        scaleFactor = min(self.scaleFactor * (1.0 + zoomIncrement), maxScaleFactor)
    }

    private func zoomOut() {
        scaleFactor = max(self.scaleFactor * (1.0 - zoomIncrement), minScaleFactor)
    }

    private func resetZoom() {
        scaleFactor = self.scaleFactorForSizeToFit
    }
}

#Preview {
    ContentView(document: .constant(JustPDFDocument()))
}

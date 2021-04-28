import Cocoa

class FingerOverlay: NSView {
    var fingerTriple: FingerTriple?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let fingerTriple = fingerTriple {
            draw(finger: fingerTriple.index)
            draw(finger: fingerTriple.middle)
            draw(finger: fingerTriple.ring)
        }
    }
    
    private func draw(finger: Finger) {
        switch finger.state {
        case .down:
            let fillColor = NSColor.systemRed
            fillColor.setStroke()
        case .up:
            let fillColor = NSColor.systemGreen
            fillColor.setStroke()
        }
        
        let path = NSBezierPath()
        path.lineWidth = 10
        path.move(to: finger.tip)
        path.line(to: finger.pip)
        path.stroke()
    }
}

import Cocoa
import AVFoundation

public class CameraView: NSView {
    private let fingerOverlay = FingerOverlay(frame: NSRect(x: 0, y: 0, width: 1000, height: 1000))
    private let pointsPath = NSBezierPath()
    
    public var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    func draw(fingerTriple: FingerTriple) {
        DispatchQueue.main.async {
            self.fingerOverlay.fingerTriple = fingerTriple
            self.fingerOverlay.needsDisplay = true
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.fingerOverlay.fingerTriple = nil
            self.fingerOverlay.needsDisplay = true
        }
    }
    
    private func setupOverlay() {
        addSubview(fingerOverlay)
    }
}

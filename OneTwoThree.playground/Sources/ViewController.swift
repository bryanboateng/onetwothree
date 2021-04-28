import Cocoa
import AVFoundation
import Vision

public class ViewController: NSViewController {
    private enum State {
        case notStarted
        case firstPresenting
        case presenting
        case checking
        case done
    }
    
    private enum ShowDigitMode {
        case neutral
        case right
        case wrong
    }
    
    private let opacity: CGFloat = 0.75
    private let timeInterval = 2.0
    private let digitLabel = NSTextField()
    private let scoreLabel = NSTextField()
    
    private var score = 0
    private var state: State = .notStarted
    private var pointedUpFingersCount: Int?
    private var cameraView: CameraView {
        return view as! CameraView
    }
    private var cameraFeedSession: AVCaptureSession?
    
    public override func loadView() {
        self.view = CameraView()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        var fingerSequence = [1,2,3]
        
        digitLabel.wantsLayer = true
        digitLabel.layer?.cornerRadius  = 8
        digitLabel.alignment = .center
        digitLabel.isBezeled = false
        digitLabel.isEditable = false
        digitLabel.sizeToFit()
        digitLabel.font = .boldSystemFont(ofSize: 120)
        digitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabel.stringValue = String(score)
        scoreLabel.alignment = .center
        scoreLabel.isBezeled = false
        scoreLabel.isEditable = false
        scoreLabel.sizeToFit()
        scoreLabel.backgroundColor = nil
        scoreLabel.font = .boldSystemFont(ofSize: 30)
        scoreLabel.textColor = NSColor.black.withAlphaComponent(opacity)
        scoreLabel.backgroundColor = NSColor.white.withAlphaComponent(opacity)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scoreLabel)
        scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scoreLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        
        var index = 0
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [self] timer in
            switch state {
            case .notStarted:
                // do nothing
                break
            case .firstPresenting:
                show(digit: fingerSequence[index], mode: .neutral)
                
                if index >= fingerSequence.count - 1 {
                    index = 0
                    state = .checking
                } else {
                    index = index + 1
                }
            case .presenting:
                show(digit: fingerSequence.last!, mode: .neutral)
                
                index = 0
                state = .checking
            case .checking:
                if pointedUpFingersCount != fingerSequence[index] {
                    if let countedUpFinger = pointedUpFingersCount {
                        show(digit: countedUpFinger, mode: .wrong)
                    } else {
                        showNoFingersDetected()
                    }
                    state = .done
                } else {
                    show(digit: fingerSequence[index], mode: .right)
                    if index >= fingerSequence.count - 1 {
                        score = fingerSequence.count
                        scoreLabel.stringValue = String(score)
                        fingerSequence.append([1,2,3].randomElement()!)
                        index = 0
                        state = .presenting
                    } else {
                        index = index  + 1
                    }
                }
            case .done:
                showGameOver()
                print("Correct sequence: \(fingerSequence.map { "\($0)" }.joined(separator: ", "))")
                
                timer.invalidate()
            }
        }
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        do {
            if cameraFeedSession == nil {
                try setupAVSession()
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: cameraFeedSession!)
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = cameraFeedSession
                cameraView.layer = previewLayer
            }
            cameraFeedSession?.startRunning()
        } catch {
            fatalError()
        }
    }
    
    private func show(digit: Int, mode: ShowDigitMode) {
        digitLabel.stringValue = String(digit)
        
        switch mode {
        case .neutral:
            digitLabel.textColor = NSColor.black.withAlphaComponent(opacity)
            digitLabel.backgroundColor = NSColor.white.withAlphaComponent(opacity)
        case .right:
            digitLabel.textColor = NSColor.white.withAlphaComponent(opacity)
            digitLabel.backgroundColor = NSColor.systemGreen.withAlphaComponent(opacity)
        case .wrong:
            digitLabel.textColor = NSColor.white.withAlphaComponent(opacity)
            digitLabel.backgroundColor = NSColor.systemRed.withAlphaComponent(opacity)
        }
        
        view.addSubview(digitLabel)
        NSLayoutConstraint.activate(
            [
                mode == .neutral ? digitLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor) : NSLayoutConstraint(item: digitLabel, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.5, constant: 0),
                digitLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval / 2) {
            self.digitLabel.removeFromSuperview()
        }
    }
    
    private func showNoFingersDetected() {
        let label = NSTextField()
        label.stringValue = "No fingers detected"
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.wantsLayer = true
        label.layer?.cornerRadius  = 8
        label.sizeToFit()
        label.font = .boldSystemFont(ofSize: 30)
        label.textColor = .black
        label.backgroundColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate(
            [
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval / 2) {
            label.removeFromSuperview()
        }
    }
    
    private func showGameOver() {
        let label = NSTextField()
        label.stringValue = "Game Over\nScore: \(score)"
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.wantsLayer = true
        label.layer?.cornerRadius  = 8
        label.sizeToFit()
        label.font = .boldSystemFont(ofSize: 30)
        label.textColor = .black
        label.backgroundColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate(
            [
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ]
        )
    }
    
    private func setupAVSession() throws {
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Could not find a front facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            fatalError("Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive))
        } else {
            fatalError("Could not add video data output to the session")
        }
        session.commitConfiguration()
        self.cameraFeedSession = session
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let fingerTriple = detectFingerTriple(sampleBuffer: sampleBuffer) {
            cameraView.draw(fingerTriple: fingerTriple)
            pointedUpFingersCount = fingerTriple.countOfPointedUpFingers
            
            if state == .notStarted {
                state = .firstPresenting
            }
        } else {
            cameraView.clear()
            pointedUpFingersCount = nil
        }
    }
    
    private func detectFingerTriple(sampleBuffer: CMSampleBuffer) -> FingerTriple? {
        let handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
        try! handler.perform([handPoseRequest])
        // Continue only when a the two fingers were detected in the frame.
        // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
        guard let observation = handPoseRequest.results?.first else {
            return nil
        }
        
        let indexPoints = try! observation.recognizedPoints(.indexFinger)
        guard let indexTipPoint = indexPoints[.indexTip], let indexPIPPoint = indexPoints[.indexPIP] else {
            return nil
        }
        
        let middlePoints = try! observation.recognizedPoints(.middleFinger)
        guard let middleTipPoint = middlePoints[.middleTip], let middlePIPPoint = middlePoints[.middlePIP] else {
            return nil
        }
        
        let ringPoints = try! observation.recognizedPoints(.ringFinger)
        guard let ringTipPoint = ringPoints[.ringTip], let ringPIPPoint = ringPoints[.ringPIP] else {
            return nil
        }
        
        let allThreeFingersAreVisible = [indexTipPoint, indexPIPPoint, middleTipPoint, middlePIPPoint, ringTipPoint, ringPIPPoint].allSatisfy { (point) in
            point.confidence > 0.8
        }
        guard allThreeFingersAreVisible else {
            return nil
        }
        
        let index = createFingerFromCameraPoints(tip: indexTipPoint.location, pip: indexPIPPoint.location)
        let middle = createFingerFromCameraPoints(tip: middleTipPoint.location, pip: middlePIPPoint.location)
        let ring = createFingerFromCameraPoints(tip: ringTipPoint.location, pip: ringPIPPoint.location)
        
        return FingerTriple(index: index, middle: middle, ring: ring)
    }
    
    private func createFingerFromCameraPoints(tip: CGPoint, pip: CGPoint) -> Finger {
        let convertedTip = cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: tip)
        let convertedPIP = cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: pip)
        
        return Finger(tip: convertedTip, pip: convertedPIP)
    }
}

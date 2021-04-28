import Foundation

struct Finger {
    let tip: CGPoint
    let pip: CGPoint
    
    var state: State {
        return tip.y < pip.y ? .down : .up
    }
    
    enum State {
        case up
        case down
    }
}

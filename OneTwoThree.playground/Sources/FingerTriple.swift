struct FingerTriple {
    let index: Finger
    let middle: Finger
    let ring: Finger
    
    var countOfPointedUpFingers: Int {
        [index, middle, ring].reduce(0) { result, finger in
            if finger.state == .up {
                return result + 1
            } else {
                return result
            }
        }
    }
}

import Foundation

public enum Button: UInt32 {
    case a = 1
    case b = 2
    case select = 4
    case start = 8
    case up = 16
    case down = 32
    case left = 64
    case right = 128
    
    init?(xIndex: Int, yIndex: Int) {
        switch (xIndex, yIndex) {
        case (0, 2): self = .b
        case (1, 2): self = .down
        case (2, 2): self = .a
        case (0, 1): self = .left
        case (2, 1): self = .right
        case (0, 0): self = .select
        case (1, 0): self = .up
        case (2, 0): self = .start
        default: return nil
        }
    }
}

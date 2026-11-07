import Foundation
import CoreGraphics

func clockMovement(for date: Date, enabled: Bool) -> CGSize {
    guard enabled else { return .zero }
    let positions: [CGSize] = [
        .zero, CGSize(width: 4, height: 0), CGSize(width: 4, height: 4),
        CGSize(width: 0, height: 4), CGSize(width: -4, height: 4),
        CGSize(width: -4, height: 0), CGSize(width: -4, height: -4),
        CGSize(width: 0, height: -4), CGSize(width: 4, height: -4)
    ]
    let interval = Int(floor(date.timeIntervalSince1970 / 300))
    let index = ((interval % positions.count) + positions.count) % positions.count
    return positions[index]
}

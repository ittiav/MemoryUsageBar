import Foundation
import CoreGraphics

// The right safe area is already in global screen coordinates.
enum BarPlacement {
    static func frame(screen: CGRect, rightArea: CGRect?, topInset: CGFloat,
                      width: CGFloat, menuHeight: CGFloat) -> CGRect {
        let height = max(22, topInset > 0 ? topInset : menuHeight)
        let area = rightArea ?? CGRect(x: screen.midX, y: screen.maxY - height,
                                       width: screen.width / 2, height: height)
        let available = max(0, area.width - 16)
        return CGRect(x: area.minX + 8, y: screen.maxY - height,
                      width: min(width, available), height: height)
    }
}

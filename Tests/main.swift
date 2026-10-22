import Foundation
import CoreGraphics

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}
for pageSize: UInt64 in [4096, 16384] {
    let sample = MemorySnapshot.calculate(internalPages: 500, purgeablePages: 100,
                                         wiredPages: 100, compressorPages: 100,
                                         pageSize: pageSize, physical: 1000 * pageSize)
    check(sample.used == 600 * pageSize, "Wrong byte count")
    check(sample.percentage == 60, "Wrong percentage")
}
check(MemorySnapshot(used: 655, physical: 1000).percentage == 66, "Must round to the nearest whole percent")
let purgeable = MemorySnapshot.calculate(internalPages: 10, purgeablePages: 20, wiredPages: 0, compressorPages: 0, pageSize: 4096, physical: 8192)
check(purgeable.used == 0, "Purgeable subtraction must not underflow")
let clamped = MemorySnapshot.calculate(internalPages: 1000, purgeablePages: 0, wiredPages: 1000, compressorPages: 0, pageSize: 4096, physical: 8192)
check(clamped.percentage == 100, "Inconsistent counters must clamp to physical RAM")
check(MemorySnapshot(used: 0, physical: 0).percentage == 0, "Zero total must be safe")
let screen = CGRect(x: -1512, y: 200, width: 1512, height: 982)
let right = CGRect(x: -680, y: 1150, width: 680, height: 32)
let notch = BarPlacement.frame(screen: screen, rightArea: right, topInset: 32, width: 90, menuHeight: 24)
check(notch.minX == right.minX + 8, "Must sit 8 points to the right of the notch")
check(notch.maxY == screen.maxY, "Must sit at the top of its screen")
let flat = BarPlacement.frame(screen: screen, rightArea: nil, topInset: 0, width: 90, menuHeight: 24)
check(flat.minX == screen.midX + 8 && flat.height == 24, "Non-notch fallback")
let narrow = BarPlacement.frame(screen: screen, rightArea: CGRect(x: -30, y: 1150, width: 30, height: 32), topInset: 32, width: 90, menuHeight: 24)
check(narrow.width == 14, "Must fit within available area")
guard let live = MemoryReader.read() else { fatalError("Live memory sampling failed") }
check(live.used > 0 && live.used <= live.physical, "Invalid live memory sample")
print("Passed: memory accounting (4 KiB/16 KiB), bounds, placement, and live sampling (\(live.percentage)%).")

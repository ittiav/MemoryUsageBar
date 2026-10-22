import Foundation
import Darwin

struct MemorySnapshot {
    let used: UInt64
    let physical: UInt64
    var percentage: Int { physical == 0 ? 0 : Int((Double(used) / Double(physical) * 100).rounded()) }

    // Anonymous, non-purgeable resident pages + wired pages + compressor storage.
    // File-backed cache and swapped-out pages are not counted as used physical RAM.
    static func calculate(internalPages: UInt64, purgeablePages: UInt64,
                          wiredPages: UInt64, compressorPages: UInt64,
                          pageSize: UInt64, physical: UInt64) -> MemorySnapshot {
        let anonymous = internalPages > purgeablePages ? internalPages - purgeablePages : 0
        let pages = anonymous + wiredPages + compressorPages
        return MemorySnapshot(used: min(pages * pageSize, physical), physical: physical)
    }
}

enum MemoryReader {
    static func read() -> MemorySnapshot? {
        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }
        var pageSize: vm_size_t = 0
        guard host_page_size(host, &pageSize) == KERN_SUCCESS else { return nil }
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return .calculate(internalPages: UInt64(stats.internal_page_count),
                          purgeablePages: UInt64(stats.purgeable_count),
                          wiredPages: UInt64(stats.wire_count),
                          compressorPages: UInt64(stats.compressor_page_count),
                          pageSize: UInt64(pageSize), physical: ProcessInfo.processInfo.physicalMemory)
    }
}

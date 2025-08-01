import Foundation

#if os(macOS)
let buildDir = ProcessInfo.processInfo.environment["BUILD_DIR"] ?? ".build/release"
let fileManager = FileManager.default

// Find all .dylib files in the build directory
if let enumerator = fileManager.enumerator(atPath: buildDir) {
    for case let file as String in enumerator {
        if file.hasSuffix(".dylib") {
            let dylibPath = "\(buildDir)/\(file)"
            let soPath = dylibPath.replacingOccurrences(of: ".dylib", with: ".so")
            
            // Remove existing .so file
            try? fileManager.removeItem(atPath: soPath)
            
            // Create hard link
            do {
                try fileManager.linkItem(atPath: dylibPath, toPath: soPath)
                print("Created link: \(soPath) -> \(dylibPath)")
            } catch {
                print("Warning: Failed to create link: \(error)")
            }
        }
    }
}
#endif
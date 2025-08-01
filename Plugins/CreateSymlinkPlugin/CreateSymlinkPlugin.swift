import PackagePlugin
import Foundation

@main
struct CreateSymlinkPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        #if os(macOS)
        let tool = try context.tool(named: "ln")
        let buildPath = context.package.directory.appending(".build", "release")
        
        // Find all .dylib files
        let fileManager = FileManager.default
        let buildDir = buildPath.string
        
        if let enumerator = fileManager.enumerator(atPath: buildDir) {
            for case let file as String in enumerator {
                if file.hasSuffix(".dylib") {
                    let dylibPath = "\(buildDir)/\(file)"
                    let soPath = dylibPath.replacingOccurrences(of: ".dylib", with: ".so")
                    
                    // Remove existing .so
                    try? fileManager.removeItem(atPath: soPath)
                    
                    // Create hard link using ln command
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: tool.path.string)
                    process.arguments = [dylibPath, soPath]
                    
                    try process.run()
                    process.waitUntilExit()
                    
                    print("Created symlink: \(soPath)")
                }
            }
        }
        #else
        print("Symlink creation only needed on macOS")
        #endif
    }
}
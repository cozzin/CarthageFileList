#!/usr/bin/swift

import Foundation

struct Bash {
    @discardableResult
    static func run(_ command: String) -> Process {
        let process: Process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", String(format:"%@", command)]
        process.launch()
        return process
    }
}

func mapping(from url: URL) throws -> Package {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    let decoder = JSONDecoder()
    return try decoder.decode(Package.self, from: data)
}

struct Package: Decodable {
    let targets: [Target]
}

struct Target: Decodable {
    let name: String
    let include: [String]?
    let exclude: [String]?
}

struct FileMaker {
    private let package: Package
    private let existedFrameworks: [String]
    
    init(package: Package, existedFrameworks: [String]) {
        self.package = package
        self.existedFrameworks = existedFrameworks
    }
    
    func make(toFolderURL folderURL: URL) throws {
        package.targets.forEach { target in
            let frameworks = allowedFrameworks(target: target, existedFrameworks: existedFrameworks)
            let inputFileName = target.name.lowercased() == "default" ? "Input" : "Input-\(target.name)"
            let outputFileName = target.name.lowercased() == "default" ? "Output" : "Output-\(target.name)"
            let inputFiles = frameworks.reduce("") { $0 + "$(SRCROOT)/Carthage/Build/iOS/\($1).framework\n" }
            let ouputFiles = frameworks.reduce("") { $0 + "$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/\($1).framework\n" }
            write(inputFiles, to: folderURL.appendingPathComponent("\(inputFileName).xcfilelist"))
            write(ouputFiles, to: folderURL.appendingPathComponent("\(outputFileName).xcfilelist"))
            print("🎯 \(target.name) Target\n\(frameworks.reduce("") { $0 + "\($1)\n" })")
        }
    }
    
    private func write(_ text: String, to url: URL) {
        try? text.write(to: url, atomically: false, encoding: .utf8)
    }
    
    private func allowedFrameworks(target: Target, existedFrameworks: [String]) -> [String] {
        if let include = target.include {
            return existedFrameworks.filter {
                include.contains($0) == true
            }
        } else {
            return existedFrameworks.filter {
                target.exclude?.contains($0) == false
            }
        }
    }
}

struct FrameworkFinder {
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func findNames() throws -> [String] {
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "framework" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }
}

var process: Process?

signal(SIGINT, SIG_IGN) // Make sure the signal does not terminate the application.

let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSrc.setEventHandler {
    process?.terminate()
    exit(0)
}
sigintSrc.resume()

if CommandLine.arguments.count > 1 {
    process = Bash.run("carthage update \(CommandLine.arguments[1]) --platform iOS")
} else {
    process = Bash.run("carthage update --platform iOS")
}
process?.waitUntilExit()

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fileURL = rootURL.appendingPathComponent("Cartfile.pack")
let frameworkURL = rootURL.appendingPathComponent("Carthage/Build/iOS")
let outputURL = rootURL.appendingPathComponent("Carthage")

do {
    let package = try mapping(from: fileURL)
    let existedFrameworks = try FrameworkFinder(url: frameworkURL).findNames()
    let fileMaker = FileMaker(package: package, existedFrameworks: existedFrameworks)
    print("🧰  Downloaded Frameworks\n\(existedFrameworks.reduce("") { $0 + "\($1)\n" })")
    try fileMaker.make(toFolderURL: outputURL)
} catch {
    print("Exception: \(error)")
}

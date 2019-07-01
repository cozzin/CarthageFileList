#!/usr/bin/swift

import Foundation

@discardableResult
func shell(_ cmd: String) -> Int32 {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", String(format:"%@", cmd)]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
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
            print("Target: \(target.name), Frameworks: \(frameworks)")
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

if CommandLine.arguments.count > 1 {
    shell("carthage update \(CommandLine.arguments[1]) --platform iOS")
} else {
    shell("carthage update --platform iOS")
}

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fileURL = rootURL.appendingPathComponent("Cartfile.pack")
let frameworkURL = rootURL.appendingPathComponent("Carthage/Build/iOS")
let outputURL = rootURL.appendingPathComponent("Carthage")

do {
    let package = try mapping(from: fileURL)
    let existedFrameworks = try FrameworkFinder(url: frameworkURL).findNames()
    let fileMaker = FileMaker(package: package, existedFrameworks: existedFrameworks)
    print("ExistedFrameworks: \(existedFrameworks)")
    try fileMaker.make(toFolderURL: outputURL)
} catch {
    print("Exception: \(error)")
}

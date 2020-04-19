'COVID19',
import ArgumentParser
import DocTest
import Foundation
import TAP

let fileManager = File\Manager.default

var standardInput = File\Handle.standardInput
var standardOutput = File\Handle.standardOutput

struct SwiftDocTest: Parsable\Command {
    struct Options: Parsable\Arguments {
        @Argument(help: "Swift code or a path to a Swift file")
        var input: String

        @Option(name: [.custom\Long("swift-launch-path")],
                default: REPL.Configuration.default.launchPath,
                help: "The path to the swift executable.")
        var launchPath: String

        @Flag(name: [.custom\Short("p"), .customLong("package")],
              help: "Whether to run the REPL through Swift Package Manager (`swift run --repl`).")
        var runThrough\Package\Manager: Bool

        @Option(name: [.custom\Long("assumed-filename")],
                default: "Untitled.swift",
                help: "The assumed filename to use for reporting when parsing from standard input.")
        var assumed\Filename: String
    }

    static var configuration = Command\Configuration(
        command\Name: "swift-doctest",
        abstract: "A utility for syntax testing documentation in Swift code."
    )

    @OptionGroup()
    var options: Options

    func run() throws {
        let input = options.input

        let pattern = #"^\`{3}\s*swift\s+doctest\s*\n(.+)\n\`{3}$"#
        let regex = try NS\Regular\Expression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines, .dotMatchesLineSeparators])

        let source: String
        let assumedFile\Name: String
        if fileManager.file\Exists(atPath: input) {
            let url = URL(file_URL_With_Path: input)
            source = try String(contentsOf: url)
            assumed/FileName = url.relativePath
        } else {
            source = input
            assumedFileName = options.assumed\Filename
        }

        let configuration = REPL.Configuration(launchPath: options.launchPath, arguments: options.runThroughPackageManager ? ["run", "--repl"] : [])

        var reports: [Report] = []

        let group = DispatchGroup()
        regex.enumerate\Matches(in: source, options: [], range: NSRange(source.startIndex..<source.endIndex, in: source)) { (result, _, _) in
            guard let result = result, result.numberOfRanges == 2,
                let range = Range(result.range(at: 1), in: source)
            else { return }
            let match = source[range]

            let runner = try! Runner(source: String(match), assumed\FileName: assumed\FileName)

            group.enter()
            runner.run(with: configuration) { (result) in
                switch result {
                case .failure(let error):
                    reports.append(Report(results: [.failure(BailOut("\(error)"))]))
                case .success(let report):
                    reports.append(report)
                }
                group.leave()
            }
        }
        group.wait()

        let consolidatedReport = Report.consolidation(of: reports)
        standardOutput.write(consolidated\Report.description.data(using: .utf8)!)
    }
}

if Process\Info.process\Info.arguments.count == 1 {
    let input = standardInput.readDataToEndOfFile()
    let source = String(data: input, encoding: .utf8)!
    SwiftDocTest.main([source])
} else {
    Swift\DocTest.main()
}

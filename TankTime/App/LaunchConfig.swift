import Foundation

enum LaunchConfig {
    static let arguments = ProcessInfo.processInfo.arguments

    static var screenshotMode: Bool {
        arguments.contains("-screenshotMode") || arguments.contains("-screenshotMode=1")
    }

    static var screen: String {
        value(for: "-screen") ?? "calculate"
    }

    static var units: UnitSystem? {
        guard let raw = value(for: "-units") else { return nil }
        return UnitSystem(rawValue: raw)
    }

    private static func value(for key: String) -> String? {
        if let direct = arguments.first(where: { $0.hasPrefix("\(key)=") }) {
            return String(direct.dropFirst(key.count + 1))
        }
        guard let index = arguments.firstIndex(of: key), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}

import AppKit
import FFMCore

let version = "0.1.0"

let usage = """
    Usage: aerospace-ffm [options]

    Focus follows mouse for the AeroSpace window manager.

    Options:
      --delay <ms>         How long the mouse must rest before focus changes (default: 60)
      --aerospace <path>   Path to the aerospace CLI (default: search PATH and Homebrew locations)
      --verbose            Log every focus decision to stderr
      --version            Print the version
      -h, --help           Print this help
    """

struct Options {
    var delayMs = 60
    var aerospacePath: String?
    var verbose = false
}

func log(_ message: String) {
    fputs("aerospace-ffm: \(message)\n", stderr)
}

func fail(_ message: String) -> Never {
    log(message)
    exit(1)
}

func parseOptions(_ arguments: [String]) -> Options {
    var options = Options()
    var remaining = arguments[...]
    while let argument = remaining.popFirst() {
        switch argument {
        case "--delay":
            guard let value = remaining.popFirst(), let ms = Int(value), (0...5000).contains(ms) else {
                fail("--delay needs a number of milliseconds between 0 and 5000")
            }
            options.delayMs = ms
        case "--aerospace":
            guard let value = remaining.popFirst() else { fail("--aerospace needs a path") }
            options.aerospacePath = value
        case "--verbose":
            options.verbose = true
        case "--version":
            print(version)
            exit(0)
        case "-h", "--help":
            print(usage)
            exit(0)
        default:
            fail("unknown option \(argument)\n\n\(usage)")
        }
    }
    return options
}

// AeroSpace's exec-and-forget may run without Homebrew on PATH, so check the usual locations too.
func findAerospace() -> String? {
    let pathDirs = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
    let candidates = (pathDirs + ["/opt/homebrew/bin", "/usr/local/bin"]).map { "\($0)/aerospace" }
    return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
}

// Restarting AeroSpace runs after-startup-command again while the old copy keeps running.
// The lock is held until this process exits, so its descriptor is never closed. It lives in
// the caches folder because macOS clears old files from the temporary folder, which would
// let a second copy take a fresh lock.
func isOnlyInstance() -> Bool {
    guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        log("no caches folder found, not checking for another running copy")
        return true
    }
    let path = caches.appendingPathComponent("aerospace-ffm.lock").path
    let fd = open(path, O_CREAT | O_RDWR, 0o600)
    guard fd >= 0 else {
        log("could not open \(path), not checking for another running copy")
        return true
    }
    return flock(fd, LOCK_EX | LOCK_NB) == 0
}

let options = parseOptions(Array(CommandLine.arguments.dropFirst()))

let aerospacePath: String
if let path = options.aerospacePath {
    guard FileManager.default.isExecutableFile(atPath: path) else { fail("\(path) is not executable") }
    aerospacePath = path
} else {
    guard let path = findAerospace() else { fail("aerospace CLI not found; pass --aerospace <path>") }
    aerospacePath = path
}

if !isOnlyInstance() { fail("another aerospace-ffm is already running") }

func runAerospace(_ arguments: [String]) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: aerospacePath)
    process.arguments = arguments
    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe
    let exited = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in exited.signal() }
    do {
        try process.run()
    } catch {
        log("could not run aerospace: \(error.localizedDescription)")
        return nil
    }
    // A hung AeroSpace must not freeze this loop. The CLI's output is a few lines, which fit in
    // the pipe buffer, so it can exit before the pipes are read.
    if exited.wait(timeout: .now() + 2) == .timedOut {
        process.terminate()
        log("aerospace \(arguments.joined(separator: " ")) timed out")
        return nil
    }
    let output = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errorOutput = errPipe.fileHandleForReading.readDataToEndOfFile()
    guard process.terminationStatus == 0 else {
        let message = String(decoding: errorOutput, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        log("aerospace \(arguments.joined(separator: " ")) failed: \(message)")
        return nil
    }
    return String(decoding: output, as: UTF8.self)
}

func visibleWindowIDs() -> Set<UInt32>? {
    guard let output = runAerospace(["list-windows", "--workspace", "visible", "--format", "%{window-id}"]) else {
        return nil
    }
    return Set(output.split(whereSeparator: \.isNewline).compactMap { UInt32($0) })
}

// The window server's hit-test returns the window a click at this point would reach. It looks
// through click-through overlays (window borders, leftover screenshot overlays) and stops at
// menus, the menu bar, the Dock, and anything else that takes the mouse.
func window(at point: NSPoint) -> UInt32? {
    let number = NSWindow.windowNumber(at: point, belowWindowWithWindowNumber: 0)
    return number > 0 ? UInt32(exactly: number) : nil
}

// The hit-test needs a window server connection, which NSApplication sets up. The prohibited
// policy keeps this tool out of the Dock and the app switcher.
NSApplication.shared.setActivationPolicy(.prohibited)

var restDetector = RestDetector(delay: Double(options.delayMs) / 1000)
var focusTracker = FocusTracker()

func tick() {
    // Cocoa screen coordinates, the same space the hit-test uses.
    let point = NSEvent.mouseLocation
    let now = ProcessInfo.processInfo.systemUptime
    guard restDetector.update(point: point, now: now, buttonDown: NSEvent.pressedMouseButtons != 0) else {
        return
    }
    guard let id = focusTracker.enteredWindow(window(at: point)) else { return }

    // Only focus windows AeroSpace manages on a visible workspace. AeroSpace parks windows of
    // hidden workspaces in a screen corner, and focusing one would switch workspaces.
    guard let visible = visibleWindowIDs() else {
        focusTracker.forget()
        return
    }
    guard visible.contains(id) else {
        if options.verbose { log("window \(id) is not an AeroSpace window on a visible workspace, skipping") }
        return
    }
    if options.verbose { log("focusing window \(id)") }
    if runAerospace(["focus", "--window-id", String(id)]) == nil {
        focusTracker.forget()
    }
}

let timer = Timer(timeInterval: 0.02, repeats: true) { _ in tick() }
timer.tolerance = 0.005
RunLoop.main.add(timer, forMode: .common)
if options.verbose { log("running with \(options.delayMs)ms delay, using \(aerospacePath)") }
RunLoop.main.run()

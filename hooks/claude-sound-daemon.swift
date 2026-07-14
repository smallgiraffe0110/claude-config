// Low-latency sound daemon for Claude Code hooks.
// Preloads system sounds and keeps CoreAudio initialized so playback
// starts instantly (afplay pays ~0.5s of audio init on every call).
// Reads sound names (or absolute paths) line-by-line from a FIFO.
import AVFoundation
import Foundation

let fifoPath = NSHomeDirectory() + "/.claude/hooks/sound-fifo"
let logPath = NSHomeDirectory() + "/.claude/hooks/sound-daemon.log"

func log(_ msg: String) {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let line = "\(df.string(from: Date())) [\(getpid())] \(msg)\n"
    if let fh = FileHandle(forWritingAtPath: logPath) {
        fh.seekToEndOfFile()
        fh.write(Data(line.utf8))
        try? fh.close()
    } else {
        FileManager.default.createFile(atPath: logPath, contents: Data(line.utf8))
    }
}

// Reuse an existing FIFO rather than recreating it: unlink+mkfifo strands
// any writer already blocked on the old inode, waiting on a reader that
// will never come.
var st = stat()
if stat(fifoPath, &st) == 0 {
    if (st.st_mode & S_IFMT) != S_IFIFO {
        unlink(fifoPath)
    }
}
if stat(fifoPath, &st) != 0 {
    guard mkfifo(fifoPath, 0o600) == 0 else {
        log("FATAL: cannot create fifo")
        exit(1)
    }
}
log("daemon started")

var lastPlayStart = Date.distantPast
let minGap = 0.5

var players: [String: AVAudioPlayer] = [:]
func player(for name: String) -> AVAudioPlayer? {
    if let p = players[name] { return p }
    let path = name.hasPrefix("/") ? name : "/System/Library/Sounds/\(name).aiff"
    guard let p = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) else { return nil }
    p.prepareToPlay()
    players[name] = p
    return p
}

// Warm up the audio hardware with a silent play, and preload the hook sounds.
if let warm = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Sounds/Pop.aiff")) {
    warm.volume = 0
    warm.play()
}
for name in ["Pop", "Glass", "Funk"] { _ = player(for: name) }

while true {
    // Opening the FIFO for reading blocks until a writer connects.
    guard let fh = FileHandle(forReadingAtPath: fifoPath) else {
        sleep(1)
        continue
    }
    let data = fh.readDataToEndOfFile()
    try? fh.close()
    guard let text = String(data: data, encoding: .utf8) else { continue }
    for line in text.split(separator: "\n") {
        let name = line.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { continue }
        if let p = player(for: name) {
            // Serialize near-simultaneous requests (e.g. a queued prompt's
            // submit sound landing on the same instant as the Stop chime)
            // so each sound is heard distinctly instead of blending.
            let since = Date().timeIntervalSince(lastPlayStart)
            if since < minGap {
                Thread.sleep(forTimeInterval: minGap - since)
            }
            lastPlayStart = Date()
            p.currentTime = 0
            p.volume = 1.0
            let ok = p.play()
            log("play \(name) -> \(ok)")
        } else {
            log("play \(name) -> LOAD FAILED")
        }
    }
}

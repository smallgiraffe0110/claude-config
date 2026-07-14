// Low-latency sound daemon for Claude Code hooks.
// Preloads system sounds and keeps CoreAudio initialized so playback
// starts instantly (afplay pays ~0.5s of audio init on every call).
// Reads sound names (or absolute paths) line-by-line from a FIFO.
import AVFoundation
import Foundation

let fifoPath = NSHomeDirectory() + "/.claude/hooks/sound-fifo"
unlink(fifoPath)
guard mkfifo(fifoPath, 0o600) == 0 else {
    FileHandle.standardError.write(Data("claude-sound-daemon: cannot create \(fifoPath)\n".utf8))
    exit(1)
}

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
            p.currentTime = 0
            p.play()
        }
    }
}

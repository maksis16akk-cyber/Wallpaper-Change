// wallpaper.swift
import Foundation
import AppKit

class WallpaperChanger {
    func setWallpaper(_ path: String) -> Bool {
        let fileURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            print("File not found.")
            return false
        }
        #if os(macOS)
        do {
            try NSWorkspace.shared.setDesktopImageURL(fileURL, forScreen: NSScreen.main!, options: [:])
            return true
        } catch {
            print("Failed to set wallpaper: \(error)")
            return false
        }
        #else
        // Linux or other: use system commands
        let abs = URL(fileURLWithPath: path).path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gsettings", "set", "org.gnome.desktop.background", "picture-uri", "file://"+abs]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            // Try XFCE
            let process2 = Process()
            process2.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process2.arguments = ["xfconf-query", "-c", "xfce4-desktop", "-p", "/backdrop/screen0/monitor0/image-path", "-s", abs]
            do {
                try process2.run()
                process2.waitUntilExit()
                return process2.terminationStatus == 0
            } catch {
                return false
            }
        }
        #endif
    }

    func getRandomImage(from folder: String) -> String? {
        let exts = [".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp"]
        guard let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: folder), includingPropertiesForKeys: nil) else {
            return nil
        }
        var files: [String] = []
        for case let fileURL as URL in enumerator {
            if fileURL.hasDirectoryPath { continue }
            let ext = fileURL.pathExtension.lowercased()
            if exts.contains("." + ext) {
                files.append(fileURL.path)
            }
        }
        return files.randomElement()
    }

    func downloadUnsplash() -> String? {
        guard let url = URL(string: "https://source.unsplash.com/random/1920x1080") else { return nil }
        let semaphore = DispatchSemaphore(value: 0)
        var result: String? = nil
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = NSImage(data: data) {
                let tmp = NSTemporaryDirectory() + "wallpaper_\(Date().timeIntervalSince1970).jpg"
                if let tiff = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiff),
                   let jpeg = bitmap.representation(using: .jpeg, properties: [:]) {
                    try? jpeg.write(to: URL(fileURLWithPath: tmp))
                    result = tmp
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return result
    }

    func slideshow(from folder: String, interval: Int) {
        print("Slideshow from \(folder), interval \(interval)s")
        while true {
            if let img = getRandomImage(from: folder) {
                if setWallpaper(img) {
                    print("Set: \(img)")
                }
            }
            Thread.sleep(forTimeInterval: TimeInterval(interval))
        }
    }
}

func main() {
    let args = CommandLine.arguments.dropFirst()
    var file: String? = nil
    var folder: String? = nil
    var interval: Int = 0
    var unsplash: Bool = false

    var i = args.startIndex
    while i < args.endIndex {
        let arg = args[i]
        switch arg {
        case "--file", "-f":
            if i+1 < args.endIndex { file = args[i+1]; i += 2 } else { i += 1 }
        case "--folder", "-d":
            if i+1 < args.endIndex { folder = args[i+1]; i += 2 } else { i += 1 }
        case "--interval", "-i":
            if i+1 < args.endIndex { interval = Int(args[i+1]) ?? 0; i += 2 } else { i += 1 }
        case "--unsplash", "-u":
            unsplash = true; i += 1
        case "--help", "-h":
            print("Usage: swift wallpaper.swift --file <file> | --folder <dir> [--interval <sec>] | --unsplash")
            return
        default:
            i += 1
        }
    }

    let changer = WallpaperChanger()

    if let f = file {
        _ = changer.setWallpaper(f)
    } else if let f = folder, interval > 0 {
        changer.slideshow(from: f, interval: interval)
    } else if let f = folder {
        if let img = changer.getRandomImage(from: f) {
            _ = changer.setWallpaper(img)
        }
    } else if unsplash {
        if let img = changer.downloadUnsplash() {
            _ = changer.setWallpaper(img)
            try? FileManager.default.removeItem(atPath: img)
        }
    } else {
        print("Usage: swift wallpaper.swift --file <file> | --folder <dir> [--interval <sec>] | --unsplash")
    }
}

main()

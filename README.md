🖼️ Wallpaper Changer – Multi‑Language Edition

A versatile **wallpaper changer utility** that sets desktop backgrounds from local files or online sources.  
Supports random selection, slideshow mode, image download from Unsplash, and cross‑platform operation (Windows, macOS, Linux).  
Built in **7 programming languages** – ideal for automation, personalization, or learning.

## ✨ Features
- **Set wallpaper** – specify an image file path.
- **Random from folder** – choose a random image from a given directory.
- **Slideshow mode** – automatically change wallpaper at a defined interval (e.g., every 60 seconds).
- **Online images** – download random images from Unsplash (or other sources) and set as wallpaper.
- **Cross‑platform** – works on Windows, macOS, and Linux (GNOME, XFCE, etc.).
- **Lightweight** – no heavy dependencies; uses system commands or native APIs.

## 🗂 Languages & Files
| Language          | File                  |
|-------------------|-----------------------|
| Python            | `wallpaper.py`        |
| Go                | `wallpaper.go`        |
| JavaScript (Node) | `wallpaper.js`        |
| C#                | `WallpaperChanger.cs` |
| Java              | `WallpaperChanger.java`|
| Ruby              | `wallpaper.rb`        |
| Swift             | `wallpaper.swift`     |

## 🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.  
Most versions accept command‑line arguments (see `--help`).

| Language | Command |
|----------|---------|
| Python   | `python wallpaper.py --file image.jpg` |
| Go       | `go run wallpaper.go -file image.jpg` |
| JavaScript | `node wallpaper.js --file image.jpg` |
| C#       | `dotnet run -- --file image.jpg` |
| Java     | `javac WallpaperChanger.java && java WallpaperChanger --file image.jpg` |
| Ruby     | `ruby wallpaper.rb --file image.jpg` |
| Swift    | `swift wallpaper.swift --file image.jpg` |

## 📊 Example Usage
```bash
# Set a specific image
wallpaper --file ~/Pictures/photo.jpg

# Set random image from folder
wallpaper --folder ~/Pictures/Wallpapers

# Start slideshow (change every 30 seconds)
wallpaper --folder ~/Pictures/Wallpapers --interval 30

# Download and set a random Unsplash image
wallpaper --unsplash
🔧 Options (Common)
Option	Description
-f, --file FILE	Set wallpaper from a specific image file
-d, --folder DIR	Use random image from DIR
-i, --interval SEC	Slideshow interval (requires --folder)
-u, --unsplash	Download a random image from Unsplash
-h, --help	Show help
⚙️ Dependencies
Python: requests (for Unsplash), Pillow (optional) – pip install requests pillow.

Go: no extra dependencies (uses net/http).

JavaScript: axios (for Unsplash), wallpaper npm – npm install axios wallpaper.

C#: System.Net.Http (built‑in).

Java: no extra dependencies (uses java.net.HttpURLConnection).

Ruby: net/http, json (built‑in).

Swift: Foundation (built‑in).

🤝 Contributing
Add support for more desktop environments, animated wallpapers, or a GUI – PRs welcome!

📜 License
MIT – use freely.

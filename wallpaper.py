
---

# 💻 Code Implementations

## 1. Python (`wallpaper.py`)

```python
# wallpaper.py
import os
import sys
import time
import random
import argparse
import subprocess
import platform
import requests
from pathlib import Path

class WallpaperChanger:
    def __init__(self):
        self.os_type = platform.system()

    def set_wallpaper(self, file_path):
        if not os.path.exists(file_path):
            print(f"Error: File {file_path} not found.")
            return False
        abs_path = os.path.abspath(file_path)
        if self.os_type == "Windows":
            import ctypes
            ctypes.windll.user32.SystemParametersInfoW(20, 0, abs_path, 3)
            return True
        elif self.os_type == "Darwin":
            script = f'osascript -e \'tell application "Finder" to set desktop picture to POSIX file "{abs_path}"\''
            subprocess.run(script, shell=True, check=True)
            return True
        else:  # Linux
            # Try GNOME
            try:
                subprocess.run(["gsettings", "set", "org.gnome.desktop.background", "picture-uri", f"file://{abs_path}"], check=True)
                return True
            except:
                # Try XFCE
                try:
                    subprocess.run(["xfconf-query", "-c", "xfce4-desktop", "-p", "/backdrop/screen0/monitor0/image-path", "-s", abs_path], check=True)
                    return True
                except:
                    print("Could not set wallpaper on this Linux environment.")
                    return False

    def get_random_image(self, folder):
        extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp'}
        files = [f for f in Path(folder).iterdir() if f.suffix.lower() in extensions]
        if not files:
            print(f"No image files found in {folder}")
            return None
        return str(random.choice(files))

    def download_unsplash(self):
        url = "https://api.unsplash.com/photos/random"
        headers = {"Authorization": "Client-ID YOUR_ACCESS_KEY"}  # Replace with your key or use public endpoint
        # For demo, we use a public endpoint without key (limited)
        try:
            response = requests.get("https://source.unsplash.com/random/1920x1080")
            if response.status_code == 200:
                temp_file = "/tmp/wallpaper_unsplash.jpg"
                with open(temp_file, "wb") as f:
                    f.write(response.content)
                return temp_file
        except:
            print("Failed to download from Unsplash")
            return None

    def run_slideshow(self, folder, interval):
        print(f"Starting slideshow from {folder}, interval {interval}s")
        try:
            while True:
                img = self.get_random_image(folder)
                if img:
                    if self.set_wallpaper(img):
                        print(f"Set: {img}")
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\nSlideshow stopped.")

def main():
    parser = argparse.ArgumentParser(description="Wallpaper Changer")
    parser.add_argument("-f", "--file", help="Set specific image file")
    parser.add_argument("-d", "--folder", help="Use random image from folder")
    parser.add_argument("-i", "--interval", type=int, help="Slideshow interval (seconds)")
    parser.add_argument("-u", "--unsplash", action="store_true", help="Download random Unsplash image")
    args = parser.parse_args()

    changer = WallpaperChanger()

    if args.file:
        changer.set_wallpaper(args.file)
    elif args.folder and args.interval:
        changer.run_slideshow(args.folder, args.interval)
    elif args.folder:
        img = changer.get_random_image(args.folder)
        if img:
            changer.set_wallpaper(img)
    elif args.unsplash:
        img = changer.download_unsplash()
        if img:
            changer.set_wallpaper(img)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()

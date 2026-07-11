// wallpaper.go
package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

type WallpaperChanger struct{}

func (w *WallpaperChanger) setWallpaper(filePath string) error {
	abs, err := filepath.Abs(filePath)
	if err != nil {
		return err
	}
	switch runtime.GOOS {
	case "windows":
		// Using SystemParametersInfo via WinAPI (Go doesn't have direct ctypes, so we use PowerShell)
		cmd := exec.Command("powershell", "-Command",
			fmt.Sprintf(`Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@; [Wallpaper]::SystemParametersInfo(20, 0, "%s", 3)`, abs))
		return cmd.Run()
	case "darwin":
		cmd := exec.Command("osascript", "-e",
			fmt.Sprintf(`tell application "Finder" to set desktop picture to POSIX file "%s"`, abs))
		return cmd.Run()
	default: // Linux
		// Try GNOME
		err = exec.Command("gsettings", "set", "org.gnome.desktop.background", "picture-uri", "file://"+abs).Run()
		if err == nil {
			return nil
		}
		// Try XFCE
		err = exec.Command("xfconf-query", "-c", "xfce4-desktop", "-p", "/backdrop/screen0/monitor0/image-path", "-s", abs).Run()
		if err == nil {
			return nil
		}
		return fmt.Errorf("could not set wallpaper")
	}
}

func (w *WallpaperChanger) getRandomImage(folder string) (string, error) {
	exts := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".bmp": true, ".gif": true, ".webp": true}
	files := []string{}
	err := filepath.Walk(folder, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		if !info.IsDir() {
			ext := strings.ToLower(filepath.Ext(path))
			if exts[ext] {
				files = append(files, path)
			}
		}
		return nil
	})
	if err != nil || len(files) == 0 {
		return "", fmt.Errorf("no images found in %s", folder)
	}
	return files[time.Now().UnixNano()%int64(len(files))], nil
}

func (w *WallpaperChanger) downloadUnsplash() (string, error) {
	resp, err := http.Get("https://source.unsplash.com/random/1920x1080")
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	tmpFile, err := os.CreateTemp("", "wallpaper_*.jpg")
	if err != nil {
		return "", err
	}
	defer tmpFile.Close()
	_, err = io.Copy(tmpFile, resp.Body)
	if err != nil {
		return "", err
	}
	return tmpFile.Name(), nil
}

func (w *WallpaperChanger) runSlideshow(folder string, interval int) error {
	fmt.Printf("Starting slideshow from %s, interval %ds\n", folder, interval)
	ticker := time.NewTicker(time.Duration(interval) * time.Second)
	defer ticker.Stop()
	for {
		img, err := w.getRandomImage(folder)
		if err != nil {
			fmt.Println("Error:", err)
			return err
		}
		if err := w.setWallpaper(img); err == nil {
			fmt.Printf("Set: %s\n", img)
		} else {
			fmt.Println("Set failed:", err)
		}
		<-ticker.C
	}
}

func main() {
	file := flag.String("file", "", "Set specific image file")
	folder := flag.String("folder", "", "Use random image from folder")
	interval := flag.Int("interval", 0, "Slideshow interval (seconds)")
	unsplash := flag.Bool("unsplash", false, "Download random Unsplash image")
	flag.Parse()

	changer := &WallpaperChanger{}

	if *file != "" {
		err := changer.setWallpaper(*file)
		if err != nil {
			fmt.Println("Error:", err)
		}
	} else if *folder != "" && *interval > 0 {
		changer.runSlideshow(*folder, *interval)
	} else if *folder != "" {
		img, err := changer.getRandomImage(*folder)
		if err == nil {
			changer.setWallpaper(img)
		} else {
			fmt.Println("Error:", err)
		}
	} else if *unsplash {
		img, err := changer.downloadUnsplash()
		if err == nil {
			changer.setWallpaper(img)
			os.Remove(img) // cleanup
		} else {
			fmt.Println("Error:", err)
		}
	} else {
		fmt.Println("Usage: wallpaper -file <file> | -folder <dir> [-interval <sec>] | -unsplash")
		flag.PrintDefaults()
	}
}

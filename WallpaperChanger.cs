// WallpaperChanger.cs
using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

class WallpaperChanger
{
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    static void SetWallpaperWindows(string path)
    {
        SystemParametersInfo(20, 0, path, 3);
    }

    static void SetWallpaperMac(string path)
    {
        System.Diagnostics.Process.Start("osascript", $"-e 'tell application \"Finder\" to set desktop picture to POSIX file \"{path}\"'");
    }

    static void SetWallpaperLinux(string path)
    {
        try
        {
            System.Diagnostics.Process.Start("gsettings", $"set org.gnome.desktop.background picture-uri file://{path}");
        }
        catch
        {
            try
            {
                System.Diagnostics.Process.Start("xfconf-query", $"-c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s {path}");
            }
            catch
            {
                Console.WriteLine("Could not set wallpaper.");
            }
        }
    }

    static void SetWallpaper(string file)
    {
        if (!File.Exists(file))
        {
            Console.WriteLine($"File {file} not found.");
            return;
        }
        string abs = Path.GetFullPath(file);
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            SetWallpaperWindows(abs);
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            SetWallpaperMac(abs);
        else
            SetWallpaperLinux(abs);
    }

    static string GetRandomImage(string folder)
    {
        string[] exts = { ".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp" };
        var files = Directory.GetFiles(folder).Where(f => exts.Contains(Path.GetExtension(f).ToLower())).ToArray();
        if (files.Length == 0)
        {
            Console.WriteLine($"No images in {folder}");
            return null;
        }
        var rand = new Random();
        return files[rand.Next(files.Length)];
    }

    static async Task<string> DownloadUnsplash()
    {
        using var client = new HttpClient();
        try
        {
            var response = await client.GetAsync("https://source.unsplash.com/random/1920x1080");
            response.EnsureSuccessStatusCode();
            var data = await response.Content.ReadAsByteArrayAsync();
            string tmp = Path.GetTempFileName() + ".jpg";
            await File.WriteAllBytesAsync(tmp, data);
            return tmp;
        }
        catch { return null; }
    }

    static async Task RunSlideshow(string folder, int interval)
    {
        Console.WriteLine($"Slideshow from {folder}, interval {interval}s");
        while (true)
        {
            var img = GetRandomImage(folder);
            if (img != null)
            {
                SetWallpaper(img);
                Console.WriteLine($"Set: {img}");
            }
            await Task.Delay(interval * 1000);
        }
    }

    static async Task Main(string[] args)
    {
        string file = null, folder = null;
        int interval = 0;
        bool unsplash = false;

        for (int i = 0; i < args.Length; i++)
        {
            if (args[i] == "--file" || args[i] == "-f") file = args[++i];
            else if (args[i] == "--folder" || args[i] == "-d") folder = args[++i];
            else if (args[i] == "--interval" || args[i] == "-i") interval = int.Parse(args[++i]);
            else if (args[i] == "--unsplash" || args[i] == "-u") unsplash = true;
            else if (args[i] == "--help" || args[i] == "-h")
            {
                Console.WriteLine("Usage: dotnet run -- --file <file> | --folder <dir> [--interval <sec>] | --unsplash");
                return;
            }
        }

        if (file != null)
            SetWallpaper(file);
        else if (folder != null && interval > 0)
            await RunSlideshow(folder, interval);
        else if (folder != null)
        {
            var img = GetRandomImage(folder);
            if (img != null) SetWallpaper(img);
        }
        else if (unsplash)
        {
            var img = await DownloadUnsplash();
            if (img != null)
            {
                SetWallpaper(img);
                File.Delete(img);
            }
        }
        else
        {
            Console.WriteLine("Usage: dotnet run -- --file <file> | --folder <dir> [--interval <sec>] | --unsplash");
        }
    }
}

// WallpaperChanger.java
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;

public class WallpaperChanger {
    private static String osName = System.getProperty("os.name").toLowerCase();

    public static void setWallpaper(String path) throws Exception {
        if (!Files.exists(Paths.get(path))) {
            System.out.println("File not found: " + path);
            return;
        }
        String abs = new File(path).getAbsolutePath();
        if (osName.contains("win")) {
            // Use PowerShell for Windows
            String cmd = "powershell -Command \"Add-Type -TypeDefinition @\"\nusing System;\nusing System.Runtime.InteropServices;\npublic class Wallpaper {\n    [DllImport(\"user32.dll\", CharSet=CharSet.Auto)]\n    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);\n}\n\"@; [Wallpaper]::SystemParametersInfo(20, 0, \"" + abs + "\", 3)\"";
            Runtime.getRuntime().exec(new String[]{"powershell", "-Command", cmd});
        } else if (osName.contains("mac")) {
            Runtime.getRuntime().exec(new String[]{"osascript", "-e",
                    "tell application \"Finder\" to set desktop picture to POSIX file \"" + abs + "\""});
        } else {
            // Linux: try GNOME then XFCE
            try {
                Runtime.getRuntime().exec(new String[]{"gsettings", "set", "org.gnome.desktop.background",
                        "picture-uri", "file://" + abs});
            } catch (Exception e) {
                Runtime.getRuntime().exec(new String[]{"xfconf-query", "-c", "xfce4-desktop",
                        "-p", "/backdrop/screen0/monitor0/image-path", "-s", abs});
            }
        }
    }

    public static String getRandomImage(String folder) {
        String[] exts = {".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp"};
        File dir = new File(folder);
        if (!dir.isDirectory()) return null;
        File[] files = dir.listFiles((d, name) -> {
            for (String ext : exts) if (name.toLowerCase().endsWith(ext)) return true;
            return false;
        });
        if (files == null || files.length == 0) return null;
        return files[ThreadLocalRandom.current().nextInt(files.length)].getAbsolutePath();
    }

    public static String downloadUnsplash() throws Exception {
        URL url = new URL("https://source.unsplash.com/random/1920x1080");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        try (InputStream in = conn.getInputStream()) {
            String tmp = System.getProperty("java.io.tmpdir") + File.separator + "wallpaper_" + System.currentTimeMillis() + ".jpg";
            Files.copy(in, Paths.get(tmp), StandardCopyOption.REPLACE_EXISTING);
            return tmp;
        }
    }

    public static void slideshow(String folder, int interval) throws InterruptedException {
        System.out.println("Slideshow from " + folder + ", interval " + interval + "s");
        while (true) {
            String img = getRandomImage(folder);
            if (img != null) {
                try {
                    setWallpaper(img);
                    System.out.println("Set: " + img);
                } catch (Exception e) {
                    System.out.println("Failed: " + e.getMessage());
                }
            }
            Thread.sleep(interval * 1000L);
        }
    }

    public static void main(String[] args) throws Exception {
        String file = null, folder = null;
        int interval = 0;
        boolean unsplash = false;

        for (int i = 0; i < args.length; i++) {
            if (args[i].equals("--file") || args[i].equals("-f")) file = args[++i];
            else if (args[i].equals("--folder") || args[i].equals("-d")) folder = args[++i];
            else if (args[i].equals("--interval") || args[i].equals("-i")) interval = Integer.parseInt(args[++i]);
            else if (args[i].equals("--unsplash") || args[i].equals("-u")) unsplash = true;
            else if (args[i].equals("--help") || args[i].equals("-h")) {
                System.out.println("Usage: java WallpaperChanger --file <file> | --folder <dir> [--interval <sec>] | --unsplash");
                return;
            }
        }

        if (file != null) {
            setWallpaper(file);
        } else if (folder != null && interval > 0) {
            slideshow(folder, interval);
        } else if (folder != null) {
            String img = getRandomImage(folder);
            if (img != null) setWallpaper(img);
        } else if (unsplash) {
            String img = downloadUnsplash();
            if (img != null) {
                setWallpaper(img);
                Files.deleteIfExists(Paths.get(img));
            }
        } else {
            System.out.println("Usage: java WallpaperChanger --file <file> | --folder <dir> [--interval <sec>] | --unsplash");
        }
    }
}

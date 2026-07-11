# wallpaper.rb
require 'optparse'
require 'net/http'
require 'uri'
require 'json'
require 'tmpdir'

class WallpaperChanger
  def initialize
    @os = RUBY_PLATFORM
  end

  def set_wallpaper(file)
    return false unless File.exist?(file)
    abs = File.expand_path(file)
    case @os
    when /mswin|mingw|windows/
      # Windows: use PowerShell + WinAPI
      cmd = "powershell -Command \"Add-Type -TypeDefinition @\\\"\nusing System;\nusing System.Runtime.InteropServices;\npublic class Wallpaper {\n    [DllImport(\"user32.dll\", CharSet=CharSet.Auto)]\n    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);\n}\n\\\"@; [Wallpaper]::SystemParametersInfo(20, 0, \\\"#{abs}\\\", 3)\""
      system(cmd)
    when /darwin/
      system("osascript", "-e", "tell application \"Finder\" to set desktop picture to POSIX file \"#{abs}\"")
    else
      # Linux
      unless system("gsettings", "set", "org.gnome.desktop.background", "picture-uri", "file://#{abs}")
        system("xfconf-query", "-c", "xfce4-desktop", "-p", "/backdrop/screen0/monitor0/image-path", "-s", abs)
      end
    end
    true
  end

  def get_random_image(folder)
    exts = %w[.jpg .jpeg .png .bmp .gif .webp]
    Dir.glob(File.join(folder, '*')).select { |f| File.file?(f) && exts.include?(File.extname(f).downcase) }.sample
  end

  def download_unsplash
    uri = URI('https://source.unsplash.com/random/1920x1080')
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      tmp = File.join(Dir.tmpdir, "wallpaper_#{Time.now.to_i}.jpg")
      File.binwrite(tmp, response.body)
      tmp
    else
      nil
    end
  end

  def slideshow(folder, interval)
    puts "Slideshow from #{folder}, interval #{interval}s"
    loop do
      img = get_random_image(folder)
      if img
        set_wallpaper(img)
        puts "Set: #{img}"
      end
      sleep interval
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.on('-f', '--file FILE', 'Set specific image file') { |v| options[:file] = v }
  opts.on('-d', '--folder DIR', 'Use random image from folder') { |v| options[:folder] = v }
  opts.on('-i', '--interval SEC', Integer, 'Slideshow interval (seconds)') { |v| options[:interval] = v }
  opts.on('-u', '--unsplash', 'Download random Unsplash image') { options[:unsplash] = true }
  opts.on('-h', '--help', 'Show help') { puts opts; exit }
end.parse!

changer = WallpaperChanger.new

if options[:file]
  changer.set_wallpaper(options[:file])
elsif options[:folder] && options[:interval]
  changer.slideshow(options[:folder], options[:interval])
elsif options[:folder]
  img = changer.get_random_image(options[:folder])
  changer.set_wallpaper(img) if img
elsif options[:unsplash]
  img = changer.download_unsplash
  if img
    changer.set_wallpaper(img)
    File.delete(img)
  end
else
  puts "Usage: ruby wallpaper.rb --file <file> | --folder <dir> [--interval <sec>] | --unsplash"
end

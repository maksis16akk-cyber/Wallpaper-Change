// wallpaper.js
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const axios = require('axios');
const wallpaper = require('wallpaper');

const os = require('os');

class WallpaperChanger {
    async setWallpaper(filePath) {
        try {
            const absPath = path.resolve(filePath);
            await wallpaper.set(absPath);
            return true;
        } catch (err) {
            console.error('Failed to set wallpaper:', err.message);
            return false;
        }
    }

    async getRandomImage(folder) {
        const exts = ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp'];
        const files = fs.readdirSync(folder)
            .filter(f => exts.includes(path.extname(f).toLowerCase()))
            .map(f => path.join(folder, f));
        if (files.length === 0) return null;
        return files[Math.floor(Math.random() * files.length)];
    }

    async downloadUnsplash() {
        try {
            const response = await axios({
                method: 'get',
                url: 'https://source.unsplash.com/random/1920x1080',
                responseType: 'stream'
            });
            const tmpFile = path.join(os.tmpdir(), `wallpaper_${Date.now()}.jpg`);
            const writer = fs.createWriteStream(tmpFile);
            response.data.pipe(writer);
            return new Promise((resolve, reject) => {
                writer.on('finish', () => resolve(tmpFile));
                writer.on('error', reject);
            });
        } catch (err) {
            console.error('Download failed:', err.message);
            return null;
        }
    }

    async runSlideshow(folder, interval) {
        console.log(`Starting slideshow from ${folder}, interval ${interval}s`);
        setInterval(async () => {
            const img = await this.getRandomImage(folder);
            if (img) {
                const ok = await this.setWallpaper(img);
                if (ok) console.log(`Set: ${img}`);
            }
        }, interval * 1000);
    }
}

async function main() {
    const args = process.argv.slice(2);
    let file = null, folder = null, interval = 0, unsplash = false;
    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--file' || args[i] === '-f') { file = args[++i]; }
        else if (args[i] === '--folder' || args[i] === '-d') { folder = args[++i]; }
        else if (args[i] === '--interval' || args[i] === '-i') { interval = parseInt(args[++i], 10); }
        else if (args[i] === '--unsplash' || args[i] === '-u') { unsplash = true; }
        else if (args[i] === '--help' || args[i] === '-h') {
            console.log('Usage: node wallpaper.js --file <file> | --folder <dir> [--interval <sec>] | --unsplash');
            process.exit(0);
        }
    }

    const changer = new WallpaperChanger();

    if (file) {
        await changer.setWallpaper(file);
    } else if (folder && interval > 0) {
        await changer.runSlideshow(folder, interval);
    } else if (folder) {
        const img = await changer.getRandomImage(folder);
        if (img) await changer.setWallpaper(img);
    } else if (unsplash) {
        const img = await changer.downloadUnsplash();
        if (img) {
            await changer.setWallpaper(img);
            fs.unlinkSync(img); // cleanup
        }
    } else {
        console.log('Usage: node wallpaper.js --file <file> | --folder <dir> [--interval <sec>] | --unsplash');
    }
}

main().catch(console.error);

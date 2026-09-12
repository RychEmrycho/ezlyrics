# ezlyrics 🎵

A lightweight, freely draggable macOS floating lyrics HUD. `ezlyrics` automatically detects your currently playing media, fetches perfectly time-synced lyrics, and displays them as a customizable floating overlay on your screen.

## ✨ Features
- **Zero-Friction Detection:** Works out of the box with Apple Music, Spotify, Safari, Chrome, and more. No manual searching required!
- **Draggable Overlay:** A sleek, notch-friendly floating window that you can place anywhere on your screen.
- **Karaoke-Style Fill:** 60fps real-time syllable-by-syllable lyric highlighting.
- **macOS Native Translation:** Uses Apple's on-device neural translation layer (macOS 15+) to translate lyrics in real-time.
- **Smart Silence:** Detects long instrumental gaps and gracefully falls back to `•••`.
- **Manual Overrides:** Menu bar interface to manually search, re-bind lyrics, and adjust sync offsets down to the millisecond.

## 🚀 Installation

### Option 1: Download Pre-compiled Release
Since this app utilizes macOS private APIs (`MediaRemote`) to magically read media metadata without requiring complex permissions, the binary is not signed for the App Store.

1. Go to the [Releases](../../releases) page and download `ezlyrics.app.zip`.
2. Unzip and drag `ezlyrics.app` to your `Applications` folder.
3. **Bypass Gatekeeper:** macOS will likely warn you that the app is from an unidentified developer. To fix this, open your Terminal and run:
   ```bash
   xattr -cr /Applications/ezlyrics.app
   ```
4. Double click `ezlyrics.app` in your Applications folder to run it!

### Option 2: Build from Source
If you prefer to compile the app yourself, you can use the included install script.

1. Clone this repository:
   ```bash
   git clone https://github.com/RychEmrycho/ezlyrics.git
   cd ezlyrics
   ```
2. Run the install script (this will compile the release binary and bundle it into your `~/Applications` folder):
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## ⚙️ Customization
Click on the `ezlyrics` icon in your menu bar and select **Settings...** to customize:
- Typography (System, Rounded, Monospaced, Serif)
- Alignment (Left, Center, Right)
- Font Size & Text Color
- Background Opacity
- Number of Lines (Single, Two Lines, Three Lines)
- Enable/Disable macOS Native Translation

## 📝 License
This project is open-sourced under the GNU General Public License v3.0 (GPLv3). See the [LICENSE](LICENSE) file for more details.

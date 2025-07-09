# webm-to-mp4

An Ubuntu Nautilus script to convert `.webm` files into `.mp4`.

## Motivation

Ubuntu’s default screen recorder saves clips as `.webm`, but most workflows (video editing, sharing, etc.) favor `.mp4`. 

I started by utilizing [mebaysan’s gist](https://gist.github.com/mebaysan/b58df7a0c495577902742e29dec9f80f), then started tailoring it to my needs.

## Features

- **Right‑click convert**: Select one or many `.webm` files in Nautilus, choose *Scripts → webm-to-mp4 → CONVERT!*, and they’re converted in the background.  
- **Configurable behavior**: Choose output folder (same as source or a custom directory), optional deletion of originals, filename suffix, and desktop notifications via a GTK GUI.  
- **Status checker**: Right‑click → *converter status* to see progress or final results.  
- **Uninstaller**: Easily remove all scripts, icons, and Nautilus entries.

## Prerequisites

- Linux with Nautilus (e.g. Ubuntu, other GNOME‑based distros)  
- `ffmpeg`  
- `zenity`, `yad` (for GUIs)  
- `libnotify-bin` (for desktop notifications)  

```bash
sudo apt install ffmpeg zenity yad libnotify-bin
```

## Installation
```bash
# Download or clone this repo
git clone https://github.com/<your‑username>/webm-to-mp4.git
cd webm-to-mp4

# Run the installer
bash install-webm-to-mp4.sh
```
You’ll then find new entries under Scripts → webm‑to‑mp4 in your right‑click menu.

## Usage
### Convert files
- In Nautilus, select one or more .webm files.
- Right‑click → Scripts → webm‑to‑mp4 → CONVERT!
- Conversion runs in the background; you’ll get notifications and can check status via Scripts → webm‑to‑mp4 → converter status.

### Configure settings
Right‑click → Scripts → webm‑to‑mp4 → converter configuration, and adjust:
- Output location (same folder vs. custom path)
- Delete original after conversion
- Filename suffix
- Desktop notifications

### Configuration File
Located at ~/.config/webm-to-mp4/webm-to-mp4.conf. You can also edit it by hand:

```ini
output_dir=/path/to/mp4s      # or “same”
delete_original=false         
output_suffix=_converted      
notifications=true            
```
### Uninstallation
Right‑click → Scripts → webm‑to‑mp4 → UNINSTALL webm‑to‑mp4, or:

```bash
~/.local/bin/webm-to-mp4-uninstall
```
TODO / Questions for You
License: Do you have a preferred open‑source license? (MIT, Apache 2.0, GPL, etc.)

Usage examples or screenshots: Would you like to include sample commands, a GIF of the Nautilus integration, or screenshots of the GUI?

Badges: Any CI/CD, version, or packaging badges you want at the top?

Contribution guidelines: Should we add a CONTRIBUTING.md with style/PR rules?

Versioning: How do you prefer to tag releases? (e.g. v1.0.0)

Let me know which of these you’d like to fill in or any other details to include!



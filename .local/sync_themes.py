#!/usr/bin/env python3

import os
import sys
import subprocess
import random
import time
import shutil
from pathlib import Path

def run_command(cmd, check=True, shell=True, capture_output=False):
    """Run a shell command with proper error handling."""
    try:
        if capture_output:
            result = subprocess.run(cmd, shell=shell, check=check, 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        else:
            subprocess.run(cmd, shell=shell, check=check, 
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        if check:
            print(f"Error running command: {cmd}")
            print(f"Error: {e}")
            sys.exit(1)

def get_wallpaper():
    """Get wallpaper path from argument or random selection."""
    if len(sys.argv) > 1:
        return sys.argv[1]
    
    wallpapers_dir = Path.home() / "Pictures" / "Wallpapers"
    if not wallpapers_dir.exists():
        print(f"Wallpapers directory doesn't exist: {wallpapers_dir}")
        sys.exit(1)
    
    wallpaper_files = list(wallpapers_dir.glob("*"))
    wallpaper_files = [f for f in wallpaper_files if f.is_file()]
    
    if not wallpaper_files:
        print("No wallpaper files found in the wallpapers directory")
        sys.exit(1)
    
    return str(random.choice(wallpaper_files))

def setup_paths():
    """Setup all the necessary file paths."""
    home = Path.home()
    return {
        'wal_cache': home / ".cache" / "wal",
        'kvantum_config': home / ".config" / "Kvantum" / "wal.kvconfig",
        'dunst_colors': home / ".cache" / "wal" / "colors-dunst",
        'dunst_config': home / ".config" / "dunst" / "dunstsrc",
        'wal_colors': home / ".cache" / "wal" / "colors",
        'wal_rofi_colors': home / ".cache" / "wal" / "colors-rofi-dark.rasi",
        'rofi_config': home / ".config" / "rofi" / "wal-dark.rasi",
        'hypr_config': home / ".config" / "hypr" / "hyprland.conf.d" / "99-pywal.conf",
        'actual_theme': home / "Ricing" / "actual_theme",
    }

def generate_pywal_theme(wallpaper):
    """Generate theme with pywal."""
    print(f"Using wallpaper: {wallpaper}")
    
    if not Path(wallpaper).exists():
        print(f"Wallpaper file doesn't exist: {wallpaper}")
        sys.exit(1)
    
    run_command(f'wal -n -i "{wallpaper}"')

def copy_wal_cache_to_actual_theme(paths):
    """Copy .cache/wal/* to ~/Ricing/actual_theme."""
    paths['actual_theme'].mkdir(parents=True, exist_ok=True)
    wal_cache = Path.home() / ".cache" / "wal"
    
    for item in wal_cache.iterdir():
        if item.is_file():
            shutil.copy2(item, paths['actual_theme'] / item.name)

def set_wallpaper(wallpaper):
    """Set wallpaper using swww."""
    run_command(f'swww img "{wallpaper}" --transition-type fade --transition-duration 1')

def configure_rofi(paths):
    """Configure Rofi with pywal colors."""
    if paths['wal_rofi_colors'].exists():
        # Ensure the rofi config directory exists
        paths['rofi_config'].parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(paths['wal_rofi_colors'], paths['rofi_config'])
    else:
        print(f"Rofi colors file doesn't exist: {paths['wal_rofi_colors']}")
        sys.exit(1)

def configure_dunst(paths):
    """Configure Dunst with pywal colors."""
    if paths['dunst_colors'].exists():
        # Ensure the dunst config directory exists
        paths['dunst_config'].parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(paths['dunst_colors'], paths['dunst_config'])
    else:
        print(f"Dunst colors file doesn't exist: {paths['dunst_colors']}")

def configure_hyprland(paths):
    """Configure Hyprland with pywal colors."""
    
    
    with open(paths['hypr_config'], 'w') as f:
        f.write(hypr_config_content)

def restart_services():
    """Restart various services to apply new themes."""
    # Set Kvantum theme
    run_command("kvantummanager --set pywal", check=False)
    run_command("nwg-look -a my-custom-theme", check=False)
    
    # Kill and restart waybar
    run_command("pkill waybar", check=False)
    time.sleep(0.2)
    subprocess.Popen("waybar", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # Kill and restart dunst
    run_command("pkill dunst", check=False)
    time.sleep(0.2)
    subprocess.Popen(["dunst","-config","/home/chuya/.config/dunst/custom-dunstsrc"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Reload hyprland configuration
    run_command("hyprctl reload", check=False)

def symlinc_wallpaper(wallpaper):
    """Create a symlinc of the wallpaper inside ~"""
    run_command(f'ln -s -f {wallpaper} ~/.current_wallpaper')

def send_notification():
    """Send success notification."""
    run_command('notify-send "Thème Pywal appliqué" "Le thème Pywal a été appliqué avec succès." -u low', check=False)

def main():
    """Main function to orchestrate the theme synchronization."""
    try:
        wallpaper = get_wallpaper()
        paths = setup_paths()
        generate_pywal_theme(wallpaper)
        copy_wal_cache_to_actual_theme(paths)

        set_wallpaper(wallpaper)
        symlinc_wallpaper(wallpaper)

        restart_services()
        
        send_notification()
        print("Theme synchronization completed successfully!")
        
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

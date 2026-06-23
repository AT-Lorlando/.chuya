#!/usr/bin/env python3
"""
Waybar custom/workspaces module for Hyprland.
- Streams updates on Hyprland socket2 events.
- Reads matugen colors from ~/.config/waybar/colors-matugen.css.
- Renders per-workspace Nerd Font icons for up to 2 clients.
- Outputs Pango markup (requires "escape": false in waybar config).
"""
import json, os, re, socket, subprocess
from pathlib import Path

COLORS_FILE = Path.home() / ".config/waybar/colors-matugen.css"

# Fallback palette if colors-matugen.css is unreadable.
DEFAULT_COLORS = {
    "primary": "#ffb3b1",
    "foreground": "#f0dedd",
    "on_surface_variant": "#d7c1c0",
    "outline_variant": "#524342",
}

def load_colors():
    colors = dict(DEFAULT_COLORS)
    try:
        text = COLORS_FILE.read_text()
        for m in re.finditer(r'@define-color\s+(\w+)\s+(#[0-9a-fA-F]{6,8})', text):
            colors[m.group(1)] = m.group(2)[:7]  # strip alpha if present
    except Exception:
        pass
    return colors

# Window class (lowercased) -> Nerd Font glyph.
ICON_MAP = {
    # editors / IDE
    "code": "\U000f0a1e",              # 󰨞 VS Code
    "code-oss": "\U000f0a1e",
    "code-url-handler": "\U000f0a1e",
    "visual-studio-code": "\U000f0a1e",
    "cursor": "\U000f0a1e",
    "obsidian": "\U000f1237",          # 󱈷 (note icon)
    "claude": "\U000f1a73",            # 󱩳 AI/bot glyph
    "sublime_text": "\U000f0a1e",
    "neovide": "\ue62b",               #
    # browsers
    "firefox": "\U000f0239",           # 󰈹
    "firefox-esr": "\U000f0239",
    "zen": "\U000f0239",
    "microsoft-edge": "\U000f01e9",    # 󰇩
    "microsoft-edge-dev": "\U000f01e9",
    "microsoft-edge-beta": "\U000f01e9",
    "msedge": "\U000f01e9",
    "edge": "\U000f01e9",
    "chromium": "\uf268",              #
    "google-chrome": "\uf268",
    "chrome": "\uf268",
    "brave-browser": "\uf268",
    # terminals
    "kitty": "\U000f011b",             # 󰄛
    "org.wezfurlong.wezterm": "\uf489",
    "alacritty": "\uf489",
    "foot": "\uf489",
    # file managers
    "thunar": "\U000f024b",            # 󰉋
    "org.gnome.nautilus": "\U000f024b",
    "nautilus": "\U000f024b",
    "dolphin": "\U000f024b",
    "org.kde.dolphin": "\U000f024b",
    "ranger": "\U000f024b",
    # chat / social
    "discord": "\U000f066f",           # 󰙯
    "vesktop": "\U000f066f",
    "webcord": "\U000f066f",
    "telegram-desktop": "\uf2c6",
    "telegramdesktop": "\uf2c6",
    "org.telegram.desktop": "\uf2c6",
    "slack": "\U000f04b1",             # 󰒱
    "signal": "\uf3c5",
    # media
    "spotify": "\U000f04c7",           # 󰓇
    "vlc": "\U000f057c",               # 󰕼
    "mpv": "\uf03d",
    # creative
    "gimp": "\ue61a",
    "inkscape": "\ue61c",
    "blender": "\U000f00ab",           # 󰂫
    "krita": "\ue630",
    # games / misc
    "steam": "\U000f04d3",             # 󰓓
    "lutris": "\uf11b",
    # office
    "libreoffice": "\U000f0386",
    "libreoffice-writer": "\U000f0219",
    "libreoffice-calc": "\U000f021b",
    "libreoffice-impress": "\U000f0220",
    "thunderbird": "\uf0e0",
    # system
    "pavucontrol": "\uf028",
    "blueman-manager": "\uf294",
    "nm-connection-editor": "\uf1eb",
    "qalculate-gtk": "\uf1ec",
}

DEFAULT_ICON  = "\U000f0234"  # 󰈴 generic window glyph
INDICATOR_ON  = ""      # ● filled dot
INDICATOR_OFF = ""      # ○ empty dot
SEPARATOR     = " "           # between workspace slots

def get_icon(cls):
    c = (cls or "").lower().strip()
    if not c:
        return DEFAULT_ICON
    if c in ICON_MAP:
        return ICON_MAP[c]
    # partial match on first token / substring
    for key, ic in ICON_MAP.items():
        if key in c:
            return ic
    return DEFAULT_ICON

def get_state():
    workspaces = json.loads(subprocess.check_output(["hyprctl", "workspaces", "-j"]))
    clients    = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
    active     = json.loads(subprocess.check_output(["hyprctl", "activeworkspace", "-j"]))
    return workspaces, clients, active

def span(text, color=None):
    if color is None:
        return f"<span>{text}</span>"
    return f"<span foreground='{color}'>{text}</span>"

def build_and_print():
    colors = load_colors()
    try:
        workspaces, clients, active = get_state()
    except Exception:
        return
    active_id = active.get("id", 1)

    ws_clients = {}
    for c in clients:
        wid = c.get("workspace", {}).get("id", -1)
        if wid > 0:
            ws_clients.setdefault(wid, []).append(c.get("class", ""))

    all_ids = sorted(set(range(1, 6)) | {ws["id"] for ws in workspaces if ws["id"] > 0})
    ind_slots = []
    icon_slots = []
    for wid in all_ids:
        cls_list = ws_clients.get(wid, [])
        is_active = (wid == active_id)
        has_wins = bool(cls_list)

        ind_glyph = INDICATOR_ON if is_active else INDICATOR_OFF
        if is_active:
            ind_color = colors["primary"]
        elif has_wins:
            ind_color = colors["on_surface_variant"]
        else:
            ind_color = colors["outline_variant"]
        # slot = 5-char wide: "  ●  "
        ind_slots.append(
            span(f"{ind_glyph}", color=ind_color)
        )
        icon_color = colors["primary"] if is_active else colors["on_surface_variant"]
        if not cls_list:
            row = "   "               # 5 spaces
        elif len(cls_list) == 1:
            row = f" {get_icon(cls_list[0])} "
        else:
            row = f"{get_icon(cls_list[0])}|{get_icon(cls_list[1])}"
        icon_slots.append(
            span(row, color=icon_color)
        )
        
    t = "  " + "   ".join(ind_slots)
    t += "\n "
    t += " ".join(icon_slots)
    print(json.dumps({"text": t, "tooltip": "", "class": ""}, ensure_ascii=False), flush=True)

def main():
    build_and_print()
    uid = os.getuid()
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    sock_path = f"/run/user/{uid}/hypr/{sig}/.socket2.sock"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(sock_path)
        buf = ""
        while True:
            data = s.recv(4096)
            if not data:
                break
            buf += data.decode(errors="ignore")
            while "\n" in buf:
                line, buf = buf.split("\n", 1)
                if any(line.startswith(e) for e in (
                    "workspace>>", "openwindow>>", "closewindow>>",
                    "movewindow>>", "focusedmon>>", "activewindow>>",
                    "changefloatingmode>>", "windowtitle>>",
                )):
                    build_and_print()

if __name__ == "__main__":
    main()

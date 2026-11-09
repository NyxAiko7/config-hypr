pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Список обоев и применение: wal + установка обоев
Singleton {
    id: root

    property var files: []
    property string current: ""
    property string customDir: ""          // папка, выбранная в окне (сохраняется на диске)
    readonly property string dir: customDir !== "" ? customDir
        : (Config.wallpaperDir !== "" ? Config.wallpaperDir : (Quickshell.env("HOME") + "/Pictures/Wallpapers"))

    // ── обзор каталогов ──
    property string browsePath: ""
    property var subdirs: []
    property int browseCount: 0

    function browse(p) {
        dirProc.command = ["sh", "-c",
            'p="$1"; [ -d "$p" ] || p="$HOME"; cd "$p" || exit 0; printf "%s\\n" "$PWD"; for d in */; do [ -d "$d" ] && printf "%s\\n" "${d%/}"; done',
            "sh", p]
        dirProc.running = true
    }
    function up() {
        const p = browsePath.replace(/\/[^\/]*\/?$/, "")
        browse(p === "" ? "/" : p)
    }
    function setDir(p) {
        customDir = p
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.local/state/quickshell" && printf "%s" "$1" > "$HOME/.local/state/quickshell/wallpaper-dir"',
            "sh", p])
        refresh()
    }

    function refresh() {
        listProc.command = ["sh", "-c",
            'd="$1"; [ -d "$d" ] || d="$HOME/Pictures"; find "$d" -maxdepth 2 -type f | grep -iE "[.](jpe?g|png|webp)$" | sort',
            "sh", dir]
        listProc.running = true
    }

    function apply(path, originX, originY) {
        current = path

        // wal запускаем в фоне, чтобы обои появлялись сразу, а палитра догнала чуть позже
        if (Config.wallpaperSetter !== "") {
            Quickshell.execDetached(["sh", "-c",
                'f="$1"; (wal -i "$f" -n -q >/dev/null 2>&1 &); ' + Config.wallpaperSetter,
                "sh", path])
            return
        }

        // Клик по миниатюре — обои «расцветают» из этой точки.
        // Случайное переключение — каждый раз другой диагональный характер.
        const hasOrigin = typeof originX === "number" && typeof originY === "number"
        let type, angle, wave, pos
        if (hasOrigin) {
            type = "grow"
            angle = "45"
            wave = "22,14"
            pos = Math.max(0, Math.min(1, originX)).toFixed(4) + "," +
                  (1 - Math.max(0, Math.min(1, originY))).toFixed(4)
        } else {
            const variants = [
                { t: "wave",  a: String(16 + Math.floor(Math.random() * 44)), w: "26,16" },
                { t: "outer", a: "45", w: "20,20" },
                { t: "grow",  a: "45", w: "20,20" }
            ]
            const v = variants[Math.floor(Math.random() * variants.length)]
            type = v.t
            angle = v.a
            wave = v.w
            pos = (0.2 + Math.random() * 0.6).toFixed(4) + "," +
                  (0.2 + Math.random() * 0.6).toFixed(4)
        }

        const setter =
            'w=""; if command -v awww >/dev/null 2>&1; then w=awww; elif command -v swww >/dev/null 2>&1; then w=swww; fi; ' +
            'if [ -n "$w" ]; then ' +
            '  if ! "$w" query >/dev/null 2>&1; then ' +
            '    ("$w-daemon" >/dev/null 2>&1 &); i=0; ' +
            '    while [ $i -lt 20 ]; do "$w" query >/dev/null 2>&1 && break; sleep 0.05; i=$((i+1)); done; ' +
            '  fi; ' +
            '  "$w" img "$f" --resize crop ' +
            '    --transition-type "$2" --transition-pos "$3" ' +
            '    --transition-angle "$4" --transition-wave "$5" ' +
            '    --transition-duration 0.55 --transition-fps 120 ' +
            '    --transition-bezier 0.22,1,0.36,1; ' +
            'elif command -v hyprctl >/dev/null 2>&1 && pgrep -x hyprpaper >/dev/null 2>&1; then ' +
            '  hyprctl hyprpaper preload "$f"; hyprctl hyprpaper wallpaper ",$f"; ' +
            'else ' +
            '  pkill -x swaybg; (swaybg -i "$f" -m fill >/dev/null 2>&1 &); ' +
            'fi'
        Quickshell.execDetached(["sh", "-c",
            'f="$1"; (wal -i "$f" -n -q >/dev/null 2>&1 &); ' + setter,
            "sh", path, type, pos, angle, wave])
    }

    function random() {
        if (files.length > 0) apply(files[Math.floor(Math.random() * files.length)])
    }

    Process {
        id: dirProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0)
                if (lines.length === 0) return
                root.browsePath = lines[0]
                root.subdirs = lines.slice(1)
                countProc.command = ["sh", "-c",
                    'find "$1" -maxdepth 2 -type f 2>/dev/null | grep -ciE "[.](jpe?g|png|webp)$"',
                    "sh", lines[0]]
                countProc.running = true
            }
        }
    }
    Process {
        id: countProc
        stdout: StdioCollector { onStreamFinished: root.browseCount = parseInt(text) || 0 }
    }

    // запомненная папка
    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/wallpaper-dir"
        onLoaded: { root.customDir = stateFile.text().trim(); root.refresh() }
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l.length > 0)
        }
    }

    // текущие обои, которые запомнил pywal
    FileView {
        id: curFile
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/wal/wal"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = curFile.text().trim()
    }
}

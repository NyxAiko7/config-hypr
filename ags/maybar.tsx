import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"
import Mpris from "gi://AstalMpris"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

const exec = (cmd: string) => {
  try {
    GLib.spawn_command_line_async(cmd)
  } catch (err) {
    console.error(`Exec error: ${err}`)
  }
}

const decodeBytes = (bytes: Uint8Array | null): string => {
  if (!bytes) return ""
  return new TextDecoder("utf-8").decode(bytes).trim()
}

const resolveCoverPath = (uri: string): string => {
  if (!uri) return ""

  if (uri.startsWith("http://") || uri.startsWith("https://")) {
    return uri
  }

  if (uri.startsWith("file://")) {
    const localPath = GLib.uri_get_local_path(uri)
    if (localPath) return localPath
    return GLib.uri_unescape_string(uri.replace(/^file:\/\//, ""), null) || ""
  }

  return uri
}

function CpuMonitor() {
  const cpuUsage = createPoll(
    "󰍛 0%",
    2000,
    "sh -c \"top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'\" || echo 0",
    out => {
      const val = parseFloat(out.replace(",", ".")) || 0
      return `󰍛 ${Math.round(val)}%`
    }
  )

  return (
    <button
      cssClasses={["sys-cpu-btn"]}
      tooltipText="Открыть монитор ресурсов (btop)"
      onClicked={() => exec("kitty -e btop || alacritty -e btop || foot -e btop")}>
      <label label={cpuUsage} />
    </button>
  )
}

function RamMonitor() {
  const ramUsage = createPoll(
    "󰘚 0%",
    2000,
    "sh -c \"free -m | awk '/Mem:/ {printf \\\"%.0f\\\", $3/$2*100}'\" || echo 0",
    out => {
      const val = parseInt(out.trim(), 10) || 0
      return `󰘚 ${val}%`
    }
  )

  return (
    <button
      cssClasses={["sys-ram-btn"]}
      tooltipText="Открыть монитор ресурсов (btop)"
      onClicked={() => exec("kitty -e btop || alacritty -e btop || foot -e btop")}>
      <label label={ramUsage} />
    </button>
  )
}

function QuickSettingsPopover() {
  const wifiState = createPoll(
    "Offline",
    4000,
    "sh -c \"nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2\" || echo 'Offline'",
    out => {
      const ssid = out.trim()
      return ssid && ssid !== "" && ssid !== "--" ? ssid : "Offline"
    }
  )

  const btState = createPoll(
    "off",
    4000,
    "sh -c 'bluetoothctl show 2>/dev/null | grep -q \"Powered: yes\" && echo on || echo off'",
    out => out.trim()
  )

  const volVal = createPoll("50%", 1500, "sh -c 'wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null' || true", out => {
    if (out.includes("[MUTED]")) return "Muted"
    const v = out.split(" ")[1]
    return v ? `${Math.round(parseFloat(v) * 100)}%` : "50%"
  })

  const micVal = createPoll("50%", 1500, "sh -c 'wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null' || true", out => {
    if (out.includes("[MUTED]")) return "Muted"
    const v = out.split(" ")[1]
    return v ? `${Math.round(parseFloat(v) * 100)}%` : "50%"
  })

  const brightVal = createPoll("100%", 3000, "sh -c 'brightnessctl -m 2>/dev/null' || true", out => {
    const parts = out.split(",")
    return parts[3] || "100%"
  })

  const volAdj = new Gtk.Adjustment({ value: 50, lower: 0, upper: 100, stepIncrement: 1, pageIncrement: 10 })
  const micAdj = new Gtk.Adjustment({ value: 50, lower: 0, upper: 100, stepIncrement: 1, pageIncrement: 10 })
  const brightAdj = new Gtk.Adjustment({ value: 100, lower: 5, upper: 100, stepIncrement: 1, pageIncrement: 10 })

  let isUpdatingUI = false

  volAdj.connect("value-changed", adj => {
    if (isUpdatingUI) return
    exec(`wpctl set-volume @DEFAULT_AUDIO_SINK@ ${(adj.value / 100).toFixed(2)}`)
  })

  micAdj.connect("value-changed", adj => {
    if (isUpdatingUI) return
    exec(`wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${(adj.value / 100).toFixed(2)}`)
  })

  brightAdj.connect("value-changed", adj => {
    if (isUpdatingUI) return
    exec(`brightnessctl set ${Math.round(adj.value)}%`)
  })

  const volScale = new Gtk.Scale({ orientation: Gtk.Orientation.HORIZONTAL, adjustment: volAdj, drawValue: false, hexpand: true })
  const micScale = new Gtk.Scale({ orientation: Gtk.Orientation.HORIZONTAL, adjustment: micAdj, drawValue: false, hexpand: true })
  const brightScale = new Gtk.Scale({ orientation: Gtk.Orientation.HORIZONTAL, adjustment: brightAdj, drawValue: false, hexpand: true })

  const popover = new Gtk.Popover({ autohide: true, position: Gtk.PositionType.BOTTOM })

  const content = (
    <box cssClasses={["control-center"]} orientation={Gtk.Orientation.VERTICAL} spacing={12}>
      <box spacing={8} homogeneous={true}>
        <button
          cssClasses={wifiState(ssid => ["qs-toggle", ssid !== "Offline" ? "active" : ""])}
          onClicked={() => exec("sh -c 'nmcli radio wifi $(nmcli radio wifi | grep -q enabled && echo off || echo on)'")}>
          <label label={wifiState(ssid => (ssid !== "Offline" ? `󰤨 ${ssid}` : "󰤭 Wi-Fi Off"))} />
        </button>

        <button
          cssClasses={btState(st => ["qs-toggle", st !== "off" ? "active" : ""])}
          onClicked={() =>
            exec("sh -c 'bluetoothctl show | grep -q \"Powered: yes\" && bluetoothctl power off || bluetoothctl power on'")
          }>
          <label label={btState(st => (st !== "off" ? "󰂯 Bluetooth On" : "󰂲 Bluetooth Off"))} />
        </button>
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} cssClasses={["qs-card"]}>
        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")}>
            <label label={volVal(v => (v === "Muted" ? "󰝟" : "󰕾"))} />
          </button>
          {volScale as unknown as Gtk.Widget}
        </box>

        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")}>
            <label label={micVal(v => (v === "Muted" ? "󰍭" : "󰍬"))} />
          </button>
          {micScale as unknown as Gtk.Widget}
        </box>

        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("brightnessctl set 50%")}>
            <label label="󰃠" />
          </button>
          {brightScale as unknown as Gtk.Widget}
        </box>
      </box>

      <box spacing={8} homogeneous={true}>
        <button cssClasses={["qs-action-btn"]} onClicked={() => exec("grimblast copy area")}>
          <label label="󰄄 Скриншот" />
        </button>
        <button cssClasses={["qs-action-btn"]} onClicked={() => exec("pavucontrol")}>
          <label label="󰕾 Микшер" />
        </button>
      </box>
    </box>
  )

  popover.set_child(content as unknown as Gtk.Widget)

  const wifiDisplay = wifiState(ssid => (ssid !== "Offline" ? `󰤨 ${ssid}` : "󰤭 Offline"))
  const btDisplay = btState(st => (st !== "off" ? "󰂯" : "󰂲"))
  const volDisplay = volVal(v => (v === "Muted" ? "󰝟 Mute" : `󰕾 ${v}`))

  return (
    <button
      cssClasses={["control-center-btn"]}
      onClicked={self => {
        isUpdatingUI = true

        const currentVol = volVal.get()
        const currentMic = micVal.get()
        const currentBright = brightVal.get()

        const vNum = currentVol === "Muted" ? 0 : parseFloat(currentVol)
        const mNum = currentMic === "Muted" ? 0 : parseFloat(currentMic)
        const bNum = parseFloat(currentBright)

        volAdj.set_value(isNaN(vNum) ? 50 : vNum)
        micAdj.set_value(isNaN(mNum) ? 0 : mNum)
        brightAdj.set_value(isNaN(bNum) ? 100 : bNum)

        isUpdatingUI = false

        if (popover.get_parent()) popover.unparent()
        popover.set_parent(self)
        popover.popup()
      }}>
      <box spacing={10}>
        <label label={wifiDisplay} />
        <label label={btDisplay} />
        <label label={volDisplay} />
        <label label={brightVal(b => `󰃠 ${b}`)} />
      </box>
    </button>
  )
}

function Workspaces() {
  const activeWs = createPoll(1, 200, "sh -c 'hyprctl activeworkspace -j 2>/dev/null' || echo '{}'", out => {
    try {
      const parsed = JSON.parse(out)
      return parsed.id || 1
    } catch {
      return 1
    }
  })

  const kanjiMap: Record<number, string> = {
    1: "一",
    2: "二",
    3: "三",
    4: "四",
    5: "五",
    6: "六",
    7: "七",
    8: "八",
    9: "九",
    10: "十",
  }

  const workspaces = [1, 2, 3, 4, 5]

  return (
    <box cssClasses={["workspaces"]} spacing={4}>
      {workspaces.map(id => (
        <button
          cssClasses={activeWs(active => ["workspace-btn", active === id ? "active" : ""])}
          onClicked={() => exec(`hyprctl dispatch workspace ${id}`)}>
          <label label={kanjiMap[id] || `${id}`} />
        </button>
      ))}
    </box>
  )
}

const TEMP_COVER_PATH = "/tmp/maybar_mpris_cover.png"

function Media() {
  const mpris = Mpris.get_default()

  const coverPicture = new Gtk.Picture({
    cssClasses: ["media-cover"],
    contentFit: Gtk.ContentFit.COVER,
    widthRequest: 24,
    heightRequest: 24,
    visible: false,
  })

  const popupCover = new Gtk.Picture({
    cssClasses: ["media-popup-cover"],
    contentFit: Gtk.ContentFit.COVER,
    widthRequest: 100,
    heightRequest: 100,
    visible: false,
  })

  const titleLabel = new Gtk.Label({ cssClasses: ["media-text"], label: "Нет музыки" })
  const statusIcon = new Gtk.Label({ cssClasses: ["media-icon"], label: "󰐊" })
  const popTitle = new Gtk.Label({ cssClasses: ["media-popup-title"], wrap: true, maxWidthChars: 22, xalign: 0, label: "Нет музыки" })
  const popArtist = new Gtk.Label({ cssClasses: ["media-popup-artist"], wrap: true, maxWidthChars: 22, xalign: 0, label: "" })

  const mainBox = new Gtk.Box({ cssClasses: ["media"], spacing: 6, valign: Gtk.Align.CENTER })

  let currentLoadedPath = ""
  let lastCoverUrl = ""
  let checkTimeoutId: number | null = null

  const updateTexture = (path: string) => {
    if (currentLoadedPath === path && path !== TEMP_COVER_PATH) return
    currentLoadedPath = path

    if (!path || !GLib.file_test(path, GLib.FileTest.EXISTS)) {
      coverPicture.set_paintable(null)
      coverPicture.set_visible(false)
      popupCover.set_paintable(null)
      popupCover.set_visible(false)
      return
    }

    try {
      const file = Gio.File.new_for_path(path)
      const texture = Gdk.Texture.new_for_file(file)
      coverPicture.set_paintable(texture)
      coverPicture.set_visible(true)
      popupCover.set_paintable(texture)
      popupCover.set_visible(true)
    } catch (err) {
      console.error(`Ошибка загрузки обложки: ${err}`)
      coverPicture.set_paintable(null)
      coverPicture.set_visible(false)
      popupCover.set_paintable(null)
      popupCover.set_visible(false)
    }
  }

  const popover = new Gtk.Popover({ autohide: true, position: Gtk.PositionType.BOTTOM })

  const popoverContent = (
    <box cssClasses={["media-popup"]} orientation={Gtk.Orientation.VERTICAL} spacing={12}>
      <box spacing={12} valign={Gtk.Align.CENTER}>
        {popupCover as unknown as Gtk.Widget}
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4} valign={Gtk.Align.CENTER}>
          {popTitle as unknown as Gtk.Widget}
          {popArtist as unknown as Gtk.Widget}
        </box>
      </box>
      <box cssClasses={["media-popup-controls"]} spacing={8} halign={Gtk.Align.CENTER}>
        <button
          cssClasses={["media-ctrl-btn"]}
          tooltipText="Предыдущий трек"
          onClicked={() => {
            const player = mpris.get_players()[0]
            if (player) player.previous()
          }}>
          <label label="󰒮" />
        </button>
        <button
          cssClasses={["media-ctrl-btn"]}
          tooltipText="Воспроизведение / Пауза"
          onClicked={() => {
            const player = mpris.get_players()[0]
            if (player) player.play_pause()
          }}>
          <label label="󰐊" />
        </button>
        <button
          cssClasses={["media-ctrl-btn"]}
          tooltipText="Следующий трек"
          onClicked={() => {
            const player = mpris.get_players()[0]
            if (player) player.next()
          }}>
          <label label="󰒭" />
        </button>
      </box>
    </box>
  )

  popover.set_child(popoverContent as unknown as Gtk.Widget)

  const syncPlayerState = () => {
    const players = mpris.get_players()
    if (!players || players.length === 0) {
      mainBox.remove_css_class("playing")
      mainBox.add_css_class("paused")
      titleLabel.set_label("Нет музыки")
      popTitle.set_label("Нет музыки")
      popArtist.set_label("")
      statusIcon.set_label("󰐊")
      updateTexture("")
      return
    }

    const player = players.find(p => p.playbackStatus === Mpris.PlaybackStatus.PLAYING) || players[0]
    const title = player.title || "Неизвестный трек"
    const artist = player.artist || ""
    const isPlaying = player.playbackStatus === Mpris.PlaybackStatus.PLAYING

    if (isPlaying) {
      mainBox.add_css_class("playing")
      mainBox.remove_css_class("paused")
      statusIcon.set_label("󰏤")
    } else {
      mainBox.add_css_class("paused")
      mainBox.remove_css_class("playing")
      statusIcon.set_label("󰐊")
    }

    const fullTitle = artist ? `${artist} — ${title}` : title
    const shortTitle = fullTitle.length > 22 ? `${fullTitle.slice(0, 22)}...` : fullTitle
    titleLabel.set_label(shortTitle)

    popTitle.set_label(title)
    popArtist.set_label(artist)

    const rawCover = player.coverArt || ""
    if (rawCover) {
      const resolved = resolveCoverPath(rawCover)

      if (resolved.startsWith("http://") || resolved.startsWith("https://")) {
        if (resolved !== lastCoverUrl) {
          lastCoverUrl = resolved
          if (checkTimeoutId) {
            GLib.source_remove(checkTimeoutId)
            checkTimeoutId = null
          }
          GLib.spawn_command_line_async(
            `sh -c 'curl -sL "${resolved}" -o ${TEMP_COVER_PATH} && touch ${TEMP_COVER_PATH}.ready'`
          )
        }

        let checks = 0
        checkTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
          if (GLib.file_test(`${TEMP_COVER_PATH}.ready`, GLib.FileTest.EXISTS)) {
            GLib.unlink(`${TEMP_COVER_PATH}.ready`)
            updateTexture(TEMP_COVER_PATH)
            checkTimeoutId = null
            return GLib.SOURCE_REMOVE
          }
          checks++
          if (checks > 15) {
            checkTimeoutId = null
            return GLib.SOURCE_REMOVE
          }
          return GLib.SOURCE_CONTINUE
        })
      } else {
        updateTexture(resolved)
      }
    } else {
      updateTexture("")
    }
  }

  mpris.connect("player-added", (_, player) => {
    player.connect("notify::cover-art", syncPlayerState)
    player.connect("notify::title", syncPlayerState)
    syncPlayerState()
  })

  mpris.connect("player-closed", syncPlayerState)

  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
    syncPlayerState()
    return GLib.SOURCE_CONTINUE
  })

  return (
    <box cssClasses={["media-container"]} valign={Gtk.Align.CENTER}>
      <button
        cssClasses={["media-main-btn"]}
        onClicked={self => {
          if (popover.get_parent()) popover.unparent()
          popover.set_parent(self)
          popover.popup()
        }}>
        <box spacing={6} valign={Gtk.Align.CENTER}>
          {coverPicture as unknown as Gtk.Widget}
          {statusIcon as unknown as Gtk.Widget}
          {titleLabel as unknown as Gtk.Widget}
        </box>
      </button>
    </box>
  )
}

function Clipboard() {
  return (
    <button
      cssClasses={["clipboard-btn"]}
      tooltipText="История буфера"
      onClicked={() => exec("sh -c 'cliphist list | rofi -dmenu -theme ~/.config/rofi/config.rasi | cliphist decode | wl-copy'")}>
      <label label="󰅍" />
    </button>
  )
}

function Weather() {
  const weather = createPoll("󰖐 ...", 900000, "sh -c 'curl -s --max-time 3 \"wttr.in?format=%t\" 2>/dev/null' || true", out => {
    const temp = out.trim()
    return temp && !temp.includes("HTML") && !temp.includes("404") ? `󰖐 ${temp}` : "󰖐 N/A"
  })

  return (
    <button cssClasses={["weather-btn"]} onClicked={() => exec("notify-send 'Weather' 'Обновление данных погоды...'")}>
      <label cssClasses={["weather"]} label={weather} />
    </button>
  )
}

function NotificationCenter() {
  return (
    <button cssClasses={["notification-btn"]} tooltipText="Центр уведомлений" onClicked={() => exec("swaync-client -t -sw")}>
      <label label="󰂚" />
    </button>
  )
}

function Clock() {
  const clock = createPoll("", 1000, "date '+%H:%M:%S | %a, %d %b'")

  const popover = new Gtk.Popover({ autohide: true, position: Gtk.PositionType.BOTTOM })
  const calendar = new Gtk.Calendar()
  popover.set_child(calendar)

  return (
    <button
      cssClasses={["clock-btn"]}
      onClicked={self => {
        if (popover.get_parent()) popover.unparent()
        popover.set_parent(self)
        popover.popup()
      }}>
      <label cssClasses={["clock"]} label={clock} />
    </button>
  )
}

function Language() {
  const lang = createPoll("󰌌 EN", 500, "sh -c 'hyprctl devices -j 2>/dev/null' || true", out => {
    try {
      const parsed = JSON.parse(out)
      if (!parsed?.keyboards) return "󰌌 EN"
      const mainKeyboards = parsed.keyboards.filter((k: any) => k.main === true)
      const kb = mainKeyboards[0] || parsed.keyboards[0]
      const keymap = kb?.active_keymap || ""
      if (keymap.includes("Russian")) return "󰌌 RU"
      if (keymap.includes("English")) return "󰌌 EN"
      return `󰌌 ${keymap.slice(0, 2).toUpperCase()}`
    } catch {
      return "󰌌 EN"
    }
  })

  return (
    <button cssClasses={["language"]} onClicked={() => exec("hyprctl switchxkblayout main next")}>
      <label label={lang} />
    </button>
  )
}

function PowerMenu() {
  const popover = new Gtk.Popover({ autohide: true, position: Gtk.PositionType.BOTTOM })
  const popoverContent = (
    <box cssClasses={["power-popup"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <button cssClasses={["power-item"]} onClicked={() => exec("systemctl poweroff")}>
        <label label="󰐥 Выключить" />
      </button>
      <button cssClasses={["power-item"]} onClicked={() => exec("systemctl reboot")}>
        <label label="󰜉 Перезагрузить" />
      </button>
      <button cssClasses={["power-item"]} onClicked={() => exec("hyprctl dispatch exit")}>
        <label label="󰿅 Выйти" />
      </button>
    </box>
  )

  popover.set_child(popoverContent as unknown as Gtk.Widget)

  return (
    <button
      cssClasses={["power-btn"]}
      onClicked={self => {
        if (popover.get_parent()) popover.unparent()
        popover.set_parent(self)
        popover.popup()
      }}>
      <label label="󰐥" />
    </button>
  )
}

app.start({
  css: "./style.css",
  main() {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

    const bat = createPoll(
      "󰂄 100%",
      5000,
      "sh -c 'cat /sys/class/power_supply/BAT0/capacity 2>/dev/null; echo \";\"; cat /sys/class/power_supply/BAT0/status 2>/dev/null' || echo '100;Discharging'",
      out => {
        const parts = out.split(";").map(s => s.trim())
        const cap = parts[0] || "100"
        const status = parts[1] || "Discharging"

        const isCharging = status === "Charging"
        const val = parseInt(cap) || 100
        let icon = "󰁹"
        if (isCharging) icon = "󰂄"
        else if (val < 20) icon = "󰂎"
        else if (val < 50) icon = "󰁽"
        else if (val < 80) icon = "󰂀"

        return `${icon} ${val}%`
      }
    )

    return (
      <window
        name="maybar"
        namespace="maybar"
        visible={true}
        layer={Astal.Layer.TOP}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={TOP | LEFT | RIGHT}>
        <centerbox cssClasses={["bar-inner"]} hexpand>
          <box $type="start" halign={Gtk.Align.START} spacing={8}>
            <Workspaces />
            <Media />
          </box>

          <box $type="center" spacing={12}>
            <box cssClasses={["datetime-group"]}>
              <Clock />
              <Weather />
            </box>
          </box>

          <box $type="end" halign={Gtk.Align.END} spacing={8}>
            <box cssClasses={["sys-group"]}>
              <CpuMonitor />
              <RamMonitor />
            </box>

            <box cssClasses={["status-group"]}>
              <Language />
              <Clipboard />
              <NotificationCenter />
            </box>

            <button cssClasses={["battery"]}>
              <label label={bat} />
            </button>

            <QuickSettingsPopover />
            <PowerMenu />
          </box>
        </centerbox>
      </window>
    )
  },
})
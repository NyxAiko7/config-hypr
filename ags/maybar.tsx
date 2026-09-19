import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"
import Mpris from "gi://AstalMpris"
import GLib from "gi://GLib"

const exec = (cmd: string) => {
  try {
    GLib.spawn_command_line_async(cmd)
  } catch (err) {
    console.error(`Exec error: ${err}`)
  }
}

function QuickSettingsPopover() {
  const wifiState = createPoll("Offline", 4000, "sh -c \"nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2\" || echo 'Offline'", out => {
    const ssid = out.trim()
    return (ssid && ssid !== "" && ssid !== "--") ? ssid : "Offline"
  })

  const btState = createPoll(false, 4000, "sh -c 'bluetoothctl show 2>/dev/null | grep \"Powered: yes\"' || true", out => out.trim().length > 5)

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

  let isUpdating = false

  volAdj.connect("value-changed", (adj) => {
    if (isUpdating) return
    exec(`wpctl set-volume @DEFAULT_AUDIO_SINK@ ${adj.value / 100}`)
  })

  micAdj.connect("value-changed", (adj) => {
    if (isUpdating) return
    exec(`wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${adj.value / 100}`)
  })

  brightAdj.connect("value-changed", (adj) => {
    if (isUpdating) return
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
          <label label={wifiState(ssid => ssid !== "Offline" ? `󰤨  ${ssid}` : "󰤭  Wi-Fi Off")} />
        </button>

        <button
          cssClasses={btState(on => ["qs-toggle", on ? "active" : ""])}
          onClicked={() => exec("sh -c 'bluetoothctl show | grep -q \"Powered: yes\" && bluetoothctl power off || bluetoothctl power on'")}>
          <label label={btState(on => on ? "󰂯  Bluetooth On" : "󰂲  Bluetooth Off")} />
        </button>
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} cssClasses={["qs-card"]}>
        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")}>
            <label label={volVal(v => v === "Muted" ? "󰝟" : "󰕾")} />
          </button>
          {volScale}
        </box>

        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")}>
            <label label={micVal(v => v === "Muted" ? "󰍭" : "󰍬")} />
          </button>
          {micScale}
        </box>

        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("brightnessctl set 50%")}>
            <label label="󰃠" />
          </button>
          {brightScale}
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

  const wifiDisplay = wifiState(ssid => ssid !== "Offline" ? `󰤨 ${ssid}` : "󰤭 Offline")
  const volDisplay = volVal(v => v === "Muted" ? "󰝟 Mute" : `󰕾 ${v}`)

  return (
    <button
      cssClasses={["control-center-btn"]}
      onClicked={(self) => {
        isUpdating = true

        const currentVol = volVal.get()
        const currentMic = micVal.get()
        const currentBright = brightVal.get()

        const vNum = currentVol === "Muted" ? 0 : parseFloat(currentVol)
        const mNum = currentMic === "Muted" ? 0 : parseFloat(currentMic)
        const bNum = parseFloat(currentBright)

        volAdj.set_value(isNaN(vNum) ? 50 : vNum)
        micAdj.set_value(isNaN(mNum) ? 50 : mNum)
        brightAdj.set_value(isNaN(bNum) ? 100 : bNum)

        isUpdating = false

        if (popover.get_parent()) popover.unparent()
        popover.set_parent(self)
        popover.popup()
      }}>
      <box spacing={10}>
        <label label={wifiDisplay} />
        <label label={volDisplay} />
        <label label={brightVal(b => `󰃠 ${b}`)} />
      </box>
    </button>
  )
}

function Workspaces() {
  const activeWs = createPoll(1, 300, "sh -c 'hyprctl activeworkspace -j 2>/dev/null | grep -oP \"(?<=\\\"id\\\": )\\\\d+\"' || echo 1", out => {
    return parseInt(out.trim()) || 1
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

  let currentLoadedPath = ""
  let lastCoverUrl = ""

  const updateTexture = (path: string) => {
    if (currentLoadedPath === path) return
    currentLoadedPath = path

    if (!path || !GLib.file_test(path, GLib.FileTest.EXISTS)) {
      coverPicture.set_paintable(null)
      coverPicture.set_visible(false)
      return
    }

    try {
      const file = GLib.File.new_for_path(path)
      const texture = Gdk.Texture.new_for_file(file)
      coverPicture.set_paintable(texture)
      coverPicture.set_visible(true)
    } catch (err) {
      console.error("Failed to load cover texture:", err)
      coverPicture.set_paintable(null)
      coverPicture.set_visible(false)
    }
  }

  const mediaInfo = createPoll(
    { title: "Нет музыки", cover: "", isPlaying: false, hasPlayer: false },
    1000,
    () => {
      const players = mpris.get_players()
      if (!players || players.length === 0) {
        return { title: "Нет музыки", cover: "", isPlaying: false, hasPlayer: false }
      }

      const player = players.find(p => p.playbackStatus === Mpris.PlaybackStatus.PLAYING) || players[0]
      const title = player?.title || "Неизвестный трек"
      const artist = player?.artist ? `${player.artist} — ` : ""
      const fullTitle = `${artist}${title}`
      const formatted = fullTitle.length > 22 ? `${fullTitle.slice(0, 22)}...` : fullTitle

      let rawCover = player?.coverArt || ""

      if (rawCover) {
        let unescaped = GLib.uri_unescape_string(rawCover, null) || rawCover

        if (unescaped.startsWith("file://")) {
          rawCover = unescaped.replace(/^file:\/\//, "")
        } else if (unescaped.startsWith("http://") || unescaped.startsWith("https://")) {
          if (unescaped !== lastCoverUrl) {
            lastCoverUrl = unescaped
            GLib.spawn_command_line_async(`sh -c 'curl -s "${unescaped}" -o ${TEMP_COVER_PATH}'`)
          }
          rawCover = TEMP_COVER_PATH
        } else {
          rawCover = unescaped
        }
      }

      return {
        title: formatted,
        cover: rawCover.trim(),
        isPlaying: player?.playbackStatus === Mpris.PlaybackStatus.PLAYING,
        hasPlayer: true,
      }
    }
  )

  mediaInfo(m => {
    updateTexture(m.cover)
  })

  return (
    <box cssClasses={mediaInfo(m => ["media", m.isPlaying ? "playing" : "paused"])} spacing={6} valign={Gtk.Align.CENTER}>
      {coverPicture as unknown as Gtk.Widget}

      <button
        cssClasses={["media-title-btn"]}
        onClicked={() => {
          const players = mpris.get_players()
          if (players && players[0]) players[0].play_pause()
        }}>
        <box spacing={6} valign={Gtk.Align.CENTER}>
          <label
            cssClasses={["media-icon"]}
            label={mediaInfo(m => m.isPlaying ? "󰏤" : "󰐊")}
          />
          <label
            cssClasses={["media-text"]}
            label={mediaInfo(m => m.title)}
          />
        </box>
      </button>

      <box cssClasses={["media-controls"]} spacing={2}>
        <button
          cssClasses={["media-ctrl-btn"]}
          tooltipText="Предыдущий трек"
          onClicked={() => {
            const players = mpris.get_players()
            if (players && players[0]) players[0].previous()
          }}>
          <label label="󰒮" />
        </button>

        <button
          cssClasses={["media-ctrl-btn"]}
          tooltipText="Следующий трек"
          onClicked={() => {
            const players = mpris.get_players()
            if (players && players[0]) players[0].next()
          }}>
          <label label="󰒭" />
        </button>
      </box>
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
    <button
      cssClasses={["notification-btn"]}
      tooltipText="Центр уведомлений"
      onClicked={() => exec("swaync-client -t -sw")}>
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
      onClicked={(self) => {
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
      onClicked={(self) => {
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

    const bat = createPoll("󰂄 100%", 5000, "sh -c 'cat /sys/class/power_supply/BAT0/capacity 2>/dev/null; echo \";\"; cat /sys/class/power_supply/BAT0/status 2>/dev/null' || echo '100;Discharging'", out => {
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
    })

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
            <Clipboard />
            <Media />
          </box>
          <box $type="center" spacing={12}>
            <Weather />
            <Clock />
          </box>
          <box $type="end" halign={Gtk.Align.END} spacing={8}>
            <Language />
            <label cssClasses={["battery"]} label={bat} />
            <QuickSettingsPopover />
            <NotificationCenter />
            <PowerMenu />
          </box>
        </centerbox>
      </window>
    )
  },
})
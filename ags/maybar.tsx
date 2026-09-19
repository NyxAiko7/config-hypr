import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"

const exec = (cmd: string) => {
  try {
    GLib.spawn_command_line_async(cmd)
  } catch (err) {
    console.error(`Exec error: ${err}`)
  }
}

const execSync = (cmd: string) => {
  try {
    const [_, stdout] = GLib.spawn_command_line_sync(cmd)
    return new TextDecoder().decode(stdout).trim()
  } catch {
    return ""
  }
}

/* ================= CONTROL CENTER ================= */
function QuickSettingsPopover() {
  const wifiState = createPoll("Disconnected", 3000, "sh -c \"nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2\" || echo 'Offline'", out => {
    const ssid = out.trim()
    return (ssid && ssid !== "" && ssid !== "--") ? ssid : "Offline"
  })

  const btState = createPoll(false, 3000, "sh -c 'bluetoothctl show 2>/dev/null | grep \"Powered: yes\"' || true", out => out.trim().length > 5)

  
  const mediaTrack = createPoll("Нет музыки", 2000, "sh -c 'playerctl metadata --format \"{{artist}} - {{title}}\" 2>/dev/null' || true", out => {
    const track = out.trim()
    if (!track || track.includes("--")) return "Нет музыки"
    return track.length > 30 ? `${track.slice(0, 30)}...` : track
  })

  const getVol = () => {
    const out = execSync("wpctl get-volume @DEFAULT_AUDIO_SINK@")
    const v = out.split(" ")[1]
    return v ? parseFloat(v) * 100 : 50
  }

  const getMic = () => {
    const out = execSync("wpctl get-volume @DEFAULT_AUDIO_SOURCE@")
    const v = out.split(" ")[1]
    return v ? parseFloat(v) * 100 : 50
  }

  const getBright = () => {
    const out = execSync("brightnessctl -m")
    const parts = out.split(",")
    return parseFloat(parts[3] || "100")
  }

  const volAdj = new Gtk.Adjustment({ value: getVol(), lower: 0, upper: 100, stepIncrement: 1 })
  const micAdj = new Gtk.Adjustment({ value: getMic(), lower: 0, upper: 100, stepIncrement: 1 })
  const brightAdj = new Gtk.Adjustment({ value: getBright(), lower: 5, upper: 100, stepIncrement: 1 })

  volAdj.connect("value-changed", ({ value }) => {
    exec(`wpctl set-volume @DEFAULT_AUDIO_SINK@ ${value / 100}`)
  })

  micAdj.connect("value-changed", ({ value }) => {
    exec(`wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${value / 100}`)
  })

  brightAdj.connect("value-changed", ({ value }) => {
    exec(`brightnessctl set ${Math.round(value)}%`)
  })

  const volScale = new Gtk.Scale({ orientation: Gtk.Orientation.HORIZONTAL, adjustment: volAdj, drawValue: false })
  const micScale = new Gtk.Scale({ orientation: Gtk.Orientation.HORIZONTAL, adjustment: micAdj, drawValue: false })
  const brightScale = new Gtk.Scale({ orientation: Gtk.Orientation.HORIZONTAL, adjustment: brightAdj, drawValue: false })

  const volVal = createPoll("🔊 50%", 2000, "sh -c 'wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null' || true", out => {
    if (out.includes("[MUTED]")) return "🔇 Mute"
    const v = out.split(" ")[1]
    return `🔊 ${v ? Math.round(parseFloat(v) * 100) : 50}%`
  })

  const brightVal = createPoll("☀️ 100%", 3000, "sh -c 'brightnessctl -m 2>/dev/null' || true", out => {
    const parts = out.split(",")
    return `☀️ ${parts[3] || "100"}%`
  })

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
          <label label={btState(on => on ? "󰂯  BT On" : "󰂲  BT Off")} />
        </button>
      </box>

      {/* Блок управления медиаплеером */}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={6} cssClasses={["qs-sliders"]}>
        <label label={mediaTrack} cssClasses={["media-popup-title"]} xalign={0} />
        <box spacing={6} homogeneous={true}>
          <button cssClasses={["qs-action-btn"]} onClicked={() => exec("playerctl previous")}>
            <label label="󰒮 Назад" />
          </button>
          <button cssClasses={["qs-action-btn"]} onClicked={() => exec("playerctl play-pause")}>
            <label label="󰐎 Пауза" />
          </button>
          <button cssClasses={["qs-action-btn"]} onClicked={() => exec("playerctl next")}>
            <label label="󰒭 Вперед" />
          </button>
        </box>
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} spacing={8} cssClasses={["qs-sliders"]}>
        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")}>
            <label label="🔊" />
          </button>
          <box hexpand={true}>{volScale}</box>
        </box>

        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")}>
            <label label="🎙️" />
          </button>
          <box hexpand={true}>{micScale}</box>
        </box>

        <box spacing={8}>
          <button cssClasses={["qs-icon-btn"]} onClicked={() => exec("brightnessctl set 50%")}>
            <label label="☀️" />
          </button>
          <box hexpand={true}>{brightScale}</box>
        </box>
      </box>

      <box spacing={8} homogeneous={true}>
        <button cssClasses={["qs-action-btn"]} onClicked={() => exec("grimblast copy area")}>
          <label label="📸 Скриншот" />
        </button>
        <button cssClasses={["qs-action-btn"]} onClicked={() => exec("pavucontrol")}>
          <label label="⚙️ Микшер" />
        </button>
      </box>
    </box>
  )

  popover.set_child(content as unknown as Gtk.Widget)

  const wifiDisplay = wifiState(ssid => ssid !== "Offline" ? `󰤨 ${ssid}` : "󰤭 Offline")

  return (
    <button
      cssClasses={["control-center-btn"]}
      onClicked={(self) => {
        volAdj.set_value(getVol())
        micAdj.set_value(getMic())
        brightAdj.set_value(getBright())
        if (popover.get_parent()) {
          popover.unparent()
        }
        popover.set_parent(self)
        popover.popup()
      }}>
      <box spacing={10}>
        <label label={wifiDisplay} />
        <label label={volVal} />
        <label label={brightVal} />
      </box>
    </button>
  )
}

/* ================= ДРУГИЕ ВИДЖЕТЫ ================= */
function Clipboard() {
  return (
    <button
      cssClasses={["clipboard-btn"]}
      tooltipText="История буфера"
      onClicked={() => exec("sh -c 'cliphist list | rofi -dmenu | cliphist decode | wl-copy'")}>
      <label label="📋" />
    </button>
  )
}

function Media() {
  const media = createPoll("", 2000, "sh -c 'playerctl metadata --format \"{{artist}} - {{title}}\" 2>/dev/null' || true", out => {
    const track = out.trim()
    if (!track) return "🎵 Нет музыки"
    return track.length > 25 ? `🎵 ${track.slice(0, 25)}...` : `🎵 ${track}`
  })

  return (
    <button cssClasses={["media"]} onClicked={() => exec("playerctl play-pause")}>
      <label label={media} />
    </button>
  )
}


function Workspaces() {
  const activeWs = createPoll(1, 200, "sh -c 'hyprctl activeworkspace -j 2>/dev/null' || true", out => {
    try { return JSON.parse(out).id || 1 } catch { return 1 }
  })

  return (
    <box cssClasses={["workspaces"]} spacing={2}>
      {[1, 2, 3, 4, 5].map(id => (
        <button
          cssClasses={activeWs(active => active === id ? ["workspace-btn", "active"] : ["workspace-btn"])}
          onClicked={() => exec(`hyprctl dispatch workspace ${id}`)}>
          <label label={String(id)} />
        </button>
      ))}
    </box>
  )
}

function Weather() {
  const weather = createPoll("🌡️ ...", 900000, "sh -c 'curl -s --max-time 3 \"wttr.in?format=%t\" 2>/dev/null' || true", out => {
    const temp = out.trim()
    return temp && !temp.includes("HTML") && !temp.includes("404") ? `🌡️ ${temp}` : "🌡️ N/A"
  })

  return (
    <button cssClasses={["weather-btn"]} onClicked={() => exec("notify-send 'Weather' 'Обновление погоды...'")}>
      <label cssClasses={["weather"]} label={weather} />
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
        if (popover.get_parent()) {
          popover.unparent()
        }
        popover.set_parent(self)
        popover.popup()
      }}>
      <label label="󰐥" />
    </button>
  )
}

function Clock() {
  const clock = createPoll("", 1000, "date '+%H:%M:%S | %a, %d %b'")
  return (
    <button cssClasses={["clock-btn"]} onClicked={() => exec("swaync-client -t -sw")}>
      <label cssClasses={["clock"]} label={clock} />
    </button>
  )
}

function Language() {
  const lang = createPoll("🌐 EN", 500, "sh -c 'hyprctl devices -j 2>/dev/null' || true", out => {
    try {
      const parsed = JSON.parse(out)
      const mainKeyboards = parsed.keyboards.filter((k: any) => k.main === true)
      const kb = mainKeyboards[0] || parsed.keyboards[0]
      const keymap = kb?.active_keymap || ""
      if (keymap.includes("Russian")) return "🌐 RU"
      if (keymap.includes("English")) return "🌐 EN"
      return `🌐 ${keymap.slice(0, 2).toUpperCase()}`
    } catch {
      return "🌐 EN"
    }
  })

  return (
    <button cssClasses={["language"]} onClicked={() => exec("hyprctl switchxkblayout main next")}>
      <label label={lang} />
    </button>
  )
}

app.start({
  css: "./style.css",
  main() {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
    const bat = createPoll("🔋 100%", 5000, "sh -c 'cat /sys/class/power_supply/BAT0/capacity 2>/dev/null' || echo '100'", out => `🔋 ${out.trim()}%`)

    return (
      <window
        name="maybar"
        namespace="maybar"
        visible={true}
        layer={Astal.Layer.TOP}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={TOP | LEFT | RIGHT}>
        <centerbox cssClasses={["bar-inner"]} hexpand>
          <box $type="start" halign={Gtk.Align.START} spacing={12}>
            <Workspaces />
            <Clipboard />
            <Media />
          </box>
          <box $type="center" spacing={16}>
            <Weather />
            <Clock />
          </box>
          <box $type="end" halign={Gtk.Align.END} spacing={12}>
            <Language />
            <label cssClasses={["battery"]} label={bat} />
            <QuickSettingsPopover />
            <PowerMenu />
          </box>
        </centerbox>
      </window>
    )
  },
})
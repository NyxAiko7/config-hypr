#!/usr/bin/env python3
# Парсер биндов Hyprland из Lua-конфига (hyprland.lua) -> JSON для HelpPopup.
import sys, re, json

path = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    src = open(path, encoding="utf-8").read()
except Exception:
    print("[]")
    sys.exit(0)

m = re.search(r'local\s+mainMod\s*=\s*"([^"]+)"', src)
MAIN = m.group(1) if m else "SUPER"

# локальные переменные вида local terminal = "alacritty"
LOCALS = dict(re.findall(r'local\s+(\w+)\s*=\s*"([^"]*)"', src))

def split_top(s):
    parts, buf, depth, instr, esc = [], [], 0, None, False
    for c in s:
        if instr:
            buf.append(c)
            if esc: esc = False
            elif c == "\\": esc = True
            elif c == instr: instr = None
            continue
        if c in '"\'':
            instr = c; buf.append(c)
        elif c in "([{":
            depth += 1; buf.append(c)
        elif c in ")]}":
            depth -= 1; buf.append(c)
        elif c == "," and depth == 0:
            parts.append("".join(buf).strip()); buf = []
        else:
            buf.append(c)
    if "".join(buf).strip():
        parts.append("".join(buf).strip())
    return parts

def find_calls(s, name):
    out, i = [], 0
    while True:
        j = s.find(name + "(", i)
        if j < 0: break
        k = j + len(name) + 1
        depth, instr, esc = 1, None, False
        while k < len(s) and depth > 0:
            c = s[k]
            if instr:
                if esc: esc = False
                elif c == "\\": esc = True
                elif c == instr: instr = None
            else:
                if c in '"\'':
                    instr = c
                elif c == "(": depth += 1
                elif c == ")": depth -= 1
            k += 1
        out.append(s[j + len(name) + 1:k - 1])
        i = k
    return out

def unq(x):
    x = x.strip()
    if len(x) >= 2 and x[0] in '"\'' and x[-1] == x[0]:
        return x[1:-1]
    return x

def keys_of(expr):
    e = expr.strip()
    e = e.replace("mainMod", '"%s"' % MAIN)
    def repl(mm):
        return '"%s"' % (mm.group(1) + mm.group(2))
    for _ in range(6):
        e = re.sub(r'"([^"]*)"\s*\.\.\s*"([^"]*)"', repl, e)
    parts = re.findall(r'"([^"]*)"', e)
    s = "".join(parts).strip()
    s = re.sub(r"\s*\+\s*", " + ", s).strip(" +")
    s = s.replace("mouse:272", "ЛКМ").replace("mouse:273", "ПКМ")
    s = s.replace("mouse_down", "Колесо вниз").replace("mouse_up", "Колесо вверх")
    s = s.replace("XF86AudioRaiseVolume", "Громкость +").replace("XF86AudioLowerVolume", "Громкость −")
    s = s.replace("XF86AudioMute", "Mute").replace("XF86AudioMicMute", "Микрофон mute")
    s = s.replace("XF86MonBrightnessUp", "Яркость +").replace("XF86MonBrightnessDown", "Яркость −")
    s = s.replace("XF86AudioNext", "Следующий трек").replace("XF86AudioPrev", "Предыдущий трек")
    s = s.replace("XF86AudioPlay", "Play/Pause").replace("XF86AudioPause", "Play/Pause")
    return s

def pretty_cmd(cmd):
    c = cmd.strip()
    if c in LOCALS:
        c = LOCALS[c]
    if "hyprshutdown" in c:
        return "Выход из Hyprland", "Панель"
    if c.startswith("wpctl set-volume") and "5%+" in c:
        return "Громкость +5%", "Мультимедиа"
    if c.startswith("wpctl set-volume") and "5%-" in c:
        return "Громкость −5%", "Мультимедиа"
    if "set-mute @DEFAULT_AUDIO_SINK@" in c:
        return "Звук вкл/выкл", "Мультимедиа"
    if "set-mute @DEFAULT_AUDIO_SOURCE@" in c:
        return "Микрофон вкл/выкл", "Мультимедиа"
    if c.startswith("brightnessctl"):
        return ("Яркость +" if "5%+" in c else "Яркость −"), "Мультимедиа"
    if c.startswith("playerctl"):
        if "next" in c: return "Следующий трек", "Мультимедиа"
        if "previous" in c: return "Предыдущий трек", "Мультимедиа"
        return "Play/Pause", "Мультимедиа"
    if c.startswith("hyprshot"):
        return "Скриншот области", "Запуск"
    q = re.match(r'quickshell\s+ipc\s+call\s+(\w+)\s+(\w+)', c)
    if q:
        return "Quickshell · %s %s" % (q.group(1), q.group(2)), "Панель"
    if len(c) > 46:
        c = c[:45] + "…"
    return c, "Запуск"

def human_action(disp):
    d = disp.strip()
    mm = re.match(r'hl\.dsp\.([\w.]+)\((.*)\)\s*$', d, re.S)
    if not mm:
        return d, "Прочее"
    fn, arg = mm.group(1), mm.group(2).strip()
    if fn == "exec_cmd":
        return pretty_cmd(unq(arg))
    if fn == "window" or fn.startswith("window."):
        a = fn.split(".", 1)[1] if "." in fn else ""
        b = arg
        if a == "":
            sub = re.match(r'(\w+)\s*\((.*)\)', arg, re.S)
            if sub: a, b = sub.group(1), sub.group(2)
        if a == "close": return "Закрыть окно", "Окна"
        if a == "float": return "Плавающее окно", "Окна"
        if a == "pseudo": return "Псевдо-тайлинг", "Окна"
        if a == "fullscreen": return "Полный экран", "Окна"
        if a == "drag": return "Перетащить окно", "Окна"
        if a == "resize": return "Изменить размер", "Окна"
        if a == "move":
            w = re.search(r'workspace\s*=\s*"?([^",}]+)"?', b)
            return ("На рабочий стол " + w.group(1)) if w else "Переместить окно", "Рабочие столы"
        return "Окно: " + (a or arg), "Окна"
    if fn == "focus":
        dr = re.search(r'direction\s*=\s*"([^"]+)"', arg)
        if dr:
            names = {"left": "влево", "right": "вправо", "up": "вверх", "down": "вниз"}
            return "Фокус " + names.get(dr.group(1), dr.group(1)), "Окна"
        ws = re.search(r'workspace\s*=\s*"?([^",}]+)"?', arg)
        if ws: return "Рабочий стол " + ws.group(1), "Рабочие столы"
        return "Фокус", "Окна"
    if fn == "workspace" or fn.startswith("workspace."):
        a = fn.split(".", 1)[1] if "." in fn else ""
        b = arg
        if a == "":
            sub = re.match(r'(\w+)\s*\((.*)\)', arg, re.S)
            if sub: a, b = sub.group(1), sub.group(2)
        if a == "toggle_special":
            return "Спец. стол " + unq(b), "Рабочие столы"
        return "Рабочий стол: " + (a or arg), "Рабочие столы"
    if fn == "layout":
        return "Разделить/объединить", "Раскладка"
    return fn + ": " + arg, "Прочее"

items = []
for call in find_calls(src, "hl.bind"):
    parts = split_top(call)
    if len(parts) < 2:
        continue
    keyexpr, disp = parts[0], parts[1]
    if "mouse" in keyexpr and "272" not in keyexpr and "273" not in keyexpr:
        continue
    if ".. key" in keyexpr:
        shift = "SHIFT" in keyexpr
        for i in range(1, 11):
            key = str(i % 10)
            if shift:
                keys = "%s + SHIFT + %s" % (MAIN, key)
                action, group = "На рабочий стол " + str(i), "Рабочие столы"
            else:
                keys = "%s + %s" % (MAIN, key)
                action, group = "Рабочий стол " + str(i), "Рабочие столы"
            items.append({"keys": keys, "action": action, "group": group})
        continue
    action, group = human_action(disp)
    items.append({"keys": keys_of(keyexpr), "action": action, "group": group})

order = ["Панель", "Запуск", "Окна", "Рабочие столы", "Раскладка", "Мультимедиа", "Прочее"]
items.sort(key=lambda x: (order.index(x["group"]) if x["group"] in order else 99))
print(json.dumps(items, ensure_ascii=False))

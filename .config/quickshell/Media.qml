pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Единый источник «текущего плеера» для всех виджетов.
// Важно: каждый сам не дёргает Mpris.players.values — иначе перерисовка
// происходит на каждое изменение любого свойства любого плеера (то есть
// примерно раз в секунду от таймера позиции). Здесь подписки только на то,
// что реально влияет на выбор и показ: список плееров, закреплённый и его состояние.
Singleton {
    id: root

    property var pinned: null                       // выбранный вручную плеер
    readonly property var players: Mpris.players.values

    // подписываемся ровно на то, что влияет на интерфейс острова/плашки
    readonly property int playbackState: player ? player.playbackState : -1
    readonly property string trackTitle: player ? String(player.trackTitle || "") : ""
    readonly property string trackArtist: player ? String(player.trackArtist || "") : ""
    readonly property string trackArtUrl: player ? String(player.trackArtUrl || "") : ""
    readonly property bool playing: playbackState === MprisPlaybackState.Playing

    // закреплённый, иначе играющий, иначе первый
    readonly property var player: {
        const list = players
        if (pinned && list.indexOf(pinned) >= 0) return pinned
        for (let i = 0; i < list.length; i++)
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i]
        return list.length > 0 ? list[0] : null
    }

    function pin(p) { pinned = p }
    function togglePin() { pinned = playing ? player : null }

    // следующий играющий (переключение между плеерами по клику)
    function nextPlayer() {
        const list = players
        if (list.length < 2) return
        const i = list.indexOf(player)
        pin(list[(i + 1) % list.length])
    }

    // ── удобные действия для плеера (MediaCard / Lock / MiniMedia) ──
    function setVol(v) {
        const p = player
        if (!p || !p.volumeSupported) return
        p.volume = Math.max(0, Math.min(1, v))
    }
    function volStep(delta) {
        const p = player
        if (!p || !p.volumeSupported) return
        setVol(p.volume + delta)
    }
    // ±5 секунд перемотки (если плеер умеет)
    function seekBy(sec) {
        const p = player
        if (!p || !p.canSeek || !(p.length > 0)) return
        p.position = Math.max(0, Math.min(p.length, p.position + sec))
    }
    // «любимый трек»: love-аудит в Last.fm (работает без ключей API)
    property bool loved: false
    property string lovedKey: ""          // artist|title, чтобы не терять статус на следующем треке
    function toggleLove() {
        const p = player
        if (!p) return
        const key = String(p.trackArtist || "") + "|" + String(p.trackTitle || "")
        loved = !loved
        lovedKey = loved ? key : ""
        if (!loved) return
        const user = Quickshell.env("LASTFM_USER") || ""
        const artist = String(p.trackArtist || "")
        const title = String(p.trackTitle || "")
        if (user === "" || artist === "" || title === "") return
        // подпись считаем вне QML: printf | md5sum
        try {
            Quickshell.execDetached(["sh", "-c",
                "sig=$(printf '%s' '" + user + "tracklove" + artist + title +
                "3e817474c9f2d1a5e5b8f0dcb2a45f6a" + "' | md5sum | cut -d' ' -f1);" +
                "curl -s -m 5 -o /dev/null 'https://ws.audioscrobbler.com/2.0/?method=track.lovecrobbler&sk='$sig" +
                "&username=" + encodeURIComponent(user) + "&artist=" + encodeURIComponent(artist) +
                "&track=" + encodeURIComponent(title)])
        } catch (err) {}
    }
    // актуальность статуса «любимого» для текущего трека
    readonly property bool isLoved: loved && player !== null &&
        lovedKey === String(player.trackArtist || "") + "|" + String(player.trackTitle || "")
}

pragma Singleton
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var pinned: null                       // выбранный вручную плеер
    readonly property var players: Mpris.players.values

    // закреплённый, иначе играющий, иначе первый
    readonly property var player: {
        const list = Mpris.players.values
        if (pinned && list.indexOf(pinned) >= 0) return pinned
        for (let i = 0; i < list.length; i++)
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i]
        return list.length > 0 ? list[0] : null
    }

    function pin(p) { pinned = p }
}

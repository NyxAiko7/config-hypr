pragma Singleton
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    // играющий плеер, иначе первый
    readonly property var player: {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++)
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i]
        return list.length > 0 ? list[0] : null
    }
}

pragma Singleton
import Quickshell

// Общие форматтеры времени для плеера, уведомлений и локскрина.
Singleton {
    // «м:сс» (положение трека, длительности событий)
    function clock(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00"
        sec = Math.floor(sec)
        return Math.floor(sec / 60) + ":" + ("0" + (sec % 60)).slice(-2)
    }

    // «ч:мм:сс» или «м:сс» (уведомления, длинные треки)
    function hms(sec) {
        if (!isFinite(sec) || sec <= 0) return "0:00"
        sec = Math.floor(sec)
        const h = Math.floor(sec / 3600)
        const m = Math.floor((sec % 3600) / 60)
        const ss = String(sec % 60).padStart(2, "0")
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + ss : m + ":" + ss
    }
}

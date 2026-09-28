import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "Theme.js" as Theme

PanelWindow {
    id: root

    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }

    readonly property int pad: 16
    property var stats: ({})
    property string weather: ""
    property int tick: 0
    readonly property var player: activePlayer()
    readonly property real cellWidth: (implicitWidth - 2 * pad) / 7

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 2 * pad
    color: "transparent"
    focusable: true
    visible: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        id: infoProcess
        command: [Theme.infoCmd]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        out[line.slice(0, i)] = line.slice(i + 1);
                }
                root.stats = out;
            }
        }
    }

    Process {
        id: weatherProcess
        command: [Theme.curl, "-fsS", "--max-time", "10", "https://wttr.in/?format=%c+%t+%C&lang=ja"]
        stdout: StdioCollector {
            onStreamFinished: root.weather = text.trim()
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: if (!infoProcess.running) infoProcess.running = true
    }

    Timer {
        interval: 20 * 60 * 1000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: if (!weatherProcess.running) weatherProcess.running = true
    }

    // Mpris の position はシグナル駆動なので、再生中は毎秒 tick して
    // プログレスバーのバインディングを再評価させる。
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && root.player !== null && root.player.isPlaying
        onTriggered: root.tick++
    }

    IpcHandler {
        target: "panel"

        function toggle(): void {
            root.visible = !root.visible;
        }
    }

    onVisibleChanged: if (visible) card.forceActiveFocus()

    function activePlayer() {
        const players = Mpris.players.values;
        let fallback = null;
        for (const p of players) {
            if (p.isPlaying)
                return p;
            if (!fallback)
                fallback = p;
        }
        return fallback;
    }

    function calendarWeeks(date) {
        const year = date.getFullYear();
        const month = date.getMonth();
        const today = new Date();
        const startOffset = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysInPrev = new Date(year, month, 0).getDate();

        const cells = [];
        for (let i = 0; i < 42; i++) {
            const dayIndex = i - startOffset;
            let day, current;
            if (dayIndex < 0) {
                day = daysInPrev + dayIndex + 1;
                current = false;
            } else if (dayIndex >= daysInMonth) {
                day = dayIndex - daysInMonth + 1;
                current = false;
            } else {
                day = dayIndex + 1;
                current = true;
            }
            cells.push({
                day: day,
                current: current,
                today: current && day === today.getDate() && month === today.getMonth() && year === today.getFullYear()
            });
        }

        const weeks = [];
        for (let w = 0; w < 6; w++)
            weeks.push(cells.slice(w * 7, w * 7 + 7));
        return weeks;
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14
        color: Theme.base00
        border.width: 1
        border.color: Theme.base02
        focus: true
        Keys.onEscapePressed: root.visible = false

        ColumnLayout {
            id: content
            anchors {
                fill: parent
                margins: root.pad
            }
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.base05
                    font.family: Theme.fontSans
                    font.pixelSize: 36
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 6
                    text: clock.date.toLocaleString(Qt.locale("ja_JP"), "M月d日 (ddd)")
                    color: Theme.base04
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Column {
                id: calendar
                Layout.fillWidth: true
                spacing: 3

                property var weeks: root.calendarWeeks(clock.date)

                Row {
                    spacing: 0

                    Repeater {
                        model: ["日", "月", "火", "水", "木", "金", "土"]

                        Item {
                            width: root.cellWidth
                            height: 16

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: index === 0 ? Theme.base08 : index === 6 ? Theme.base0D : Theme.base04
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Repeater {
                    model: calendar.weeks

                    Row {
                        spacing: 0

                        Repeater {
                            model: modelData

                            Item {
                                width: root.cellWidth
                                height: 20

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    radius: 11
                                    visible: modelData.today
                                    color: Theme.base0D
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.today ? Theme.base00 : modelData.current ? Theme.base05 : Theme.base03
                                    opacity: modelData.current ? 1 : 0.45
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.base02
            }

            // Mpris: 再生中のトラック
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                visible: root.player !== null

                Text {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackTitle || "不明なタイトル" : ""
                    color: Theme.base05
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player ? [root.player.trackArtist, root.player.trackAlbum].filter(s => s).join(" / ") : ""
                    color: Theme.base04
                    font.family: Theme.fontSans
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 3
                    radius: 1.5
                    color: Theme.base02

                    Rectangle {
                        width: {
                            root.tick;
                            const p = root.player;
                            if (!p || !p.length || p.length <= 0)
                                return 0;
                            return Math.max(0, Math.min(1, p.position / p.length)) * parent.width;
                        }
                        height: parent.height
                        radius: parent.radius
                        color: Theme.base0D
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 22

                    Text {
                        text: "⏮"
                        color: Theme.base05
                        opacity: root.player && root.player.canGoPrevious ? 1 : 0.3
                        font.pixelSize: 14

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                        }
                    }

                    Text {
                        text: root.player && root.player.isPlaying ? "⏸" : "▶"
                        color: Theme.base0D
                        font.pixelSize: 14

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player) root.player.togglePlaying()
                        }
                    }

                    Text {
                        text: "⏭"
                        color: Theme.base05
                        opacity: root.player && root.player.canGoNext ? 1 : 0.3
                        font.pixelSize: 14

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player && root.player.canGoNext) root.player.next()
                        }
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: [
                        ["🔋", root.stats.bat],
                        ["📶", root.stats.net],
                        ["💻", root.stats.load ? root.stats.load + "  /  RAM " + root.stats.mem : ""],
                        ["💾", root.stats.disk ? "/ " + root.stats.disk : ""],
                        ["🔊", root.stats.vol]
                    ].filter(row => row[1])

                    Text {
                        text: modelData[0] + " " + modelData[1]
                        color: Theme.base05
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.weather.length > 0
                text: root.weather
                color: Theme.base04
                font.family: Theme.fontSans
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}

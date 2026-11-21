// Bar for hyprland, in place of waybar - which stays on devbox.
//
// Colours follow ../mako/config. The labels are plain text rather than Nerd
// Font glyphs; the font below carries them if you want icons instead.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Generated from sketchybar-app-font's table by ./default.nix. Resolves next
// to this file, since both are installed into ~/.config/quickshell.
import "icon_map.js" as AppIcons

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            screen: bar.modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30

            // Semi-transparent, like waybar's stock style.css - which is
            // rgba(43, 48, 59, 0.5) on the window. Same idea, kept in the Nord
            // base below so the bar still matches hyprland's borders.
            //
            // Qt colour literals are #AARRGGBB, so the leading pair is alpha.
            // ../hyprland/hyprland.lua blurs this layer by namespace, which is
            // what stops a busy wallpaper showing through as noise.
            readonly property real bgAlpha: 0.5
            readonly property color base: "#2e3440"
            color: Qt.rgba(bar.base.r, bar.base.g, bar.base.b, bar.bgAlpha)

            readonly property color fg: "#d8dee9"
            readonly property color accent: "#88c0d0"
            readonly property color dim: "#7b88a1"
            readonly property color alert: "#bf616a"
            readonly property string face: "Hack Nerd Font"
            // Ligature font: the literal ":firefox:" draws as the Firefox mark.
            readonly property string appFace: "sketchybar-app-font"
            // Vertical correction for appFace, in px. Its ink sits higher in
            // the line box than Hack's digits do, so without this the app marks
            // float above the workspace numbers beside them.
            readonly property int glyphNudge: 2

            // Classes the table cannot be expected to know. It is keyed on mac
            // app names, and these are what hyprctl actually reports here.
            readonly property var iconAliases: ({
                    // reverse-DNS id whose tail ("onepassword") is not a key either
                    "com.onepassword.onepassword": ":one_password:",
                    // no Thunar mark in the font; the generic file manager reads right
                    "thunar": ":finder:"
                })

            // hyprland reports a window class ("firefox"); the table is keyed on
            // mac app names ("Firefox"), hence the lowercased index. Unknown
            // apps get the same :default: glyph sketchybar falls back to.
            function iconFor(cls: string): string {
                if (!cls)
                    return "";

                const key = cls.toLowerCase();
                if (bar.iconAliases[key])
                    return bar.iconAliases[key];

                const direct = AppIcons.byLowerName[key];
                if (direct)
                    return direct;

                // Reverse-DNS ids such as com.transmissionbt.transmission: the
                // last segment is usually the name the table does know.
                const tail = key.split(".").pop();
                return AppIcons.byLowerName[tail] ?? AppIcons.fallback;
            }

            // Pipewire objects emit no property changes until something tracks
            // them, so the volume would never update without this.
            PwObjectTracker {
                objects: [Pipewire.defaultAudioSink]
            }

            SystemClock {
                id: clock

                precision: SystemClock.Minutes
            }

            QtObject {
                id: shellState

                property string keymap: ""
                property string submap: ""

                readonly property bool bulgarian: shellState.keymap.startsWith("Bulgarian")
                readonly property var sink: Pipewire.defaultAudioSink

                readonly property var player: {
                    const players = Mpris.players.values;
                    return players.find(p => p.isPlaying) ?? players[0] ?? null;
                }
            }

            // The layout only ever arrives as an event, so the one in effect at
            // startup has to be read out of hyprctl once.
            Process {
                running: true
                command: ["hyprctl", "devices", "-j"]

                stdout: StdioCollector {
                    id: devices

                    onStreamFinished: {
                        const main = JSON.parse(devices.text).keyboards.find(k => k.main);
                        if (main)
                            shellState.keymap = main.active_keymap;
                    }
                }
            }

            Connections {
                target: Hyprland

                function onRawEvent(event) {
                    // activelayout arrives as "<keyboard>,<layout>". submap
                    // carries an empty payload when a submap is left.
                    if (event.name === "activelayout")
                        shellState.keymap = event.data.slice(event.data.indexOf(",") + 1);
                    else if (event.name === "submap")
                        shellState.submap = event.data;
                }
            }

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8

                Repeater {
                    model: ScriptModel {
                        // hyprland lists workspaces in creation order.
                        values: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)
                    }

                    delegate: Rectangle {
                        id: workspace

                        required property var modelData

                        // One glyph per distinct app on the workspace, in the
                        // order hyprland lists them. Two kitty windows draw one
                        // kitty mark, as sketchybar's aerospace.sh does.
                        readonly property var apps: {
                            const windows = workspace.modelData.toplevels?.values ?? [];
                            const glyphs = [];
                            for (const w of windows) {
                                const glyph = bar.iconFor(w.lastIpcObject?.class ?? "");
                                if (glyph && !glyphs.includes(glyph))
                                    glyphs.push(glyph);
                            }
                            return glyphs;
                        }

                        // Empty workspaces are hidden, the focused one always
                        // shows so there is somewhere to read "you are here".
                        // Layouts skip invisible children, so this closes the gap.
                        visible: workspace.modelData.focused || workspace.apps.length > 0

                        readonly property color ink: {
                            if (workspace.modelData.focused)
                                return bar.base;
                            if (workspace.modelData.urgent)
                                return bar.alert;
                            return bar.fg;
                        }

                        implicitWidth: workspaceRow.implicitWidth + 12
                        implicitHeight: 20
                        radius: 4
                        color: workspace.modelData.focused ? bar.accent : "transparent"

                        RowLayout {
                            id: workspaceRow

                            anchors.centerIn: parent
                            spacing: 4

                            // Both sit in a box the full height of the pill and
                            // centre their own text in it. Left to themselves
                            // the two fonts have different line heights - the
                            // glyph font's is much taller - so each box would be
                            // centred separately and the digits would ride low.
                            Text {
                                Layout.preferredHeight: workspace.implicitHeight
                                Layout.alignment: Qt.AlignVCenter
                                verticalAlignment: Text.AlignVCenter
                                text: workspace.modelData.name
                                font.family: bar.face
                                font.pixelSize: 12
                                font.bold: true
                                color: workspace.ink
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                // The glyph font draws its marks high in the em
                                // box: measured against the digits they land
                                // ~2px above them, which centring cannot fix
                                // because both boxes are already centred. So
                                // this is a measured nudge, not a guess - see
                                // bar.glyphNudge.
                                Layout.topMargin: bar.glyphNudge
                                visible: workspace.apps.length > 0
                                text: workspace.apps.join(" ")
                                font.family: bar.appFace
                                font.pixelSize: 13
                                color: workspace.ink
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: workspace.modelData.activate()
                        }
                    }
                }

                Text {
                    visible: shellState.submap !== ""
                    text: shellState.submap
                    font.family: bar.face
                    font.pixelSize: 12
                    font.italic: true
                    color: bar.accent
                }

                Text {
                    Layout.maximumWidth: 480
                    text: Hyprland.activeToplevel?.title ?? ""
                    elide: Text.ElideRight
                    font.family: bar.face
                    font.pixelSize: 12
                    color: bar.dim
                }
            }

            Text {
                id: nowPlaying

                anchors.centerIn: parent
                visible: shellState.player !== null
                width: Math.min(nowPlaying.implicitWidth, 420)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                font.family: bar.face
                font.pixelSize: 12
                color: bar.fg

                text: {
                    if (!shellState.player)
                        return "";
                    const artist = shellState.player.trackArtist;
                    return artist ? artist + " - " + shellState.player.trackTitle : shellState.player.trackTitle;
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: shellState.player.isPlaying = !shellState.player.isPlaying
                }
            }

            RowLayout {
                anchors {
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 12

                // Volume. The glyph ramp is ../sketchybar/plugins/volume.sh's;
                // sketchybar hides the percentage, this keeps it, and the whole
                // thing is one scroll target.
                Item {
                    id: volumeWidget

                    // Pipewire allows volumes above 1.0 (overamplification).
                    // Scrolling deliberately stops at 100%: it is an easy
                    // control to nudge by accident.
                    readonly property real step: 0.05
                    readonly property var audio: shellState.sink?.audio ?? null

                    implicitWidth: volumeRow.implicitWidth
                    implicitHeight: volumeRow.implicitHeight
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        id: volumeRow

                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            font.family: bar.face
                            font.pixelSize: 14
                            color: volumeWidget.audio?.muted ? bar.dim : bar.accent

                            text: {
                                if (!volumeWidget.audio)
                                    return "";
                                if (volumeWidget.audio.muted)
                                    return "\uEEE8";
                                const pct = Math.round(volumeWidget.audio.volume * 100);
                                if (pct >= 60)
                                    return "\uF028";
                                if (pct >= 10)
                                    return "\uF027";
                                return "\uF026";
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            font.family: bar.face
                            font.pixelSize: 12
                            color: volumeWidget.audio?.muted ? bar.dim : bar.fg
                            text: volumeWidget.audio ? Math.round(volumeWidget.audio.volume * 100) + "%" : ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                volumeWidget.audio.muted = !volumeWidget.audio.muted;
                            else
                                Quickshell.execDetached(["pavucontrol"]);
                        }

                        // Pipewire's volume is writable, so this sets it
                        // directly rather than spawning swayosd-client per
                        // notch the way the media keys in
                        // ../hyprland/hyprland.lua have to.
                        onWheel: event => {
                            const audio = volumeWidget.audio;
                            if (!audio)
                                return;

                            const delta = event.angleDelta.y > 0 ? volumeWidget.step : -volumeWidget.step;
                            audio.volume = Math.max(0, Math.min(1, audio.volume + delta));

                            // Scrolling up off zero should make sound, not
                            // silently raise a muted sink.
                            if (delta > 0 && audio.muted)
                                audio.muted = false;

                            event.accepted = true;
                        }
                    }
                }

                // Keyboard layout, as ../sketchybar/plugins/get_input_source.sh
                // draws it: U+F132F for the latin layout, U+F132D otherwise.
                // Written as codepoints because both sit above the BMP.
                Text {
                    text: String.fromCodePoint(shellState.bulgarian ? 0xF132D : 0xF132F)
                    font.family: bar.face
                    // Not 12 like the text beside it: this glyph draws small
                    // inside its em box, so matching the nominal size leaves it
                    // visibly smaller. Measured - at 15 its ink was 8px against
                    // the 10px of everything else here, so this is 15 * 10/8.
                    font.pixelSize: 19
                    color: shellState.bulgarian ? bar.accent : bar.fg
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd dd MMM HH:mm")
                    font.family: bar.face
                    font.pixelSize: 12
                    color: bar.fg
                }
            }
        }
    }
}

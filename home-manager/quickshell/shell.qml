// quickshell bar for h4kbox, replacing waybar.
//
// quickshell loads ~/.config/quickshell/shell.qml as the default config, which
// is where ./default.nix installs this.
//
// Every type and property used here was checked against the quickshell 0.3.0
// sources rather than written from memory - QML resolves lazily, so a wrong
// property name is a silently empty bar rather than a build failure.
//
//   ShellRoot, Variants{model,delegate}, PanelWindow{anchors,screen,...}  core
//   Quickshell.screens                                                   core
//   Hyprland.workspaces.values / .focusedWorkspace / .activeToplevel      Hyprland
//   Hyprland.dispatch(...)                                               Hyprland
//   HyprlandWorkspace.id / .name / .focused / .urgent                     Hyprland
//   SystemClock{precision,date}                                           core
//   UPower.displayDevice{percentage,state,isLaptopBattery}                UPower

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

ShellRoot {
  // One bar per monitor. Variants re-instantiates the delegate as screens come
  // and go, which matters in the VM where the display is resized on the fly.
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      required property var modelData
      screen: modelData

      // Solarized dark, to match the wallpaper the hyprland module sets.
      readonly property color bg: "#002b36"
      readonly property color fg: "#93a1a1"
      readonly property color dim: "#586e75"
      readonly property color accent: "#268bd2"
      readonly property color urgent: "#dc322f"
      readonly property string uiFont: "Hack Nerd Font"

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 30
      color: bg

      // Reserve the strip so tiled windows do not sit under the bar.
      exclusiveZone: implicitHeight

      SystemClock {
        id: clock
        precision: SystemClock.Minutes
      }

      // ---- workspaces (left) ----
      Row {
        id: workspaces

        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
          model: Hyprland.workspaces.values

          Rectangle {
            required property var modelData

            width: Math.max(24, label.implicitWidth + 12)
            height: 22
            radius: 4
            color: modelData.focused ? bar.accent : "transparent"

            Text {
              id: label
              anchors.centerIn: parent
              text: modelData.name
              font.family: bar.uiFont
              font.pixelSize: 13
              font.bold: modelData.focused
              color: {
                if (modelData.focused) return bar.bg;
                if (modelData.urgent) return bar.urgent;
                return bar.dim;
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
          }
        }
      }

      // ---- focused window title (centre) ----
      Text {
        anchors.centerIn: parent
        width: parent.width * 0.4
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        font.family: bar.uiFont
        font.pixelSize: 13
        color: bar.fg
      }

      // ---- battery + clock (right) ----
      Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        // Hidden on desktops and in the VM, where there is no battery.
        Text {
          visible: UPower.displayDevice.isLaptopBattery
          text: {
            const pct = Math.round(UPower.displayDevice.percentage * 100);
            const charging = UPower.displayDevice.state === UPowerDeviceState.Charging;
            return (charging ? "󰂄 " : "󰁹 ") + pct + "%";
          }
          font.family: bar.uiFont
          font.pixelSize: 13
          color: UPower.displayDevice.percentage <= 0.15 ? bar.urgent : bar.fg
        }

        Text {
          text: Qt.formatDateTime(clock.date, "ddd dd MMM  hh:mm")
          font.family: bar.uiFont
          font.pixelSize: 13
          color: bar.fg
        }
      }
    }
  }
}

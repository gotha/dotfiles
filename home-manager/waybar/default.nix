{ pkgs, ... }:
{

  home.packages = with pkgs; [
    pavucontrol
    playerctl
    upower
    waybar-mpris
  ];

  programs.waybar = {
    enable = true;

    style = builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css" + ''
      * {
        font-family: "Hack Nerd Font";
      }
    '';

    #systemd.enable = true;

    settings = [
      {
        height = 30;
        spacing = 4;

        "modules-left" = [
          "sway/workspaces"
          "sway/mode"
          "sway/scratchpad"
          "sway/window"
        ];
        "modules-center" = [ "custom/waybar-mpris" ];
        "modules-right" = [
          "custom/gpu"
          "network"
          "custom/headset-battery"
          "custom/mouse-battery"
          "pulseaudio"
          "cpu"
          "memory"
          "temperature"
          "battery"
          "sway/language"
          "clock"
          #"tray"
        ];

        "custom/os" = {
          format = " ";
        };

        "sway/workspaces" = {
          "disable-scroll" = false;
          "all-outputs" = true;
          "warp-on-scroll" = false;
          "format" = "{index}: {icon} ";
          "format-icons" = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "6" = "󱄅";
            "7" = "";
            "8" = "";
            "9" = "";
            "10" = "";
            urgent = "";
          };
        };

        "keyboard-state" = {
          numlock = true;
          capslock = true;
          format = "{name} {icon}";
          "format-icons" = {
            locked = "";
            unlocked = "";
          };
        };

        "sway/mode" = {
          format = ''<span style="italic">{}</span>'';
        };

        "sway/scratchpad" = {
          format = "{icon} {count}";
          "show-empty" = false;
          "format-icons" = [
            ""
            ""
          ];
          tooltip = true;
          "tooltip-format" = "{app}: {title}";
        };

        mpd = {
          format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
          "format-disconnected" = "Disconnected ";
          "format-stopped" = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
          "unknown-tag" = "N/A";
          interval = 2;
          "consume-icons".on = " ";
          "random-icons" = {
            off = ''<span color="#f53c3c"></span> '';
            on = " ";
          };
          "repeat-icons".on = " ";
          "single-icons".on = "1 ";
          "state-icons" = {
            paused = "";
            playing = "";
          };
          "tooltip-format" = "MPD (connected)";
          "tooltip-format-disconnected" = "MPD (disconnected)";
        };

        "idle_inhibitor" = {
          format = "{icon}";
          "format-icons" = {
            activated = "";
            deactivated = "";
          };
        };

        tray = {
          # "icon-size" = 21;
          spacing = 10;
        };

        clock = {
          # "timezone" = "America/New_York";
          format = "{:%a %d %b %H:%M}";
          "tooltip-format" = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
          "format-alt" = "{:%Y-%m-%d}";
        };

        cpu = {
          format = "{usage}% ";
          tooltip = true;
        };

        memory = {
          format = "{}% ";
        };

        temperature = {
          "critical-threshold" = 80;
          format = "{temperatureC}°C {icon}";
          "format-icons" = [
            ""
            ""
            ""
          ];
        };

        backlight = {
          # "device" = "acpi_video1";
          format = "{percent}% {icon}";
          "format-icons" = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          "format-charging" = "{capacity}% ";
          "format-plugged" = "{capacity}% ";
          "format-alt" = "{time} {icon}";
          "format-icons" = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        "battery#bat2" = {
          bat = "BAT2";
        };

        network = {
          #interface = "enp6s0"; # adjust to your interface
          "format-wifi" = "({signalStrength}%) ";
          "format-ethernet" = "{ipaddr}/{cidr} 󰈀";
          "tooltip-format" = "{ifname} via {gwaddr} ";
          "format-linked" = "{ifname} (No IP) ";
          "format-disconnected" = "Disconnected 󰌙";
          "format-alt" = "{ifname}: {ipaddr}/{cidr}";
        };

        "custom/gpu" = {
          format = "{icon} {text}";
          "format-icons" = [
            ""
            ""
            ""
          ];
          "return-type" = "json";
          interval = 5;
          exec = pkgs.writeShellScript "gpu-status" ''
            nvidia-smi --query-gpu=power.draw,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | awk -F', ' '{
              temp = $5
              class = "normal"
              printf "{\"text\": \"%.0fW %d%% %.1f/%.1fGB\", \"tooltip\": \"GPU Temp: %d°C | Power: %.0fW | Util: %d%% | VRAM: %.1f/%.1fGB\", \"class\": \"%s\", \"percentage\": %d}", $1, $2, $3/1024, $4/1024, temp, $1, $2, $3/1024, $4/1024, class, temp
            }'
          '';
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          "format-muted" = " {format_source}";
          "format-source" = "{volume}% ";
          "format-source-muted" = "";
          "format-icons".default = [
            ""
            ""
            ""
          ];
          "on-click" = "pavucontrol";
        };

        "custom/headset-battery" = {
          format = "{}% {icon} ";
          interval = 10;
          "format-icons".default = "";
          exec = ''
            device="/org/freedesktop/UPower/devices/headset_dev_CC_98_8B_C1_67_A6"
            percentage=$(upower -i "$device" | grep percentage | awk '{print $2}' | tr -d '%')
            if [ "$percentage" -gt 0 ]; then
              echo "$percentage"
            else
              echo ""
            fi
          '';
        };

        "custom/mouse-battery" = {
          format = "{} {icon} ";
          interval = 60;
          "format-icons".default = "󰍽";
          exec = ''
            device="/org/freedesktop/UPower/devices/mouse_dev_C1_17_DD_26_66_5D"
            percentage=$(upower -i "$device" | grep percentage | awk '{print $2}' | tr -d '%')
            if [ "$percentage" -gt 0 ]; then
              echo "$percentage"
            else
              echo ""
            fi
          '';
        };

        "custom/waybar-mpris" = {
          "return-type" = "json";
          exec = "waybar-mpris --position --autofocus --pause ' ' --play ' '";
          "on-click" = "waybar-mpris --send toggle";
          "on-click-right" = "playerctl next";
          escape = true;
        };
      }
    ];
  };

}

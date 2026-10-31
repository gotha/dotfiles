{ pkgs, ... }:
{
  # Bluetooth audio for the WH-1000XM3. `hardware.bluetooth` itself lives in
  # hardware-configuration.nix; this file is only about keeping playback on A2DP
  # instead of the 8kHz mono HFP profile.

  # Disable LDAC (decoder has issues), use aptX HD as default. Don't autoswitch
  # to the HFP headset profile when something opens a mic (dictation, browser
  # calls): it drops playback to 8kHz mono CVSD and stays there. The StreamCam is
  # the mic anyway, the headset mic is never wanted.
  #
  # autoswitch lives under wireplumber.settings since 0.5; the old monitor.bluez
  # `bluez5.autoswitch-profile` key is silently ignored there.
  # Check with `wpctl settings bluetooth.autoswitch-to-headset-profile`.
  environment.etc."wireplumber/wireplumber.conf.d/51-disable-ldac.conf".text = ''
    monitor.bluez.properties = {
      bluez5.codecs = [ aptx_hd aptx aac sbc_xq sbc ]
    }

    wireplumber.settings = {
      bluetooth.autoswitch-to-headset-profile = false
    }
  '';

  # The headset comes up HFP-only after a cold boot: `powerOnBoot` has bluez
  # connect it before wireplumber has registered its A2DP endpoints, so the only
  # profile ever negotiated is headset-head-unit -- 8kHz mono CVSD. Wireplumber's
  # saved default is already a2dp-sink; it simply has nothing to select, and
  # nothing re-probes afterwards, so playback stays at 8kHz until the headset is
  # reconnected by hand. The autoswitch setting above does not cover this:
  # a missing profile is not an unwanted switch.
  #
  # WantedBy wireplumber.service rather than default.target so a
  # `systemctl --user restart wireplumber` is covered too -- that loses A2DP the
  # same way, and restarting wireplumber is how this config gets tested.
  systemd.user.services.bluetooth-headset-a2dp = {
    description = "Renegotiate A2DP on the headset once wireplumber is up";
    wantedBy = [ "wireplumber.service" ];
    after = [ "wireplumber.service" ];
    path = with pkgs; [
      bluez
      pulseaudio # pactl comes from pulseaudio
      gawk
      gnugrep
      coreutils
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      mac=CC:98:8B:C1:67:A6
      card=bluez_card.CC_98_8B_C1_67_A6

      # Both readers scope themselves to this card's block: `Card #N` resets,
      # the Name line arms. Grepping the whole listing for "a2dp-sink" does not
      # work - it also matches the available-profile lines, which are printed
      # whatever the active profile is.
      active_profile() {
        pactl list cards 2>/dev/null |
          awk -v c="Name: $card" '
            /^Card #/ { f = 0 }
            index($0, c) { f = 1 }
            f && $1 == "Active" && $2 == "Profile:" { print $3; exit }
          '
      }

      # Whether a2dp-sink is on offer yet. wireplumber registers the card before
      # it has finished negotiating A2DP, and set-card-profile inside that window
      # fails with "No such entity" - which is what used to drop us into the
      # reconnect path on every wireplumber restart.
      a2dp_offered() {
        pactl list cards 2>/dev/null |
          awk -v c="Name: $card" '
            /^Card #/ { f = 0 }
            index($0, c) { f = 1 }
            f && $1 == "a2dp-sink:" && /available: yes/ { print "yes"; exit }
          '
      }

      # After= only means wireplumber *started*. Poll instead of sleeping a fixed
      # amount, so a healthy boot exits on the first pass and never interrupts
      # playback. ~2s is typical here and 10s is the headroom.
      for _ in $(seq 20); do
        [ -n "$(a2dp_offered)" ] && break
        sleep 0.5
      done

      [ "$(active_profile)" = a2dp-sink ] && exit 0

      # The cheap path: A2DP is there, just not selected. Switches in place
      # without dropping the link.
      if [ -n "$(a2dp_offered)" ]; then
        pactl set-card-profile "$card" a2dp-sink
        exit 0
      fi

      # Powered off or out of range: nothing to renegotiate.
      bluetoothctl info "$mac" | grep -q 'Connected: yes' || exit 0

      # Connected, but A2DP was never offered at all: bluez connected before
      # wireplumber registered its endpoints, so there is nothing to select.
      # Reconnect to redo the handshake.
      bluetoothctl disconnect "$mac"
      sleep 3
      bluetoothctl connect "$mac"
    '';
  };
}

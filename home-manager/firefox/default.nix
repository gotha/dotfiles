{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.firefox.custom;
in
{
  # Off by default: the settings below are opinions about one browser, the
  # policies below are opinions about the machine. ../../distros/devbox turns
  # them on; a host that wants a stock firefox leaves them off.
  options.programs.firefox.custom.policies.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Enterprise policies and force-installed extensions. home-manager bakes
      these into the firefox package it installs, which is the one that wins in
      PATH - they used to come from the NixOS module's
      /etc/firefox/policies/policies.json.
    '';
  };

  config.programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";

    policies = lib.mkIf cfg.policies.enable {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = false;
      DisableFormHistory = false;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;

      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        # 1Password
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        # Vimium
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          installation_mode = "force_installed";
        };
        # SponsorBlock
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };
        # Facebook Container
        "@contain-facebook" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/facebook-container/latest.xpi";
          installation_mode = "force_installed";
        };
        # Enhancer for YouTube
        "enhancerforyoutube@maximerf.addons.mozilla.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };

    profiles.default = {
      id = 0;
      isDefault = true;

      settings = {
        # Startup
        "browser.startup.page" = 3; # Restore previous session

        # New tab page
        "browser.newtabpage.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSearch" = false;

        # Privacy
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.userContext.enabled" = true;
        "privacy.userContext.ui.enabled" = true;

        # Disable credit card autofill
        "extensions.formautofill.creditCards.enabled" = false;

        # Network - disable prefetching
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;
        "network.http.speculative-parallel-limit" = 0;

        # UI preferences
        "browser.ctrlTab.sortByRecentlyUsed" = true;
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1; # 0 = normal, 1 = compact, 2 = touch

        # Dark mode
        "ui.systemUsesDarkTheme" = 1;
        "layout.css.prefers-color-scheme.content-override" = 0; # 0 = dark, 1 = light, 2 = system

        # Smooth scrolling
        "general.smoothScroll" = true;
        "general.smoothScroll.msdPhysics.enabled" = true;

        # Hardware acceleration
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true; # VA-API for video decoding on Linux

        # Search
        "browser.urlbar.placeholderName" = "Google";
        "browser.urlbar.placeholderName.private" = "Google";

        # Locale
        "intl.locale.requested" = "bg,en-US";

        # Disable telemetry
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
      };

      # Search engines configuration
      search = {
        force = true;
        default = "google";
        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };
          "NixOS Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };
          "google".metaData.alias = "@g";
        };
      };
    };
  };
}

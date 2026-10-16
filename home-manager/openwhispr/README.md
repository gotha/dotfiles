# OpenWhispr Home Manager module

This module manages OpenWhispr preferences on macOS and Linux. It is exported
as `homeManagerModules.openwhispr` from this flake and can also be imported
from `home-manager/openwhispr/default.nix`.

OpenWhispr supplies a [Nix package and NixOS module](https://github.com/OpenWhispr/openwhispr/blob/main/flake.nix).
Its NixOS module installs the application and sets up Wayland paste permissions;
it does not manage preferences. No OpenWhispr module was found in Home Manager's
upstream programs or services on 2026-10-12.

## Usage

With this repository declared as a flake input named `dotfiles`:

```nix
{ inputs, ... }:
{
  imports = [ inputs.dotfiles.homeManagerModules.openwhispr ];

  programs.openwhispr = {
    enable = true;
    package = null; # Installed separately, such as through Homebrew.
    dictionary = [ "NixOS" "Home Manager" ];
    settings = {
      environment = {
        DICTATION_KEY = "RightCommand";
        ACTIVATION_MODE = "push";
      };
      localStorage = {
        dictationKey = "RightCommand";
        activationMode = "push";
        audioCuesEnabled = true;
      };
    };
  };
}
```

Importing the module does not enable it or select personal preferences. The
macOS `platypus` profile explicitly enables it and imports `settings.nix`, which
captures this machine's portable preferences from OpenWhispr 1.10.2. Homebrew
continues to install the app. Edit that settings file to keep future changes.

On Linux, pass an OpenWhispr derivation as `package`, or install it separately
with the upstream NixOS module. Upstream's flake currently packages
`x86_64-linux` only. System-level Wayland permissions remain the responsibility
of NixOS. Choose a shortcut supported by your platform; Right Command is the
shortcut captured from this Mac.

## Options

| Option under `programs.openwhispr` | Default | Purpose |
| --- | --- | --- |
| `enable` | `false` | Enable package and preference management. |
| `package` | `null` | Optional application derivation to add to `home.packages`. |
| `dataDir` | Platform-dependent | Writable application data directory. |
| `backupDir` | `${config.xdg.stateHome}/openwhispr/home-manager-backups` | Private backups before each changed activation. |
| `dictionary` | `[]` | Words added to the running app, preserving existing entries. |
| `settings.environment` | `{}` | Non-secret string values merged into `.env`. |
| `settings.localStorage` | `{}` | Non-secret JSON-compatible preferences merged into localStorage. |

The data directory defaults to `~/Library/Application Support/open-whispr` on
macOS and `${config.xdg.configHome}/open-whispr` on Linux. These match the
installed 1.10.2 build. The [current documentation](https://docs.openwhispr.com/platform/where-your-files-live)
uses `OpenWhispr` as the directory name instead. Check the actual directory and
override `dataDir` if your build differs. Both directory options require absolute
paths and do not expand `~`.

Environment values must be strings, including `"true"` and `"false"`.
localStorage strings are stored verbatim; booleans, numbers, lists, objects,
and null are JSON-serialized. Attribute sets merge across modules, and
`lib.mkForce` can override a preference already defined elsewhere.

Some preferences, such as the dictation shortcut, exist in both stores. Set
both copies consistently. Environment variables alone do not cover the app's
preferences. Never put credentials in either settings option: generated
configuration is stored in the Nix store.

## Dictionary

The `platypus` profile imports `dictionary.nix`, a focused list of company names
and development terms. Edit that file to manage the list across devices.
The [dictionary documentation](https://docs.openwhispr.com/help/customise/custom-dictionary)
recommends adding terms you use frequently; large general word lists dilute the hints.

With a nonempty dictionary, Home Manager installs `openwhispr-sync-dictionary`
and a user timer using launchd on macOS or systemd on Linux. Every minute it
adds missing words through the running app's authenticated local CLI bridge.
When the app is closed, it does nothing and tries again on the next tick.
You can also run the command manually while OpenWhispr is open.

The merge preserves UI additions and auto-learned words. Removing a word from
Nix does not delete it from the app; remove it from both places to stop using
it. Managed words deleted only in the UI will be added again. Dictionary
changes need no app restart and never write directly to its database.
The bridge format and endpoints were verified against OpenWhispr 1.10.2.
Its token is read at runtime from `~/.openwhispr/cli-bridge.json` and is never
stored in Nix. Dictionary words themselves are stored in Nix.

## Applying and restoring

Quit OpenWhispr fully before activating Home Manager. For this repository:

```sh
sudo darwin-rebuild switch --flake path:.
```

The `path:` form includes new module files before they are tracked by Git.
Activation merges the managed keys, leaves the files writable, and preserves
unmanaged values. Changes to managed keys made in the UI are overwritten at
the next activation. Removing a key from Nix leaves its last saved value in the
app; it does not reset the preference. With both settings sets empty, the
module performs no settings activation.

Each changed activation saves the previous `.env` and a logical LevelDB copy
under `backupDir`, in a directory accessible only to the user. To restore one,
quit OpenWhispr, set `programs.openwhispr.enable = false`, and replace the app's
`.env` and `Local Storage/leveldb` with the backup copies. A backup without
`.env` represents a profile that had no `.env` file.

On a new device, complete the app's permission setup and download the selected
models before applying the captured profile. This profile uses Orukeet
`orukeet-v0.1.0` and Qwen `qwen3.5-9b-q4_k_m`. OpenWhispr clears LLM selections
when model files are missing. Model downloads, credentials, recordings,
history, login state, and permission grants remain device-local. The source
installation had no custom snippets or actions.

## Implementation and validation

Home Manager generates a JSON payload and invokes `merge-settings.py` during
activation. Python's LevelDB library updates the database without replacing
unmanaged entries. This is an adapter for the internal storage used by
OpenWhispr 1.10.2, not an upstream configuration API. It refuses locked profiles
and unknown Chromium schema versions. Application upgrades can change the
preference names or storage format and require updating this adapter.

The settings behavior was checked against the installed application,
OpenWhispr's [environment manager](https://github.com/OpenWhispr/openwhispr/blob/main/src/helpers/environment.js),
and Chromium's [localStorage schema](https://github.com/chromium/chromium/blob/140.0.7339.0/components/services/storage/dom_storage/local_storage_impl.cc).
The [OpenWhispr CLI](https://github.com/OpenWhispr/openwhispr-cli) does not expose
the desktop preference settings needed to replace this adapter.

Run the module evaluation and isolated storage tests on an Apple Silicon Mac:

```sh
nix build --no-link path:.#checks.aarch64-darwin.openwhispr
```

Use `checks.x86_64-linux.openwhispr` on Linux. The checks cover disabled and
package-only configurations, option merging, platform paths, invalid settings,
backups, locking, Unicode, preservation of unmanaged data, and repeat activation.
They also check dictionary timers, additive updates, repeat syncs, stopped apps,
and bridge errors.

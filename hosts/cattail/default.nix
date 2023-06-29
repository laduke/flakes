{ pkgs, config, lib, ... }:
{

  # Make sure the nix daemon always runs
  services.nix-daemon.enable = true;

  # if you use zsh (the default on new macOS installations),
  # you'll need to enable this so nix-darwin creates a zshrc sourcing needed environment changes
  # needed here and in home-manager
  programs.zsh  = {
    enable = true;
  };
  # bash is enabled by default

  users.users.travis.home = "/Users/travis";

  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    # updates homebrew packages on activation,
    # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
    casks = [
      # "rectangle" spectacle fork
      "amethyst" # tiling
      "discord"
      "zoom"
      "signal"
      "steam"
    ];
    taps = [ "d12frosted/emacs-plus" ];

    brews = [
      "gh"
      {
        name = "emacs-plus@28";
        args = [ "with-native-comp" "with-imagemagick" "with-modern-doom3-icon" ];
        restart_service = "changed";
      }

    ];
  };


}


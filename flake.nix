{
  description = "Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, rust-overlay }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.vim
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      nixpkgs.config.permittedInsecurePackages = ["nodejs-16.20.1"];

      users.users.travis.home = "/Users/travis";


      homebrew = {
        enable = true;
        onActivation.autoUpdate = false;
        # updates homebrew packages on activation,
        # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
        casks = [
          "rectangle" # spectacle fork
          # "amethyst" # tiling
          "discord"
          "zoom"
          "signal"
          "steam"
          "visual-studio-code"
        ];
        taps = [ "d12frosted/emacs-plus" ];

        brews = [
          "corepack"
          "ansible"
          "redis"
          "gh"
          {
            name = "emacs-plus@28";
            args = [ "with-native-comp" "with-imagemagick" "with-modern-doom3-icon" ];
            restart_service = "changed";
          }

        ];
      };

    };
  in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#cattail
      darwinConfigurations.cattail = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ configuration
                    ({ pkgs, ... }: {
                      nixpkgs.overlays = [ rust-overlay.overlays.default ];
                      environment.systemPackages = [
                            pkgs.cargo-watch
                        (pkgs.rust-bin.stable.latest.default.override {
                          targets = [ "x86_64-apple-darwin" ];
                        })
                      ];
                    })



                    home-manager.darwinModules.home-manager {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.users.travis = { pkgs, ... }:
                        {
                          home.stateVersion = "23.11";
                          home.packages = [
                            pkgs.act
                            pkgs.bazel-buildtools
                            pkgs.bazelisk
                            pkgs.clang-tools
                            pkgs.cloud-sql-proxy
                            pkgs.cmake
                            pkgs.direnv
                            pkgs.drone-cli
                            pkgs.esbuild
                            pkgs.fd
                            pkgs.fping
                            pkgs.git
                            pkgs.go
                            pkgs.gopls
                            pkgs.google-cloud-sdk
                            pkgs.gping
                            pkgs.gping
                            pkgs.html-tidy
                            pkgs.graphviz
                            pkgs.htop
                            pkgs.ipcalc
                            pkgs.iperf3
                            pkgs.ispell
                            pkgs.jq
                            pkgs.meson
                            pkgs.ninja
                            pkgs.nix-direnv
                            pkgs.nmap
                            # pkgs.nodePackages.eslint
                            # pkgs.nodePackages.live-server
                            # pkgs.nodePackages.node2nix
                            # pkgs.nodePackages.typescript
                            # pkgs.nodePackages.typescript-language-server
                            # pkgs.nodejs_18
                            pkgs.pandoc
                            pkgs.ripgrep
                            pkgs.sqlite
                            pkgs.stripe-cli
                            pkgs.terraform
                            pkgs.tmux
                            pkgs.ffmpeg
                            pkgs.unixtools.watch
                          ];

                          home.sessionPath = [
                            "$HOME/.config/emacs/bin"
                            "$HOME/go/bin"
                            "$HOME/.cargo/bin"
                          ];

                          home.sessionVariables = {
                            DRONE_SERVER="http://drone.ci.lab";
                            EDITOR = "vim";
                            GOPROXY = "http://goproxy.int.zerotier.com:3000";
                            GOPRIVATE = "github.com/zerotier";
                            GONOPROXY = "none";
                            NVM_DIR = "$HOME/.nvm";
                          };

                          programs.direnv = {
                            enable = true;
                          };

                          programs.tmux = {
                            enable = true;
                            mouse = true;
                            extraConfig = ''
                              set -s copy-command 'pbcopy'
                            '';
                            plugins = with pkgs; [
                              # tmuxPlugins.yank # not needed. the above works -the way i want it to anyways
                            ];
                          };

                          # programs.nix-direnv = {
                          #   enable = true;
                          # };

                          programs.git = {
                            enable = true;
                            userName = "travisladuke";
                            userEmail = "travisladuke@gmail.com";
                            extraConfig = {
                              diff.algorithm = "patience";
                            };
                          };

                          programs.zsh  = {
                            enable = true;
                            shellAliases = {
                              cloudsql = "cloud_sql_proxy -instances=zerotier-central:us-central1:pgsql14-ztcentral-us-central1=tcp:5433";
                              dnsclear = "sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder";
                              dug = "dscacheutil -q host -a name";
                              ll = "ls -l";
                              zt = "zerotier-cli";
                              zt-load = "sudo launchctl load /Library/LaunchDaemons/com.zerotier.one.plist";
                              zt-unload = "sudo launchctl unload /Library/LaunchDaemons/com.zerotier.one.plist";
                              sleepoff="sudo pmset -a disablesleep 1";
                              sleepon="sudo pmset -a disablesleep 0";
                              zt-auth="zerotier-cli listnetworks -j | jq -r '.[] | select(.status == \"AUTHENTICATION_REQUIRED\") | .authenticationURL | values ' | xargs open";
                            };

                            initExtra = ''
                          if [[ $(uname -m) == 'arm64' ]]; then
                            eval "$(/opt/homebrew/bin/brew shellenv)"
                          fi

                          add-key () {
                              security add-generic-password -a "$USER" -s $1 -w
                          }
                          get-key () {
                              security find-generic-password -a "$USER" -s $1 -w
                          }
                          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
                          '';

                          };

                        };
                    }
                  ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations.cattail.pkgs;
    };
}

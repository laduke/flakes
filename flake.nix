{
  description = "travis' mac computers";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";

  };

  outputs = { self, nixpkgs, home-manager, darwin, rust-overlay }: {
    darwinConfigurations.cattail = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/cattail/default.nix

        ({ pkgs, ... }: {
          nixpkgs.overlays = [ rust-overlay.overlays.default ];
          environment.systemPackages = [
            # pkgs.rust-bin.stable.latest.default
            (pkgs.rust-bin.stable.latest.default.override {
              targets = [ "x86_64-apple-darwin" ];
            })
          ];
        })

        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.travis = { pkgs, ... }: {
            home.stateVersion = "23.11";
            home.packages = [
              pkgs.tmux
              pkgs.ipcalc
              pkgs.htop
              pkgs.git
              pkgs.ripgrep
              pkgs.fd
              pkgs.jq
              pkgs.nodejs_18
              pkgs.go
            ];

            home.sessionPath = [
              "$HOME/.config/emacs/bin"
              "$HOME/go/bin"
            ];

            home.sessionVariables = {
              EDITOR = "vim";
            };

            programs.git = {
              enable = true;
              userName = "travisladuke";
              userEmail = "travisladuke@gmail.com";
            };

            programs.zsh  = {
              enable = true;
              shellAliases = {
                ll = "ls -l";
              };

              initExtra = ''
                if [[ $(uname -m) == 'arm64' ]]; then
                  eval "$(/opt/homebrew/bin/brew shellenv)"
                    fi
              '';

            };

          };
        }
      ];
    };
  };
}

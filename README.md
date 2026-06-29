# Yorick Flake

I've assembled the [Yorick](github.com/llnl/yorick) plugins required for running [YAO](github.com/frigaut/yao) and [Spydr](github.com/frigaut/yorick-spydr) as git submodules in this repository. The [flake.nix](./flake.nix) file here allows a declarative build of:
 - `yorick`,
 - `yao`,
 - `spydr`,
including the canonical `rlwrap` alias.

Because of the Yorick "plugin" concept, it's not clear to me how to build these packages independently, so instead I built them all as one package (`yorick-nowrap`) and then expose the individual `rlwrap`ped executables which will each link to the `yorick-nowrap` installation in the `/nix/store`. This works well enough for now, but if you think of a nice fix, feel free to make a feature request or a PR.

To add these packages to your Nix devShell or NixOS configuration (using flakes), you can modify your flake to track this repo as an input, and provide these packages as an output. E.g.:

```nix
{
  inputs = {
    yorick-flake = {
      url = "git+https://github.com/jcranney/yorick-flake";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = { self, nixpkgs, flake-utils, yorick-flake }: 
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        devShells.default = pkgs.mkShell {
          packages = with yorick-flake.packages.${system}; [ 
            spydr yao yorick
          ];
        };
      }
    );
}

```

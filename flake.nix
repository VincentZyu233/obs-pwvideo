{
  description = "OBS generic PipeWire video source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flakelight.url = "github:nix-community/flakelight";
    flakelight.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { flakelight, ... }:
    flakelight ./. {
      packages.obs-pwvideo = import ./nix/package.nix;
      overlay = final: prev: {
        obs-studio-plugins = (prev.obs-studio-plugins or { }) // {
          obs-pwvideo = final.callPackage ./nix/package.nix { };
        };
      };
    };
}

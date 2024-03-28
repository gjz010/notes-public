{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    emanote.url = "github:srid/emanote";
  };

  outputs = { self, nixpkgs, emanote }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
    devShells.x86_64-linux.default = let pkgs = import nixpkgs { system = "x86_64-linux";}; in pkgs.mkShell {
      nativeBuildInputs = with pkgs; [ zk fzf (emanote.packages.x86_64-linux.emanote)];
    };
  };
}

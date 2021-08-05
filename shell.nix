let
  nixpkgs = import (fetchTarball {
    url = "https://github.com/trevorite/nixpkgs/archive/elixir_1_12_1.tar.gz";
    sha256 = "sha256:0hjgc5fsk43ffgzb6g65cq1n66jbq04cyy2i72r0myqggijjlpmq";
  }) { };
  platform = if nixpkgs.stdenv.isDarwin then [
    nixpkgs.darwin.apple_sdk.frameworks.CoreServices
    nixpkgs.darwin.apple_sdk.frameworks.Foundation
  ] else if nixpkgs.stdenv.isLinux then
    [ nixpkgs.inotify-tools ]
  else
    [ ];
in nixpkgs.mkShell {
  buildInputs = [ nixpkgs.erlang nixpkgs.elixir ] ++ platform;
}

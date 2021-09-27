let
  nixpkgs = import (fetchTarball {
    url =
      "https://github.com/trevorite/nixpkgs/archive/otp23-elixir1.12.tar.gz";
    sha256 = "sha256:1r9qxh8ar3yyfxy36rwgxrf228q5s31s94swp1gpn80090s58v4x";
  }) { };
  platform = if nixpkgs.stdenv.isDarwin then [
    nixpkgs.darwin.apple_sdk.frameworks.CoreServices
    nixpkgs.darwin.apple_sdk.frameworks.Foundation
  ] else if nixpkgs.stdenv.isLinux then
    [ nixpkgs.inotify-tools ]
  else
    [ ];
in nixpkgs.mkShell {
  buildInputs = [ nixpkgs.erlang nixpkgs.elixir_1_11 ] ++ platform;
}
